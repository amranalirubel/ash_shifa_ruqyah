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

    transaction.set(
      reference,
      {
        ...canonicalData,
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

if (dryRun) {
  console.log('Dry run complete. Firestore was not changed.');
} else {
  console.log(
    `Seed complete: ${created} created, ${repaired} repaired, ` +
      `${skipped} already current.`,
  );
  console.log('Existing repaired documents were backed up before replacement.');
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
      (section) => hasText(section.title) && hasText(section.description),
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
