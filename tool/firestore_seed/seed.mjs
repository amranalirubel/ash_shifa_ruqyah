import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const projectId = 'ash-shifa-ruqyah';
const canonicalIds = [
  'problems',
  'parenting_guide',
  'smart_tools',
  'age_based_care',
  'learning_development',
  'instant_care',
];
const legacySmartToolIds = ['daily_tips', 'features', 'milestones'];
const legacyMigrationVersion = 1;
const smartToolSectionIds = [
  'vaccination_schedule',
  'growth_tracking',
  'development_milestones',
  'nutrition_plan',
  'medicine_reminder',
  'health_record',
];

const inputPath = process.argv[2];
const validateOnly = process.argv.includes('--validate-only');
if (!inputPath) {
  throw new Error('The exported content JSON path is required.');
}

if (process.env.CONFIRM_PROJECT !== projectId) {
  throw new Error(`Project confirmation must exactly equal ${projectId}.`);
}

const dryRun = parseBoolean(process.env.DRY_RUN ?? 'true', 'DRY_RUN');
const forceRefresh = parseBoolean(
  process.env.FORCE_REFRESH ?? 'false',
  'FORCE_REFRESH',
);

const rawDocuments = JSON.parse(await readFile(inputPath, 'utf8'));
if (!Array.isArray(rawDocuments)) {
  throw new Error('Exported content must be a JSON array.');
}

const documents = new Map(
  rawDocuments.map((document) => [document?.id, document?.data]),
);
const exportedIds = [...documents.keys()];

if (
  exportedIds.length !== canonicalIds.length ||
  !canonicalIds.every((id, index) => exportedIds[index] === id)
) {
  throw new Error(
    `Expected only these documents in order: ${canonicalIds.join(', ')}.`,
  );
}

for (const id of canonicalIds) {
  if (!isCanonicalDocument(id, documents.get(id))) {
    throw new Error(`Bundled document failed validation: ${id}.`);
  }
}
validateMigrationHelpers(documents.get('smart_tools'));

if (validateOnly) {
  console.log('Validated all six canonical Mom & Child Care documents.');
  process.exit(0);
}

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credentialsPath) {
  throw new Error('Google Application Default Credentials were not created.');
}

const credentials = JSON.parse(await readFile(credentialsPath, 'utf8'));
if (credentials.project_id !== projectId) {
  throw new Error(
    `Credential project mismatch: expected ${projectId}, received ` +
      `${credentials.project_id ?? 'unknown'}.`,
  );
}

initializeApp({ credential: applicationDefault(), projectId });
const firestore = getFirestore();
const runId = new Date().toISOString().replace(/[^0-9]/g, '');

let created = 0;
let repaired = 0;
let skipped = 0;

for (const id of canonicalIds) {
  const canonicalData = documents.get(id);
  const reference = firestore.collection('mom_child_care').doc(id);

  const action = await firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const currentIsCanonical =
      snapshot.exists && isCanonicalDocument(id, snapshot.data());

    if (currentIsCanonical && !forceRefresh) {
      return 'skipped';
    }

    if (dryRun) {
      return snapshot.exists ? 'dry-repair' : 'dry-create';
    }

    if (snapshot.exists) {
      const backup = firestore
        .collection('content_seed_backups')
        .doc(`mom_child_care__${id}__${runId}`);

      transaction.create(backup, {
        sourcePath: reference.path,
        backedUpAt: FieldValue.serverTimestamp(),
        previousData: snapshot.data(),
      });
    }

    const nextData =
      id === 'smart_tools'
        ? preserveSmartToolContent(canonicalData, snapshot.data())
        : canonicalData;

    transaction.set(
      reference,
      {
        ...nextData,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return snapshot.exists ? 'repaired' : 'created';
  });

  if (action === 'skipped') {
    skipped += 1;
    console.log(`SKIP   mom_child_care/${id} is already canonical.`);
  } else if (action === 'dry-repair') {
    console.log(`DRY-RUN REPAIR mom_child_care/${id}`);
  } else if (action === 'dry-create') {
    console.log(`DRY-RUN CREATE mom_child_care/${id}`);
  } else if (action === 'repaired') {
    repaired += 1;
    console.log(`REPAIR mom_child_care/${id}`);
  } else if (action === 'created') {
    created += 1;
    console.log(`CREATE mom_child_care/${id}`);
  }
}

