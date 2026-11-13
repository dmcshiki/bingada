// Run from test/rules: `npm i && npm test` (needs the Firebase Emulator).
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sha = (s) => crypto.createHash('sha256').update(s).digest('hex');
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
  b.set(doc(db, `games/g1/players/${uid}`), { displayName: `Jogador ${uid}` });
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
  await seed(game({ status: 'running', drawCommit: sha('x') }));
  const host = user('host', 'h@acme.dev');
  await assertFails(updateDoc(doc(host, 'games/g1'), { salt: 'other' }));
  await assertFails(updateDoc(doc(host, 'games/g1'), { drawSeed: 'x' }));
  // The revealed seed must match the published commit.
  await assertFails(updateDoc(doc(host, 'games/g1'), { status: 'finished', drawSeed: 'wrong' }));
  await assertSucceeds(updateDoc(doc(host, 'games/g1'), { status: 'finished', drawSeed: 'x' }));
});
test('claim must match current drawIndex and prize', async () => {
  await seed(game({ status: 'running', draws: ['0:1'] }));
  await env.withSecurityRulesDisabled((c) =>
    setDoc(doc(c.firestore(), 'games/g1/cards/a'), { items: [] }));
  const a = user('a', 'a@acme.dev');
  const base = { uid: 'a', prizeId: 'p1', status: 'pending', verdict: null };
  await assertFails(setDoc(doc(a, 'games/g1/claims/a_0_p1'), { ...base, drawIndex: 0 }));
  await assertSucceeds(setDoc(doc(a, 'games/g1/claims/a_1_p1'), { ...base, drawIndex: 1 }));
});
test('claim id is bound to its owner, ball and prize', async () => {
  await seed(game({ status: 'running', draws: ['0:1'] }));
  await env.withSecurityRulesDisabled((c) =>
    setDoc(doc(c.firestore(), 'games/g1/cards/a'), { items: [] }));
  const a = user('a', 'a@acme.dev');
  const base = { uid: 'a', prizeId: 'p1', status: 'pending', verdict: null, drawIndex: 1 };
  // Pre-creating another player's id must fail.
  await assertFails(setDoc(doc(a, 'games/g1/claims/b_1_p1'), base));
  await assertFails(setDoc(doc(a, 'games/g1/claims/random'), base));
  // Forged fields are refused.
  await assertFails(setDoc(doc(a, 'games/g1/claims/a_1_p1'), { ...base, matched: [{ kind: 'full', index: 0 }] }));
  await assertFails(setDoc(doc(a, 'games/g1/claims/a_1_p1'), { ...base, hack: true }));
});
test('host offers a raffle win only to the raffle winner', async () => {
  await seed(game({
    status: 'running', draws: ['0:1', '0:2'],
    raffle: { prizeId: 'p1', candidates: ['a', 'b'], kind: 'released', winner: 'a' },
  }));
  const host = user('host', 'h@acme.dev');
  const offer = (uid, prizeId = 'p1') => ({
    uid, prizeId, drawIndex: 2, status: 'awaitingChoice', verdict: 'valid',
    offerPrizeId: prizeId, choice: null, releasePrizeId: null, tieOptIn: false,
  });
  await assertSucceeds(setDoc(doc(host, 'games/g1/claims/raffle_a_2_p1'), offer('a')));
  // Not the winner, wrong prize, or not the host.
  await assertFails(setDoc(doc(host, 'games/g1/claims/raffle_b_2_p1'), offer('b')));
  await assertFails(setDoc(doc(host, 'games/g1/claims/raffle_a_2_p2'), offer('a', 'p2')));
  await assertFails(setDoc(doc(user('b', 'b@acme.dev'), 'games/g1/claims/raffle_a_2_p1'), offer('a')));
  // Pre-answered offers are refused.
  await assertFails(setDoc(doc(host, 'games/g1/claims/raffle_a_2_p1x'),
    { ...offer('a'), releasePrizeId: 'p2' }));
});
