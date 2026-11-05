// Run from test/rules: `npm i && npm test` (needs the Firebase Emulator).
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment, assertFails, assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, writeBatch, increment } = require('firebase/firestore');

let env;
const game = (over = {}) => ({
  roomCode: 'K7QP', hostUid: 'host', eventName: 'x', status: 'lobby',
  access: { mode: 'domain', domains: ['acme.dev'], emails: [], hostDomain: null },
  template: { rows: 5, cols: 5 }, prizes: [{ id: 'p1' }], endOfGamePrizes: [],
  prizePolicy: {}, settings: { claimPenalty: { type: 'none' } }, salt: 's',
  drawCommit: 'c', drawSeed: null, playerCount: 0, maxPlayers: 60,
  currentPrizeIndex: 0, draws: [], winners: [], ...over,
});
const user = (uid, email) =>
  env.authenticatedContext(uid, { email, email_verified: true }).firestore();
const seed = (data) => env.withSecurityRulesDisabled((c) =>
  setDoc(doc(c.firestore(), 'games/g1'), data));
const joinBatch = (db, uid) => {
  const b = writeBatch(db);
  b.set(doc(db, `games/g1/cards/${uid}`), { items: Array(25).fill('0:0') });
  b.set(doc(db, `games/g1/players/${uid}`), { displayName: uid });
  b.update(doc(db, 'games/g1'), { playerCount: increment(1) });
  return b.commit();
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-tokingo',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

test('join allowed for listed domain, denied otherwise', async () => {
  await seed(game());
  await assertSucceeds(joinBatch(user('a', 'a@acme.dev'), 'a'));
  await assertFails(joinBatch(user('b', 'b@evil.com'), 'b'));
});
test('join denied when full or running', async () => {
  await seed(game({ playerCount: 60 }));
  await assertFails(joinBatch(user('a', 'a@acme.dev'), 'a'));
  await seed(game({ status: 'running' }));
  await assertFails(joinBatch(user('a', 'a@acme.dev'), 'a'));
});
test('draws grow by exactly one, host only', async () => {
  await seed(game({ status: 'running', draws: ['0:1'] }));
  const host = user('host', 'h@acme.dev');
  await assertSucceeds(updateDoc(doc(host, 'games/g1'), { draws: ['0:1', '0:2'] }));
  await assertFails(updateDoc(doc(host, 'games/g1'), { draws: ['0:1', '0:2', '0:3', '0:4'] }));
  await assertFails(updateDoc(doc(user('a', 'a@acme.dev'), 'games/g1'), { draws: ['0:1', '0:2', '0:3'] }));
});
test('immutable fields and drawSeed only at the end', async () => {
  await seed(game({ status: 'running' }));
  const host = user('host', 'h@acme.dev');
  await assertFails(updateDoc(doc(host, 'games/g1'), { salt: 'other' }));
  await assertFails(updateDoc(doc(host, 'games/g1'), { drawSeed: 'x' }));
  await assertSucceeds(updateDoc(doc(host, 'games/g1'), { status: 'finished', drawSeed: 'x' }));
});
test('claim must match current drawIndex and prize', async () => {
  await seed(game({ status: 'running', draws: ['0:1'] }));
  await env.withSecurityRulesDisabled((c) =>
    setDoc(doc(c.firestore(), 'games/g1/cards/a'), { items: [] }));
  const a = user('a', 'a@acme.dev');
  const base = { uid: 'a', prizeId: 'p1', status: 'pending', verdict: null };
  await assertFails(setDoc(doc(a, 'games/g1/claims/c0'), { ...base, drawIndex: 0 }));
  await assertSucceeds(setDoc(doc(a, 'games/g1/claims/c1'), { ...base, drawIndex: 1 }));
});