const legacyResult = await consolidateLegacySmartTools({
  firestore,
  runId,
  dryRun,
  canonicalSmartTools: documents.get('smart_tools'),
});

if (dryRun) {
  console.log('Dry run complete. Firestore was not changed.');
} else {
  console.log(
    `Seed complete: ${created} created, ${repaired} repaired, ` +
      `${skipped} already current.`,
  );
  console.log('Existing repaired documents were backed up before replacement.');
  console.log(
    `Legacy consolidation: ${legacyResult.fieldsMigrated} field(s) migrated, ` +
      `${legacyResult.documentsArchived} legacy document(s) preserved and marked deprecated.`,
  );
}

async function consolidateLegacySmartTools({
  firestore,
  runId,
  dryRun,
  canonicalSmartTools,
}) {
  const smartToolsReference = firestore.collection('mom_child_care').doc('smart_tools');
  const legacyReferences = legacySmartToolIds.map((id) =>
    firestore.collection('mom_child_care').doc(id),
  );

  return firestore.runTransaction(async (transaction) => {
    // Firestore transactions require every read to finish before any write.
    const smartToolsSnapshot = await transaction.get(smartToolsReference);
    const legacySnapshots = [];
    for (const reference of legacyReferences) {
      legacySnapshots.push(await transaction.get(reference));
    }

    const smartTools = smartToolsSnapshot.data() ?? {};
    const legacyById = new Map(
      legacySnapshots
        .filter((snapshot) => snapshot.exists)
        .map((snapshot) => [snapshot.id, snapshot.data() ?? {}]),
    );
    const updates = {};

    const currentDailyTips = stringList(smartTools.dailyTips);
    const legacyDailyTips = firstNonEmptyStringList(
      legacyById.get('daily_tips')?.dailyTips,
      legacyById.get('daily_tips')?.tips,
      legacyById.get('daily_tips')?.list,
    );
    const bundledDailyTips = stringList(canonicalSmartTools.dailyTips);
    if (
      currentDailyTips.length === 0 ||
      (legacyDailyTips.length > 0 &&
        arraysEqual(currentDailyTips, bundledDailyTips))
    ) {
      const source =
        legacyDailyTips.length > 0 ? legacyDailyTips : bundledDailyTips;
      if (source.length > 0) updates.dailyTips = source;
    }

    const currentMilestones = mapList(smartTools.milestones);
    const legacyMilestones = firstNonEmptyMapList(
      legacyById.get('milestones')?.milestones,
      legacyById.get('milestones')?.list,
    );
    if (currentMilestones.length === 0 && legacyMilestones.length > 0) {
      updates.milestones = legacyMilestones;
    }

    const legacyToArchive = legacySnapshots.filter((snapshot) => {
      if (!snapshot.exists) return false;
      const migration = snapshot.data()?.migration;
      return (
        !migration ||
        migration.version !== legacyMigrationVersion ||
        migration.targetPath !== smartToolsReference.path
      );
    });

    const fieldsMigrated = ['dailyTips', 'milestones'].filter(
      (field) => updates[field] !== undefined,
    ).length;

    if (dryRun) {
      if (updates.dailyTips) {
        console.log(
          `DRY-RUN MIGRATE ${updates.dailyTips.length} daily tip(s) into ` +
            'mom_child_care/smart_tools.dailyTips',
        );
      }
      if (updates.milestones) {
        console.log(
          `DRY-RUN MIGRATE ${updates.milestones.length} milestone group(s) into ` +
            'mom_child_care/smart_tools.milestones',
        );
      }
      for (const snapshot of legacyToArchive) {
        console.log(
          `DRY-RUN BACKUP mom_child_care/${snapshot.id} and mark it deprecated`,
        );
      }
      return {
        fieldsMigrated,
        documentsArchived: legacyToArchive.length,
      };
    }

    if (fieldsMigrated > 0) {
      if (smartToolsSnapshot.exists) {
        const backup = firestore
          .collection('content_seed_backups')
          .doc(`mom_child_care__smart_tools__before_legacy__${runId}`);
        transaction.create(backup, {
          sourcePath: smartToolsReference.path,
          reason: 'before-legacy-content-consolidation',
          backedUpAt: FieldValue.serverTimestamp(),
          previousData: smartTools,
        });
      }

      transaction.set(
        smartToolsReference,
        {
          ...updates,
          contentStructureVersion: 2,
          legacyMigrationVersion,
          legacySources: [...legacyById.keys()],
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    for (const snapshot of legacyToArchive) {
      const backup = firestore
        .collection('content_seed_backups')
        .doc(`mom_child_care__legacy_${snapshot.id}__${runId}`);
      transaction.create(backup, {
        sourcePath: snapshot.ref.path,
        reason: 'legacy-smart-tool-document',
        backedUpAt: FieldValue.serverTimestamp(),
        previousData: snapshot.data(),
      });
      transaction.set(
        snapshot.ref,
        {
          deprecated: true,
          migration: {
            version: legacyMigrationVersion,
            targetPath: smartToolsReference.path,
            migratedAt: FieldValue.serverTimestamp(),
          },
        },
        { merge: true },
      );
    }

    return {
      fieldsMigrated,
      documentsArchived: legacyToArchive.length,
    };
  });
}

function preserveSmartToolContent(canonicalData, currentData) {
  if (!currentData || typeof currentData !== 'object') return canonicalData;

  const result = { ...canonicalData };
  const dailyTips = stringList(currentData.dailyTips);
  const milestones = mapList(currentData.milestones);
  const vaccinationSchedule = mapList(currentData.vaccinationSchedule);
  if (dailyTips.length > 0) result.dailyTips = dailyTips;
  if (milestones.length > 0) result.milestones = milestones;
  if (vaccinationSchedule.length > 0) {
    result.vaccinationSchedule = vaccinationSchedule;
  }
  return result;
}

function firstNonEmptyStringList(...values) {
  for (const value of values) {
    const list = stringList(value);
    if (list.length > 0) return list;
  }
  return [];
}

function firstNonEmptyMapList(...values) {
  for (const value of values) {
    const list = mapList(value);
    if (list.length > 0) return list;
  }
  return [];
}

function stringList(value) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string')
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function validateMigrationHelpers(canonicalSmartTools) {
  assert.deepEqual(stringList(['  টিপস  ', '', 7]), ['টিপস']);
  assert.equal(firstNonEmptyMapList([], [{ title: 'group' }]).length, 1);

  const preserved = preserveSmartToolContent(canonicalSmartTools, {
    dailyTips: ['  admin tip  '],
    milestones: [{ title: 'age group' }],
    vaccinationSchedule: ['invalid record'],
  });
  assert.deepEqual(preserved.dailyTips, ['admin tip']);
  assert.equal(preserved.milestones.length, 1);
  assert.deepEqual(
    preserved.vaccinationSchedule,
    canonicalSmartTools.vaccinationSchedule,
  );
}

function arraysEqual(first, second) {
  return (
    first.length === second.length &&
    first.every((item, index) => item === second[index])
  );
}

function parseBoolean(value, name) {
  if (value === 'true') return true;
  if (value === 'false') return false;
  throw new Error(`${name} must be true or false.`);
}

function isCanonicalDocument(documentId, data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return false;

  const documentIndex = canonicalIds.indexOf(documentId);
  if (documentIndex < 0) return false;

  const sections = mapList(data.sections);
  if (!hasText(data.title) || !hasText(data.contentVersion)) return false;
  if (data.schemaVersion !== 1) return false;
  if (data.displayOrder !== documentIndex + 1) return false;
  if (!Number.isInteger(data.topicCount) || data.topicCount <= 0) return false;
  if (!Number.isInteger(data.categoryCount) || data.categoryCount <= 0) {
    return false;
  }
  if (sections.length !== data.categoryCount) return false;

  if (documentId === 'problems' || documentId === 'parenting_guide') {
    const topics = sections.flatMap((section) => mapList(section.topics));
    if (topics.length !== data.topicCount) return false;
    return topics.every(
      (topic) => hasText(topic.title) && mapList(topic.items).length > 0,
    );
  }

  if (data.topicCount !== sections.length) return false;
  if (documentId === 'smart_tools') {
    return sections.every(
      (section, index) =>
        section.id === smartToolSectionIds[index] &&
        hasText(section.title) &&
        hasText(section.description),
    );
  }

  return sections.every(
    (section) => hasText(section.title) && mapList(section.items).length > 0,
  );
}

function mapList(value) {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (item) => item && typeof item === 'object' && !Array.isArray(item),
  );
}

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}
