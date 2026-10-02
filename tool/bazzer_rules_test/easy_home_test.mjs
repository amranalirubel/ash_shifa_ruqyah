import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, query, where,
  documentId, serverTimestamp, Timestamp, writeBatch, runTransaction } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-easy-home-ci', firestore: { rules: readFileSync('firestore.rules', 'utf8') },
});
const home = 'easy_home_buildings/house';
const memberPath = uid => `${home}/members/${uid}`;
const ref = (db, path) => doc(db, path);
const stamp = () => serverTimestamp();
const date = value => Timestamp.fromDate(new Date(value));
const member = (role, extra = {}) => ({ name: 'User', phone: '01700000000', role, active: true,
  tenancyId: '', flatId: '', floor: '', updatedAt: stamp(), ...extra });
const tenant = (flatId, flatCode, floor) => ({ name: 'Private tenant name', phone: '01799999999',
  rentPaisa: 650050, dueDay: 5, flatId, flatCode, floor, userId: '', active: true,
  startDate: date('2026-01-10'), endDate: null, updatedAt: stamp() });
const request = (code = 'ABCDEFGHJKLM', role = 'tenant') => ({ name: 'Joiner', phone: '01700000001', role, code, status: 'pending', updatedAt: stamp() });

try {
  const owner = env.authenticatedContext('owner').firestore();
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  const caretaker = env.authenticatedContext('caretaker').firestore();
  const outsider = env.authenticatedContext('outsider').firestore();
  const guest = env.unauthenticatedContext().firestore();
  const setup = writeBatch(owner);
  setup.set(ref(owner, home), { name: 'House', ownerUid: 'owner', inviteCode: 'ABCDEFGHJKLM', joiningEnabled: true, createdAt: stamp(), updatedAt: stamp() });
  setup.set(ref(owner, memberPath('owner')), member('landlord'));
  setup.set(ref(owner, 'easy_home_codes/ABCDEFGHJKLM'), { homeId: 'house', createdAt: stamp() });
  setup.set(ref(owner, 'users/owner/easy_home/connection'), { homeId: 'house' });
  await assertSucceeds(setup.commit());
  await assertSucceeds(getDoc(ref(owner, home)));
  await assertFails(getDoc(ref(guest, home)));
  await assertFails(getDoc(ref(outsider, home)));
  await assertFails(getDocs(collection(outsider, 'easy_home_buildings')));
  await assertFails(getDocs(collection(outsider, 'easy_home_codes')));
  await assertFails(getDoc(ref(guest, 'easy_home_codes/ABCDEFGHJKLM')));
  await assertSucceeds(getDoc(ref(alice, 'easy_home_codes/ABCDEFGHJKLM')));
  // A forged private connection grants no rights to its target building.
  await assertSucceeds(setDoc(ref(outsider, 'users/outsider/easy_home/connection'), { homeId: 'house' }));
  await assertFails(getDoc(ref(outsider, home)));
  await assertFails(setDoc(ref(alice, memberPath('alice')), member('landlord')));
  await assertFails(setDoc(ref(alice, memberPath('alice')), member('caretaker')));
  await assertFails(setDoc(ref(alice, `${home}/requests/alice`), request('WRONGCODEXXX')));
  await assertFails(setDoc(ref(alice, `${home}/requests/alice`), request('ABCDEFGHJKLM', 'landlord')));
  await assertSucceeds(setDoc(ref(alice, `${home}/requests/alice`), request()));
  await assertSucceeds(getDoc(ref(alice, `${home}/requests/alice`)));
  await assertFails(getDoc(ref(bob, `${home}/requests/alice`)));
  await assertFails(getDocs(collection(alice, `${home}/requests`)));
  await assertSucceeds(getDocs(collection(owner, `${home}/requests`)));
  await assertFails(updateDoc(ref(alice, `${home}/requests/alice`), { status: 'approved' }));
  await assertSucceeds(updateDoc(ref(owner, home), { joiningEnabled: false, updatedAt: stamp() }));
  await assertFails(setDoc(ref(bob, `${home}/requests/bob`), request()));
  await assertSucceeds(updateDoc(ref(owner, home), { joiningEnabled: true, updatedAt: stamp() }));

  for (const [flatId, floor, unit, code, lease, uid] of [
    ['2_B', '2', 'B', '2B-K9X4', 'leaseA', 'alice'], ['3_A', '3', 'A', '3A-K9X4', 'leaseB', 'bob'],
  ]) {
    await assertSucceeds(setDoc(ref(owner, `${home}/flats/${flatId}`), { floor, unit, code, tenancyId: '', archived: false }));
    const add = writeBatch(owner);
    add.set(ref(owner, `${home}/tenants/${lease}`), tenant(flatId, code, floor));
    add.update(ref(owner, `${home}/flats/${flatId}`), { tenancyId: lease });
    await assertSucceeds(add.commit());
    const approve = writeBatch(owner);
    approve.update(ref(owner, `${home}/tenants/${lease}`), { userId: uid, updatedAt: stamp() });
    approve.set(ref(owner, memberPath(uid)), member('tenant', { tenancyId: lease, flatId, floor }));
    if (uid === 'alice') approve.update(ref(owner, `${home}/requests/alice`), { status: 'approved', updatedAt: stamp() });
    await assertSucceeds(approve.commit());
  }
  await assertSucceeds(setDoc(ref(owner, memberPath('caretaker')), member('caretaker')));
  await assertSucceeds(getDoc(ref(alice, home)));
  await assertSucceeds(getDocs(collection(alice, `${home}/flats`)));
  await assertFails(updateDoc(ref(owner, `${home}/flats/2_B`), { phone: '01799999999' }));
  await assertFails(updateDoc(ref(alice, memberPath('alice')), { role: 'landlord', updatedAt: stamp() }));
  await assertFails(updateDoc(ref(alice, memberPath('alice')), { tenancyId: 'leaseB', updatedAt: stamp() }));
  await assertFails(getDocs(collection(alice, `${home}/members`)));
  await assertFails(getDoc(ref(alice, memberPath('bob'))));
  await assertFails(getDocs(collection(caretaker, `${home}/tenants`)));
  await assertSucceeds(getDocs(query(collection(alice, `${home}/tenants`), where(documentId(), '==', 'leaseA'))));
  await assertFails(getDoc(ref(alice, `${home}/tenants/leaseB`)));
  await assertFails(getDocs(collection(alice, `${home}/tenants`)));
  await assertFails(updateDoc(ref(alice, `${home}/tenants/leaseA`), { rentPaisa: 1, updatedAt: stamp() }));
  await assertFails(updateDoc(ref(owner, home), { ownerUid: 'alice', updatedAt: stamp() }));
  await assertFails(updateDoc(ref(owner, memberPath('owner')), { active: false, updatedAt: stamp() }));
  await assertFails(updateDoc(ref(owner, memberPath('alice')), { role: 'landlord', updatedAt: stamp() }));

  const bill = (lease, code) => ({ tenantId: lease, flatCode: code, month: '2026-10', amountPaisa: 650050,
    paidPaisa: 0, dueDate: date('2026-10-05'), lastPaymentId: '', createdAt: stamp(), updatedAt: stamp() });
  const rentA = `${home}/rents/leaseA_2026-10`;
  const rentB = `${home}/rents/leaseB_2026-10`;
  await assertSucceeds(setDoc(ref(owner, rentA), bill('leaseA', '2B-K9X4')));
  await assertSucceeds(setDoc(ref(owner, rentB), bill('leaseB', '3A-K9X4')));
  await assertFails(setDoc(ref(owner, `${home}/rents/duplicate-random-id`), bill('leaseA', '2B-K9X4')));
  await assertFails(setDoc(ref(owner, rentA), bill('leaseA', '2B-K9X4')));
  await assertSucceeds(getDocs(query(collection(alice, `${home}/rents`), where('tenantId', '==', 'leaseA'))));
  await assertFails(getDocs(collection(alice, `${home}/rents`)));
  await assertFails(getDoc(ref(alice, rentB)));
  await assertFails(getDoc(ref(caretaker, rentA)));
  await assertFails(updateDoc(ref(alice, rentA), { paidPaisa: 650050, updatedAt: stamp() }));
  await assertFails(updateDoc(ref(owner, rentA), { paidPaisa: 650050, updatedAt: stamp() }));
  await assertFails(updateDoc(ref(owner, rentA), { amountPaisa: 1, updatedAt: stamp() }));
  await assertFails(deleteDoc(ref(owner, rentA)));
  async function payment(db, id, delta, paid, method = 'cash', note = '') {
    const batch = writeBatch(db);
    batch.set(ref(db, `${rentA}/payments/${id}`), { amountPaisa: delta, balancePaisa: paid, method, note, recordedBy: 'owner', createdAt: stamp() });
    batch.update(ref(db, rentA), { paidPaisa: paid, lastPaymentId: id, updatedAt: stamp() });
    return batch.commit();
  }
  await assertSucceeds(payment(owner, 'p1', 200000, 200000));
  await assertSucceeds(payment(owner, 'p2', 450050, 650050));
  await assertFails(payment(owner, 'overpay', 1, 650051));
  await assertFails(payment(owner, 'invalid-negative', -1, 650049));
  await assertFails(payment(owner, 'empty-correction', -1, 650049, 'correction'));
  await assertSucceeds(payment(owner, 'p3', -50000, 600050, 'correction', 'Entry correction'));
  await assertFails(payment(owner, 'negative-total', -600051, -1, 'correction', 'Invalid'));
  await assertFails(payment(owner, 'wrong-delta', 5, 600060));
  await assertFails(payment(owner, 'p3', 50000, 650050));
  await assertSucceeds(getDocs(collection(alice, `${rentA}/payments`)));
  await assertFails(getDocs(collection(bob, `${rentA}/payments`)));
  await assertFails(updateDoc(ref(owner, `${rentA}/payments/p1`), { amountPaisa: 1 }));
  await assertFails(deleteDoc(ref(owner, `${rentA}/payments/p1`)));
  // The transaction retries rather than losing a concurrent contribution.
  const add = id => runTransaction(owner, async tx => {
    const receipt = ref(owner, `${rentA}/payments/${id}`);
    const exists = await tx.get(receipt);
    if (exists.exists()) return;
    const rent = await tx.get(ref(owner, rentA));
    const next = rent.data().paidPaisa + 1000;
    tx.set(receipt, { amountPaisa: 1000, balancePaisa: next, method: 'cash', note: '', recordedBy: 'owner', createdAt: stamp() });
    tx.update(ref(owner, rentA), { paidPaisa: next, lastPaymentId: id, updatedAt: stamp() });
  });
  await assertSucceeds(Promise.all([add('concurrent1'), add('concurrent2')]));
  await assertSucceeds(add('concurrent1'));
  assert.equal((await getDoc(ref(owner, rentA))).data().paidPaisa, 602050);

  const notice = audience => ({ content: 'Notice', audience, emergency: false, senderId: 'caretaker', createdAt: stamp() });
  for (const [id, audience] of [['all', 'all'], ['floor', 'floor:2'], ['private', 'flat:2_B'], ['other', 'flat:3_A'], ['rentReminder', 'tenant:leaseA']]) {
    await assertSucceeds(setDoc(ref(caretaker, `${home}/notices/${id}`), notice(audience)));
  }
  await assertSucceeds(getDocs(query(collection(alice, `${home}/notices`), where('audience', 'in', ['all', 'floor:2', 'flat:2_B', 'tenant:leaseA']))));
  await assertFails(getDocs(collection(alice, `${home}/notices`)));
  await assertFails(getDoc(ref(bob, `${home}/notices/private`)));
  await assertFails(setDoc(ref(alice, `${home}/notices/fake`), { ...notice('all'), senderId: 'alice' }));
  await assertFails(setDoc(ref(caretaker, `${home}/notices/huge`), { ...notice('all'), content: 'x'.repeat(2001) }));
  await assertSucceeds(deleteDoc(ref(caretaker, `${home}/notices/other`)));

  const complaint = { title: 'Leak', description: 'Water leaking', priority: 'urgent', authorUid: 'alice',
    flatCode: '2B-K9X4', status: 'pending', response: '', createdAt: stamp(), updatedAt: stamp() };
  const issue = `${home}/complaints/issue`;
  await assertSucceeds(setDoc(ref(alice, issue), complaint));
  await assertFails(setDoc(ref(alice, `${home}/complaints/forged-flat`), { ...complaint, flatCode: '3A-K9X4' }));
  await assertSucceeds(getDocs(query(collection(alice, `${home}/complaints`), where('authorUid', '==', 'alice'))));
  await assertFails(getDoc(ref(bob, issue)));
  await assertSucceeds(getDocs(collection(caretaker, `${home}/complaints`)));
  await assertSucceeds(updateDoc(ref(alice, issue), { description: 'Updated leak', updatedAt: stamp() }));
  await assertFails(updateDoc(ref(alice, issue), { status: 'resolved', updatedAt: stamp() }));
  await assertSucceeds(updateDoc(ref(caretaker, issue), { status: 'inProgress', response: 'Plumber assigned', updatedAt: stamp() }));
  await assertFails(updateDoc(ref(alice, issue), { description: 'Too late', updatedAt: stamp() }));
  await assertFails(deleteDoc(ref(alice, issue)));
  await assertSucceeds(updateDoc(ref(owner, issue), { status: 'resolved', updatedAt: stamp() }));
  await assertFails(updateDoc(ref(caretaker, issue), { authorUid: 'caretaker', updatedAt: stamp() }));

  // Ending tenancy preserves all old bills, frees the flat and revokes access.
  const end = writeBatch(owner);
  end.update(ref(owner, `${home}/tenants/leaseA`), { active: false, endDate: stamp(), updatedAt: stamp() });
  end.update(ref(owner, `${home}/flats/2_B`), { tenancyId: '' });
  end.update(ref(owner, memberPath('alice')), { active: false, updatedAt: stamp() });
  await assertSucceeds(end.commit());
  await assertFails(getDoc(ref(alice, home)));
  await assertFails(getDoc(ref(alice, rentA)));
  await assertFails(getDoc(ref(alice, issue)));
  await assertFails(getDoc(ref(alice, `${home}/notices/all`)));
  await assertFails(updateDoc(ref(alice, memberPath('alice')), { active: true, updatedAt: stamp() }));
  await assertSucceeds(getDoc(ref(owner, rentA)));
  // A new occupant in the same flat receives a new tenancy, not old finances.
  const replacement = writeBatch(owner);
  replacement.set(ref(owner, `${home}/tenants/leaseNew`), tenant('2_B', '2B-K9X4', '2'));
  replacement.update(ref(owner, `${home}/flats/2_B`), { tenancyId: 'leaseNew' });
  await assertSucceeds(replacement.commit());
  const approveNew = writeBatch(owner);
  approveNew.update(ref(owner, `${home}/tenants/leaseNew`), { userId: 'outsider', updatedAt: stamp() });
  approveNew.set(ref(owner, memberPath('outsider')), member('tenant', { tenancyId: 'leaseNew', flatId: '2_B', floor: '2' }));
  await assertSucceeds(approveNew.commit());
  await assertFails(getDoc(ref(outsider, rentA)));
  await assertFails(getDoc(ref(outsider, `${home}/notices/rentReminder`)));
  await assertFails(getDoc(ref(outsider, `${home}/tenants/leaseA`)));
  const leave = writeBatch(bob);
  leave.update(ref(bob, memberPath('bob')), { active: false, updatedAt: stamp() });
  leave.update(ref(bob, `${home}/tenants/leaseB`), { userId: '', updatedAt: stamp() });
  leave.delete(ref(bob, 'users/bob/easy_home/connection'));
  await assertSucceeds(leave.commit());
  await assertFails(getDoc(ref(bob, home)));
  await assertFails(getDoc(ref(alice, 'easy_home/tenants')));
  await assertFails(getDoc(ref(owner, 'easy_home/users')));
  console.log('EasyHome rules passed: lifecycle, query privacy, billing, receipts, concurrent payments, notices, complaints and revocation.');
} finally {
  await env.cleanup();
}
