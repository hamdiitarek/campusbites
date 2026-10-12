// Seeds the Firebase Emulator Suite with a demo campus: one university, three
// vendors with photographed menus, five students, eight weeks of orders and
// a few notifications. Safe to re-run; it wipes the emulators first.
//
//   firebase emulators:start      (in this folder)
//   node seed.mjs
//
// It refuses to run unless every Firebase service points at an emulator.

import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const PROJECT = 'demo-campusbites';
const BUCKET = `${PROJECT}.appspot.com`;
const HOST = process.env.EMULATOR_HOST ?? '127.0.0.1';

process.env.FIRESTORE_EMULATOR_HOST ??= `${HOST}:8080`;
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= `${HOST}:9099`;
process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= `${HOST}:9199`;
process.env.STORAGE_EMULATOR_HOST ??= `http://${HOST}:9199`;

if (!PROJECT.startsWith('demo-')) throw new Error('Refusing to seed a non-demo project');

const PASSWORD = 'campusbites-demo'; // DemoAccounts.password in packages/core/lib/demo.dart
const UNIVERSITY = { id: 'egypt-university-informatics', name: 'Egypt University of Informatics' };
const IMAGES = new URL('./images/', import.meta.url);

// ------------------------------------------------------------------ catalogue

const VENDORS = [
  {
    uid: 'vendor-university-cafe',
    email: 'university.cafe@students.eui.edu.eg',
    name: 'University Café',
    description: 'Best coffee and sandwiches on campus',
    rating: 4.5,
    reviewCount: 42,
    cover: 'cafe_cover',
    menu: {
      Coffee: [
        ['espresso', 'Espresso', 'Rich, bold espresso shot', 15, 85, { 'Extra Shot': 5, Decaf: 0, 'Oat Milk': 3 }],
        ['cappuccino', 'Cappuccino', 'Classic cappuccino with steamed milk foam', 25, 92, { 'Extra Shot': 5, 'Vanilla Syrup': 3, Cinnamon: 0 }],
        ['latte', 'Caffe Latte', 'Smooth espresso with steamed milk', 30, 88, { 'Extra Shot': 5, 'Caramel Syrup': 3, 'Almond Milk': 3 }],
      ],
      Sandwiches: [
        ['club_sandwich', 'Club Sandwich', 'Triple-decker with turkey, lettuce, tomato and herb mayo', 45, 78, { 'Extra Turkey': 8, 'No Mayo': 0, 'Add Cheese': 5 }],
        ['grilled_cheese', 'Grilled Cheese', 'Toasted bread with melted cheddar and a side dip', 35, 82, { 'Add Tomato': 3, 'Extra Cheese': 5, 'Whole Wheat Bread': 0 }],
      ],
    },
  },
  {
    uid: 'vendor-pizza-el-nil',
    email: 'pizza.elnil@students.eui.edu.eg',
    name: 'Pizza El-Nil',
    description: 'Stone-oven pizza and pasta',
    rating: 4.3,
    reviewCount: 67,
    cover: 'pizza_cover',
    menu: {
      Pizza: [
        ['margherita', 'Margherita Pizza', 'Classic tomato, mozzarella, and fresh basil', 60, 95, { 'Extra Cheese': 10, 'Thin Crust': 0, 'Extra Basil': 0 }],
        ['pepperoni', 'Pepperoni Pizza', 'Tomato sauce, mozzarella, and beef pepperoni', 75, 89, { 'Extra Pepperoni': 12, 'Extra Cheese': 10, 'Thick Crust': 5 }],
      ],
      Pasta: [
        ['carbonara', 'Spaghetti Carbonara', 'Creamy pasta with parmesan and black pepper', 55, 76, { 'Extra Parmesan': 5, 'Add Chicken': 12, 'No Cream': 0 }],
      ],
    },
  },
  {
    uid: 'vendor-healthy-choice',
    email: 'healthy.choice@students.eui.edu.eg',
    name: 'Healthy Choice',
    description: 'Fresh salads, wraps, and healthy options',
    rating: 4.7,
    reviewCount: 29,
    cover: 'healthy_cover',
    menu: {
      Salads: [
        ['caesar', 'Caesar Salad', 'Romaine lettuce, croutons, parmesan, caesar dressing', 40, 84, { 'Grilled Chicken': 15, 'Extra Parmesan': 5, 'No Croutons': 0 }],
        ['greek', 'Greek Salad', 'Mixed greens, feta, olives, tomatoes, cucumber', 45, 72, { 'Extra Feta': 8, 'No Olives': 0, 'Add Avocado': 10 }],
      ],
      Wraps: [
        ['chicken_wrap', 'Grilled Chicken Wrap', 'Grilled chicken, lettuce, tomato, garlic sauce in tortilla', 35, 86, { 'Extra Chicken': 12, 'Spicy Sauce': 0, 'No Garlic': 0 }],
      ],
    },
  },
];

