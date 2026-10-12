# CampusBites demo data

Runs all three apps against the local [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite) with a seeded campus, so the apps can be reviewed and screenshotted without touching the production project. The project id is `demo-campusbites`; "demo-" projects can't reach real Firebase resources.

## What gets seeded

- **Egypt University of Informatics** with three approved vendors: University Café, Pizza El-Nil and Healthy Choice
- 11 menu items with photos (uploaded to the Storage emulator), prices, popularity and extras
- 5 students, one university admin, and a login per vendor
- About 250 orders over the last eight weeks (closed Fridays), plus a live queue for today
- Order notifications for the demo student

Outside campus hours (08:00–20:00) today's live orders are pinned to the lunch rush, so screenshots taken at night still look like a normal day.

## Run it

Needs Node 18+, Java 11+ (for the Firestore emulator) and the Firebase CLI (`npm i -g firebase-tools`).

```bash
cd tool/demo
npm install
npm run demo        # starts the emulators and seeds them; Ctrl+C stops
```

Then run any app with the `DEMO` flag:

```bash
cd apps/customer_app   # or vendor_app / admin_app
flutter run --dart-define=DEMO=true
```

The login screen is prefilled in demo builds. All accounts use the password `campusbites-demo`:

| App | Account |
| --- | --- |
| Customer | `nour.hassan@students.eui.edu.eg` |
| Vendor | `university.cafe@students.eui.edu.eg` |
| Admin | `admin@eui.edu.eg` |

The iOS simulator reaches the emulators on `localhost`; the Android emulator uses `10.0.2.2` automatically. For a physical device, pass `--dart-define=DEMO_HOST=<your machine's LAN IP>`.

## Play the vendor

`node advance.mjs` moves the demo student's latest order to its next status (pending → confirmed → ready → completed) and writes the matching notification, so the order tracker in the customer app updates live. Pass a status to jump straight to it, e.g. `node advance.mjs ready`.

`node seed.mjs` resets everything.

## Not emulated

Push notifications (FCM) and the Cloud Functions behind "Create vendor" aren't part of this repo, so demo builds skip push setup and vendor creation will fail.

Photo credits are in [CREDITS.md](CREDITS.md).
