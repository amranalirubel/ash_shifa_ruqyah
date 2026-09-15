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
  query,
  serverTimestamp,
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
  const guest = environment.unauthenticatedContext().firestore();
  const family = 'shopping_families/family-test';
  const invite = 'shopping_invites/ABCDEFGHJKLM';
  const item = `${family}/items/item-1`;
  const memberDoc = `${family}/members/member`;

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
    active: true, role: 'member', joinedAt: serverTimestamp(), removedAt: null,
  }));
  const join = writeBatch(member);
  join.set(doc(member, memberDoc), {
    uid: 'member', name: 'Family member',
    inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member',
    joinedAt: serverTimestamp(),
    removedAt: null,
  });
  join.set(doc(member, 'users/member/bazzer_reminder/family'), {
    familyId: 'family-test',
    joinedAt: serverTimestamp(),
  });
  await assertSucceeds(join.commit());
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

  await assertSucceeds(updateDoc(doc(owner, family), {
    joiningEnabled: false, updatedAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(stranger, `${family}/members/stranger`), {
    uid: 'stranger', name: 'Stranger', inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member', joinedAt: serverTimestamp(), removedAt: null,
  }));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), {
    active: false, removedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(member, item)));
  await assertFails(setDoc(doc(member, `${family}/items/item-2`), {
    ...add, name: 'আলু',
  }));
  await assertFails(setDoc(doc(member, memberDoc), {
    uid: 'member', name: 'Family member', inviteCode: 'ABCDEFGHJKLM',
    active: true, role: 'member', joinedAt: serverTimestamp(), removedAt: null,
  }));
  await assertSucceeds(updateDoc(doc(owner, memberDoc), {
    active: true, removedAt: null,
  }));
  await assertSucceeds(getDoc(doc(member, item)));
  console.log('Family shopping Firestore rules: owner, invite, membership, revoke, shopping all passed.');
} finally {
  await environment.cleanup();
}