// The first student is the one the customer app signs in as (DemoAccounts.student).
const STUDENTS = [
  ['student-nour', 'Nour Hassan', 'nour.hassan', '21-102004', '+201234567893', 250],
  ['student-mohamed', 'Mohamed Abdelrahman', 'mohamed.abdelrahman', '21-102001', '+201234567890', 150],
  ['student-yasmin', 'Yasmin Mahmoud', 'yasmin.mahmoud', '21-102002', '+201234567891', 200],
  ['student-karim', 'Karim El-Shafei', 'karim.elshafei', '21-102003', '+201234567892', 100],
  ['student-youssef', 'Youssef Ahmed', 'youssef.ahmed', '21-102005', '+201234567894', 80],
].map(([uid, fullName, handle, universityId, phoneNumber, walletBalance]) => ({
  uid,
  fullName,
  email: `${handle}@students.eui.edu.eg`,
  universityId,
  phoneNumber,
  walletBalance,
}));

const ADMIN = { uid: 'admin-eui', fullName: 'Dr. Ahmed Hassan', email: 'admin@eui.edu.eg' };

// ------------------------------------------------------------------ helpers

// Deterministic randomness so every seed produces the same campus.
let state = 20251012;
const rand = () => {
  state = (state + 0x6d2b79f5) | 0;
  let t = Math.imul(state ^ (state >>> 15), 1 | state);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const pick = (list) => list[Math.floor(rand() * list.length)];
const between = (lo, hi) => lo + Math.floor(rand() * (hi - lo + 1));

const imagePath = (vendor, file) => `menu_images/${vendor.uid}/${file}.jpg`;
const itemsOf = (vendor) =>
  Object.entries(vendor.menu).flatMap(([category, rows]) =>
    rows.map(([key, name, description, price, popularity, options]) => ({ key, name, description, price, popularity, options, category })),
  );

async function wipe() {
  const del = (url) => fetch(url, { method: 'DELETE' }).then((r) => {
    if (!r.ok) throw new Error(`${url} -> ${r.status}. Are the emulators running?`);
  });
  await del(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  await del(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/accounts`);
  await getStorage().bucket().deleteFiles({ force: true }).catch(() => {});
}

async function upload(file, destination) {
  const data = await readFile(new URL(`${file}.jpg`, IMAGES));
  await getStorage().bucket().file(destination).save(data, {
    contentType: 'image/jpeg',
    // Lets the client SDK's getDownloadURL() hand back a tokenised URL.
    metadata: { metadata: { firebaseStorageDownloadTokens: randomUUID() } },
  });
}

// ------------------------------------------------------------------ seed

initializeApp({ projectId: PROJECT, storageBucket: BUCKET });
const auth = getAuth();
const db = getFirestore();

await wipe();

const now = new Date();
const created = Timestamp.fromDate(new Date(now.getTime() - 90 * 864e5));

// Accounts
for (const s of STUDENTS) {
  await auth.createUser({ uid: s.uid, email: s.email, password: PASSWORD, displayName: s.fullName, emailVerified: true });
  await db.doc(`users/${s.uid}`).set({
    fullName: s.fullName,
    email: s.email,
    universityId: s.universityId,
    universityName: UNIVERSITY.name,
    phoneNumber: s.phoneNumber,
    isEmailVerified: true,
    role: 'student',
    walletBalance: s.walletBalance,
    profileImageUrl: '',
    fcmToken: '',
    createdAt: created,
  });
}

await auth.createUser({ uid: ADMIN.uid, email: ADMIN.email, password: PASSWORD, displayName: ADMIN.fullName, emailVerified: true });
await db.doc(`users/${ADMIN.uid}`).set({
  fullName: ADMIN.fullName,
  email: ADMIN.email,
  universityId: UNIVERSITY.id,
  universityName: UNIVERSITY.name,
  phoneNumber: '+20225550100',
  isEmailVerified: true,
  role: 'admin',
  walletBalance: 0,
  profileImageUrl: '',
  fcmToken: '',
  createdAt: created,
});

await db.doc(`universities/${UNIVERSITY.id}`).set({
  name: UNIVERSITY.name,
  emailDomain: 'students.eui.edu.eg',
  city: 'New Cairo',
  createdAt: created,
});

// Vendors, menus and photos
for (const v of VENDORS) {
  await auth.createUser({ uid: v.uid, email: v.email, password: PASSWORD, displayName: v.name, emailVerified: true });
  await db.doc(`users/${v.uid}`).set({
    fullName: v.name,
    email: v.email,
    universityId: UNIVERSITY.id,
    universityName: UNIVERSITY.name,
    phoneNumber: '+20100000' + String(VENDORS.indexOf(v) + 1).padStart(4, '0'),
    isEmailVerified: true,
    role: 'vendor',
    walletBalance: 0,
    profileImageUrl: '',
    fcmToken: '',
    createdAt: created,
  });

  const cover = `vendors/${v.uid}/cover.jpg`;
  await upload(v.cover, cover);
  await db.doc(`vendors/${v.uid}`).set({
    name: v.name,
    userId: v.uid,
    universityId: UNIVERSITY.id,
    universityName: UNIVERSITY.name,
    description: v.description,
    imageUrl: cover, // a Storage path; StorageImage resolves it
    rating: v.rating,
    reviewCount: v.reviewCount,
    categories: Object.keys(v.menu),
    isOpen: true,
    isApproved: true,
    isSuspended: false,
    createdAt: created,
  });

  // Same shape the vendor app writes: one menu document, a map per category,
  // a map per item inside it.
  const menu = {};
  let cid = 1;
  for (const [category, rows] of Object.entries(v.menu)) {
    menu[category] = { Name: category, CID: cid++ };
    for (const [key, name, description, price, popularity, options] of rows) {
      await upload(key, imagePath(v, key));
      menu[category][`item_${key}`] = {
        Name: name,
        Description: description,
        Price: price,
        ImagePath: imagePath(v, key),
        Popularity: popularity,
        Category: category,
        IsAvailable: true,
        CustomizationOptions: options,
      };
    }
  }
  await db.doc(`vendors/${v.uid}/menu/main`).set(menu);
}

// Orders: eight weeks of lunchtimes (closed Fridays), plus today's live queue.
const orders = [];
const order = (student, vendor, at, status, lines = between(1, 3)) => {
  const menu = itemsOf(vendor);
  const items = [];
  for (let i = 0; i < lines; i++) {
    const item = pick(menu);
    if (items.some((x) => x.id === `item_${item.key}`)) continue;
    const extras = Object.entries(item.options).filter(() => rand() < 0.25);
    const customizations = Object.fromEntries(extras);
    const unit = item.price + extras.reduce((sum, [, p]) => sum + p, 0);
    items.push({
      id: `item_${item.key}`,
      name: item.name,
      price: unit,
      quantity: rand() < 0.8 ? 1 : 2,
      note: rand() < 0.1 ? pick(['No onions please', 'Extra napkins', 'Pick up at 1:15']) : '',
      customizations,
    });
  }
  const total = items.reduce((sum, x) => sum + x.price * x.quantity, 0);
  orders.push({
    ref: db.collection('orders').doc(),
    data: {
      userId: student.uid,
      vendorId: vendor.uid,
      items,
      total,
      status,
      paymentMethod: rand() < 0.66 ? 'Wallet' : 'Cash',
      createdAt: Timestamp.fromDate(at),
    },
  });
  return orders.at(-1);
};

const at = (daysAgo, hour, minute) => {
  const d = new Date(now);
  d.setDate(d.getDate() - daysAgo);
  d.setHours(hour, minute, between(0, 59), 0);
  return d;
};

for (let daysAgo = 56; daysAgo >= 1; daysAgo--) {
  if (at(daysAgo, 12, 0).getDay() === 5) continue; // Friday
  const count = between(3, 7);
  for (let i = 0; i < count; i++) {
    const hour = pick([9, 10, 11, 12, 12, 13, 13, 13, 14, 15]);
    order(pick(STUDENTS), pick(VENDORS), at(daysAgo, hour, between(0, 59)), rand() < 0.05 ? 'cancelled' : 'completed');
  }
}

// Today: one order per stage so the vendor queue and the student's tracker have something to show.
const [nour, mohamed, yasmin, karim, youssef] = STUDENTS;
const [cafe, pizza, healthy] = VENDORS;
// Outside campus hours the live queue is pinned to today's lunch rush, so
// screenshots taken at night still show orders placed around 12:50.
const open = now.getHours() >= 8 && now.getHours() < 20;
const anchor = open ? now : new Date(new Date(now).setHours(12, 52, 0, 0));
const minutesAgo = (m) => new Date(anchor.getTime() - m * 60e3);
order(karim, cafe, minutesAgo(48), 'completed', 2);
order(youssef, cafe, minutesAgo(21), 'ready', 1);
const active = order(nour, cafe, minutesAgo(6), 'confirmed', 2);
order(mohamed, cafe, minutesAgo(4), 'confirmed', 1);
order(yasmin, cafe, minutesAgo(2), 'pending', 2);
order(karim, cafe, minutesAgo(1), 'pending', 1);
order(yasmin, pizza, minutesAgo(15), 'ready', 1);
order(mohamed, healthy, minutesAgo(9), 'pending', 2);

// Writes each order where the apps read it: /orders and the vendor's copy.
for (let i = 0; i < orders.length; i += 200) {
  const batch = db.batch();
  for (const { ref, data } of orders.slice(i, i + 200)) {
    const doc = { id: ref.id, ...data };
    batch.set(ref, doc);
    batch.set(db.doc(`vendors/${data.vendorId}/orders/${ref.id}`), doc);
  }
  await batch.commit();
}

// Notifications for the demo student (normally sent by a Cloud Function).
const nourOrders = orders.filter((o) => o.data.userId === nour.uid);
const recent = nourOrders.filter((o) => o.data.status === 'completed').slice(-3);
const notes = [
  [active, 'confirmed', 'Order confirmed', `${cafe.name} is preparing your order.`, false, 5],
  ...recent.map((o, i) => [o, 'ready', 'Your order is ready', `Pick it up at ${VENDORS.find((v) => v.uid === o.data.vendorId).name}.`, true, null]),
];
for (const [o, status, title, body, read, minsAgo] of notes) {
  const when = minsAgo == null ? new Date(o.data.createdAt.toDate().getTime() + 14 * 60e3) : minutesAgo(minsAgo);
  await db.collection('notifications').add({
    userId: nour.uid,
    orderId: o.ref.id,
    title,
    body,
    status,
    read,
    createdAt: Timestamp.fromDate(when),
  });
}

console.log(
  `Seeded ${STUDENTS.length} students, ${VENDORS.length} vendors, ` +
    `${VENDORS.reduce((n, v) => n + itemsOf(v).length, 0)} menu items, ${orders.length} orders ` +
    `(${nourOrders.length} for ${nour.fullName}), ${notes.length} notifications.`,
);
console.log(`Sign in with any seeded email and the password "${PASSWORD}".`);
process.exit(0);
