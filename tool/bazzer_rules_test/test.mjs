import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  deleteDoc,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
  setDoc,
} from 'firebase/firestore';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const rules = readFileSync(resolve(projectRoot, 'firestore.rules'), 'utf8');
const environment = await initializeTestEnvironment({
  projectId: 'demo-bazzer-ci',
  firestore: { rules },
});

try {
  const owner = environment.authenticatedContext('owner').firestore();
  const member = environment.authenticatedContext('member').firestore();
  const stranger = environment.authenticatedContext('stranger').firestore();
  const viewer = environment.authenticatedContext('viewer').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const family = 'shopping_families/family-test';
  const invite = 'shopping_invites/ABCDEFGHJKLM';
  const item = `${family}/items/item-1`;
  const memberDoc = `${family}/members/member`;
  const viewerDoc = `${family}/members/viewer`;
  const secureItem = `${family}/secure_items/secure-1`;

  // The client creates family, invite and private link atomically.
  const setup = writeBatch(owner);
  setup.set(doc(owner, family), {
    ownerUid: 'owner',
    name: 'পরিবারের বাজার',
    inviteCode: 'ABCDEFGHJKLM',
    joiningEnabled: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  setup.set(doc(owner, invite), {
    familyId: 'family-test',
    ownerUid: 'owner',
    createdAt: serverTimestamp(),
  });
  setup.set(doc(owner, 'users/owner/bazzer_reminder/family'), {
    familyId: 'family-test',
    joinedAt: serverTimestamp(),
  });
  await assertSucceeds(setup.commit());
  await assertSucceeds(getDoc(doc(owner, family)));
  await assertFails(getDoc(doc(guest, invite)));
  await assertFails(getDocs(collection(stranger, 'shopping_invites')));
  await assertFails(getDocs(collection(stranger, 'shopping_families')));
  await assertFails(getDoc(doc(stranger, family)));
  await assertSucceeds(getDoc(doc(member, invite)));

  // A signed-in user may join only through a known, currently enabled code.
  await assertFails(setDoc(doc(stranger, `${family}/members/stranger`), {
    uid: 'stranger', name: 'Stranger', inviteCode: 'WRONGINVITEX',
    active: true, role: 'member', secure: false,
    joinedAt: serverTimestamp(), removedAt: null,
  }));
  const join = writeBatch(member);
  join.set(doc(member, memberDoc), {
    uid: 'member', name: 'Family member',
    inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member',
    secure: false,
    joinedAt: serverTimestamp(),
    removedAt: null,
  });
  join.set(doc(member, 'users/member/bazzer_reminder/family'), {
    familyId: 'family-test',
    joinedAt: serverTimestamp(),
  });
  await assertSucceeds(join.commit());
  const joinViewer = writeBatch(viewer);
  joinViewer.set(doc(viewer, viewerDoc), {
    uid: 'viewer', name: 'Viewer', inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member', secure: false,
    joinedAt: serverTimestamp(), removedAt: null,
  });
  joinViewer.set(doc(viewer, 'users/viewer/bazzer_reminder/family'), {
    familyId: 'family-test', joinedAt: serverTimestamp(),
  });
  await assertSucceeds(joinViewer.commit());
  await assertSucceeds(getDoc(doc(member, family)));
  await assertFails(getDocs(collection(member, `${family}/members`)));
  await assertSucceeds(getDocs(collection(owner, `${family}/members`)));

  const add = {
    name: 'কাঁচামরিচ', quantity: 0.5, unit: 'কেজি',
    category: 'সবজি', isBought: false,
    createdAt: serverTimestamp(),
    addedBy: 'Family member', createdBy: 'member',
    boughtBy: null, boughtAt: null,
  };
  await assertSucceeds(setDoc(doc(member, item), add));
  await assertSucceeds(getDoc(doc(viewer, item)));
  await assertSucceeds(updateDoc(doc(member, item), { name: 'মরিচ' }));
  await assertFails(updateDoc(doc(viewer, item), { name: 'অন্য নাম' }));
  await assertFails(updateDoc(doc(owner, item), { name: 'Owner cannot edit another author' }));
  await assertFails(deleteDoc(doc(viewer, item)));
  await assertFails(deleteDoc(doc(owner, item)));
  // An item's total price is replaceable by its author or a family Admin.
  // Amounts are integer paisa; role, content and immutable note dates stay protected.
  await assertSucceeds(updateDoc(doc(member, item), { pricePaisa: 1000 }));
  await assertSucceeds(updateDoc(doc(owner, item), { pricePaisa: 2500 }));
  await assertFails(updateDoc(doc(viewer, item), { pricePaisa: 5000 }));
  await assertFails(updateDoc(doc(stranger, item), { pricePaisa: 5000 }));
  for (const pricePaisa of [-1, 1.5, '1000', 100000001]) {
    await assertFails(updateDoc(doc(owner, item), { pricePaisa }));
  }
  await assertSucceeds(updateDoc(doc(member, item), { pricePaisa: null }));
  await assertSucceeds(updateDoc(doc(member, item), { pricePaisa: 0 }));
  const datedItem = `${family}/items/dated`;
  await assertSucceeds(setDoc(doc(member, datedItem), {
    ...add, pricePaisa: null, noteDate: '2026-09-24',
    clientCreatedAt: Timestamp.fromDate(new Date('2026-09-24T10:00:00Z')),
  }));
  await assertFails(updateDoc(doc(member, datedItem), { noteDate: '2026-09-25' }));
  await assertFails(updateDoc(doc(owner, datedItem), { pricePaisa: 1000, createdBy: 'owner' }));
  await assertFails(setDoc(doc(member, `${family}/items/invalid-date`), {
    ...add, noteDate: '2026-13-99',
  }));
  await assertSucceeds(setDoc(doc(member, `${family}/items/delete-me`), add));
  await assertSucceeds(deleteDoc(doc(member, `${family}/items/delete-me`)));
  await assertSucceeds(getDocs(query(
    collection(member, `${family}/items`),
    where('isBought', '==', false),
  )));
  await assertFails(getDoc(doc(stranger, item)));
  await assertFails(updateDoc(doc(member, item), {
    isBought: true, boughtBy: 'member', boughtAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(owner, family), { ownerUid: 'stranger' }));
  await assertSucceeds(updateDoc(doc(owner, item), {
    isBought: true, boughtBy: 'owner', boughtAt: serverTimestamp(),
  }));
  const bought = await assertSucceeds(getDoc(doc(owner, item)));
  assert.equal(bought.data().isBought, true);

  // Only an admin can change roles and secure mode. Secure entries are not
  // visible to unrelated family members, even by exact document ID.
  await assertFails(updateDoc(doc(member, memberDoc), { role: 'admin' }));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), { name: 'নতুন নাম' }));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), { secure: true }));
  await assertSucceeds(setDoc(doc(member, secureItem), {
    ...add, name: 'ব্যক্তিগত বাজার',
  }));
  await assertFails(getDoc(doc(viewer, secureItem)));
  await assertFails(getDocs(collection(viewer, `${family}/secure_items`)));
  await assertSucceeds(getDocs(query(
    collection(member, `${family}/secure_items`),
    where('createdBy', '==', 'member'),
  )));
  await assertSucceeds(getDoc(doc(owner, secureItem)));
  await assertSucceeds(updateDoc(doc(member, secureItem), { name: 'আমার পরিবর্তন' }));
  await assertFails(updateDoc(doc(viewer, secureItem), { name: 'অন্য পরিবর্তন' }));
  await assertSucceeds(updateDoc(doc(member, secureItem), { pricePaisa: 1000 }));
  await assertSucceeds(updateDoc(doc(owner, secureItem), { pricePaisa: 2000 }));
  await assertFails(updateDoc(doc(viewer, secureItem), { pricePaisa: 3000 }));
  await assertFails(setDoc(doc(viewer, `${family}/secure_items/no-access`), {
    ...add, createdBy: 'viewer',
  }));
  await assertSucceeds(updateDoc(doc(owner, viewerDoc), { role: 'admin' }));
  await assertSucceeds(getDocs(collection(viewer, `${family}/secure_items`)));
  await assertSucceeds(updateDoc(doc(viewer, secureItem), {
    isBought: true, boughtBy: 'viewer', boughtAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(viewer, secureItem), { name: 'Still not the writer' }));
  await assertSucceeds(updateDoc(doc(owner, viewerDoc), { role: 'member' }));
  await assertFails(getDoc(doc(viewer, secureItem)));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), { secure: false }));
  await assertFails(setDoc(doc(member, `${family}/secure_items/no-longer-secure`), {
    ...add, name: 'নতুন গোপন জিনিস',
  }));
  await assertSucceeds(getDoc(doc(member, secureItem)));
  await assertSucceeds(deleteDoc(doc(member, secureItem)));

  await assertSucceeds(updateDoc(doc(owner, family), {
    joiningEnabled: false, updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(stranger, `${family}/members/stranger`), {
    uid: 'stranger', name: 'Stranger', inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member', secure: false,
    joinedAt: serverTimestamp(), removedAt: null,
  }));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), {
    active: false, removedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(member, item)));
  await assertFails(updateDoc(doc(member, item), { pricePaisa: 1000 }));
  await assertFails(setDoc(doc(member, `${family}/items/item-2`), {
    ...add, name: 'আলু',
  }));
  await assertFails(setDoc(doc(member, memberDoc), {
    uid: 'member', name: 'Family member', inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member', secure: false,
    joinedAt: serverTimestamp(), removedAt: null,
  }));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), {
    active: true, removedAt: null,
  }));
  await assertSucceeds(getDoc(doc(member, item)));
  console.log('Family shopping Firestore rules: owner, invite, membership, revoke, shopping all passed.');
} finally {
  await environment.cleanup();
}
