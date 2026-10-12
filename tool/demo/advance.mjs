// Plays the vendor during a demo: moves a student's latest order to the next
// status, writing both copies the way the vendor app's OrderService does.
//
//   node advance.mjs            # next status for Nour's latest order
//   node advance.mjs ready      # jump to a specific status

import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
const FLOW = ['pending', 'confirmed', 'ready', 'completed'];
const STUDENT = 'student-nour';

initializeApp({ projectId: 'demo-campusbites' });
const db = getFirestore();

const snap = await db.collection('orders').where('userId', '==', STUDENT).orderBy('createdAt', 'desc').limit(1).get();
if (snap.empty) throw new Error('No orders for the demo student. Run seed.mjs first.');

const order = snap.docs[0];
const { status, vendorId } = order.data();
const next = process.argv[2] ?? FLOW[Math.min(FLOW.indexOf(status) + 1, FLOW.length - 1)];
if (![...FLOW, 'cancelled'].includes(next)) throw new Error(`Unknown status "${next}"`);

const batch = db.batch();
batch.update(order.ref, { status: next });
batch.update(db.doc(`vendors/${vendorId}/orders/${order.id}`), { status: next });

// The production Cloud Function sends this notification; the demo writes it directly.
const vendor = (await db.doc(`vendors/${vendorId}`).get()).data();
const copy = {
  confirmed: ['Order confirmed', `${vendor.name} is preparing your order.`],
  ready: ['Your order is ready', `Pick it up at ${vendor.name}.`],
  completed: ['Enjoy your meal', `Thanks for ordering from ${vendor.name}.`],
  cancelled: ['Order cancelled', `${vendor.name} cancelled your order.`],
}[next];
if (copy) {
  batch.set(db.collection('notifications').doc(), {
    userId: STUDENT,
    orderId: order.id,
    title: copy[0],
    body: copy[1],
    status: next,
    read: false,
    createdAt: Timestamp.now(),
  });
}

await batch.commit();
console.log(`${order.id}: ${status} -> ${next}`);
process.exit(0);
