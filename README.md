markdown# CampusLink 🎓
> The exclusive peer-to-peer marketplace for UCC student services.

CampusLink connects verified University of Cape Coast students — seekers who need services and providers who offer them — through a trusted, escrow-protected platform built on Mobile Money.

---

## 📱 App Preview
> Screenshots coming after UI/UX polish sprint

---

## 🏗️ Project Status

| Sprint | Status | Owner |
|--------|--------|-------|
| Sprint 1 — Auth & Onboarding | ✅ Frontend Complete | Kwesi |
| Sprint 1 — Backend & Auth | 🔴 Not Started | Petronilo & Eric |
| Sprint 1 — Middleware & Email Validation | 🔴 Not Started | Bernard |
| Sprint 2 — Marketplace UI | ✅ Frontend Complete | Kwesi |
| Sprint 2 — Firestore & Storage | 🔴 Not Started | Petronilo & Eric |
| Sprint 2 — Escrow & Paystack | 🔴 Not Started | Bernard |
| Sprint 3 — Firebase Connection | ⏳ Pending Backend | All |
| Sprint 3 — Push Notifications | ⏳ Pending | All |
| UI/UX Polish | 🟡 In Progress | Ursula |

---

## 👥 Team

| Name | Role | Responsibilities |
|------|------|-----------------|
| Kwesi Manteaw | Frontend Lead | Flutter UI, State Management, Navigation |
| Ursula | UI/UX Designer | Figma wireframes, Design system, Screen polish |
| Petronilo | Backend Lead | Firebase Auth, Firestore, Storage |
| Eric | Backend | Firebase Rules, Indexes, Cloud Functions |
| Bernard | Middleware Lead | Paystack Integration, Escrow Logic, Cloud Functions |

---

## 🎨 UI/UX Tasks — Ursula

### Design Brief
CampusLink is a peer-to-peer student marketplace for the University of Cape Coast.
The app is built in Flutter so all designs must be delivered as high-fidelity
Figma screens exported as PNG at 2x resolution.

### Design System (Already Established — Keep Consistent)
Primary color:    #1A237E  (dark navy)
Accent color:     #1565C0  (blue)
Success:          #16A34A  (green)
Warning:          #F59E0B  (amber)
Error:            #DC2626  (red)
Background:       #F5F6FA  (off-white)
Card background:  #FFFFFF  (white)
Field background: #EEF0F5  (light grey)
Border:           #E5E7EB
Typography:
Heading 1:  24px, Bold
Heading 2:  18px, SemiBold
Body:       15px, Regular
Caption:    12px, Regular
Field label:11px, SemiBold, ALL CAPS, letter-spacing 1.2
Components:
Buttons:      56px tall, fully pill-shaped (border-radius 100px)
Input fields: 52px tall, border-radius 12px, grey fill
Cards:        border-radius 16px, white, subtle shadow
Bottom nav:   56px tall

### Design Constraints for Flutter
Canvas size:    390 × 844px (iPhone 14 — Flutter scales to all devices)
Export format:  PNG at 2x
Bottom nav:     56px height
Pill buttons:   56px tall
Input fields:   52px tall, 12px corner radius
Cards:          16px corner radius
Text contrast:  Must pass WCAG AA

### Screens to Design — Priority Order

#### PRIORITY 1 — Core Auth Flow
- [ ] Welcome / Onboarding screen
- [ ] Register screen (with role selector)
- [ ] KYC Verification screen (ID upload)
- [ ] Pending Approval screen
- [ ] Rejected KYC screen

#### PRIORITY 2 — Marketplace
- [ ] Home feed screen
- [ ] Service Detail screen
- [ ] Payment / Booking confirmation bottom sheet
- [ ] Booking Status screen (all 4 progress states)

#### PRIORITY 3 — Provider
- [ ] Provider Dashboard
- [ ] Add New Service screen
- [ ] Earnings screen

#### PRIORITY 4 — Shared
- [ ] Bookings list screen (seeker view)
- [ ] Bookings list screen (provider view)
- [ ] Bookings list screen (dual-role tabbed view)
- [ ] Profile screen

#### PRIORITY 5 — Edge States
- [ ] Empty state — no bookings
- [ ] Empty state — no services
- [ ] Error state — no internet
- [ ] Loading skeleton screens

### Delivery Format
For each screen deliver:

Figma frame (keep source editable)
PNG export at 2x
Any new icons or illustrations as SVG

Hand off to Kwesi via:

Figma share link with view access, OR
PNG exports dropped in the /designs folder
of this repository


### Current App Screenshots
> See /screenshots folder for current state of the app
> Use these as reference for what exists and what needs polish

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Flutter (Dart) | Mobile app (Android + iOS) |
| State Management | Provider | Auth, Service, Booking state |
| Database | Firebase Cloud Firestore | Real-time NoSQL database |
| Authentication | Firebase Auth | Email/password + domain restriction |
| Storage | Firebase Cloud Storage | KYC photos, service images |
| Middleware | Firebase Cloud Functions (Node.js) | Business logic, escrow state machine |
| Payments | Paystack API | MoMo escrow, transfers, webhooks |
| Design | Figma | Wireframes and UI specs |
| Version Control | GitHub | Branching, PRs, code review |

---

## 📁 Project Structure
coolapp/
├── lib/
│   ├── core/
│   │   ├── constants.dart      # Colors, styles, spacing
│   │   ├── routes.dart         # All named routes
│   │   └── validators.dart     # Form validation logic
│   │
│   ├── models/
│   │   ├── user_model.dart     # ⚠️ Shared contract — agree before changing
│   │   ├── service_model.dart  # ⚠️ Shared contract — agree before changing
│   │   └── booking_model.dart  # ⚠️ Shared contract — agree before changing
│   │
│   ├── services/               # ← PETRONILO & ERIC implement these
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── storage_service.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── service_provider.dart
│   │   └── booking_provider.dart
│   │
│   ├── screens/
│   │   ├── auth/               # Login, Register, KYC, Pending
│   │   ├── seeker/             # Home, Service Detail, Booking Status
│   │   ├── provider/           # Dashboard, Add Service, Earnings
│   │   └── shared/             # Bookings, Profile
│   │
│   ├── widgets/                # 14 reusable UI components
│   └── main.dart               # App entry point + AuthGate
│
├── functions/                  # ← BERNARD implements these
│   └── src/
│       └── index.ts            # Cloud Functions
│
├── designs/                    # ← URSULA drops Figma exports here
│   ├── sprint-1/
│   ├── sprint-2/
│   └── sprint-3/
│
├── screenshots/                # Current app state for reference
│
├── android/app/
│   └── google-services.json   # ← PETRONILO & ERIC add this
│
└── ios/Runner/
└── GoogleService-Info.plist # ← PETRONILO & ERIC add this

---

## 🔴 Backend Tasks — Petronilo & Eric

### Setup (Do this first — everything else depends on it)
- [ ] Create Firebase project named `campuslink`
- [ ] Enable Authentication, Firestore, Cloud Storage
- [ ] Generate and share `google-services.json` → place in `android/app/`
- [ ] Generate and share `GoogleService-Info.plist` → place in `ios/Runner/`
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Run `firebase init` (select Functions + Firestore + Storage)
- [ ] Share both config files with Kwesi immediately

### Sprint 1 Tasks

#### `lib/services/auth_service.dart`
Look for all comments marked `[PETRONILO & ERIC: IMPLEMENT FROM HERE]`
- [ ] `registerUser()` — Firebase Auth `createUserWithEmailAndPassword()`
- [ ] After registration, create Firestore document in `users` collection with exact fields:
  `uid, fullName, universityEmail, roles, kycStatus: 'pending', momoNumber: null, createdAt`
- [ ] Send email verification: `credential.user.sendEmailVerification()`
- [ ] `loginUser()` — Firebase Auth `signInWithEmailAndPassword()`
- [ ] After login, fetch full UserModel from Firestore
- [ ] `fetchUserModel()` — Firestore `users/{uid}` get
- [ ] `signOut()` — Firebase Auth `signOut()`
- [ ] `authStateChanges` stream — Firebase Auth `authStateChanges()`

#### `lib/models/user_model.dart`
- [ ] Confirm all field names match exactly what you store in Firestore
- [ ] **DO NOT rename any fields without telling Kwesi**
- [ ] Required fields: `uid, fullName, universityEmail, roles, kycStatus, momoNumber, createdAt`

#### `lib/services/storage_service.dart`
- [ ] `uploadKycImages()` — Firebase Storage paths:
  - `kyc/{uid}/front.jpg`
  - `kyc/{uid}/back.jpg`
- [ ] After upload, update `users/{uid}` with:
  `kycFrontUrl, kycBackUrl, kycSubmittedAt, kycStatus: 'pending'`

#### Firestore Security Rules (`firestore.rules`)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth != null
                    && request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false;
    }
  }
}
```
- [ ] Write rules above in Firebase Console → Firestore → Rules
- [ ] Test using Firebase Console → Rules Playground
- [ ] Deploy: `firebase deploy --only firestore:rules`

### Sprint 2 Tasks

#### `lib/services/firestore_service.dart`
- [ ] `getActiveServices()` — real-time stream, `isActive == true`, ordered by `createdAt DESC`
- [ ] `getServicesByCategory(category)` — filtered real-time stream
- [ ] `getServicesByProvider(providerUid)` — provider's own listings stream
- [ ] `getServiceById(serviceId)` — single document fetch
- [ ] `createService(service)` — write to `services` collection
- [ ] `updateService(serviceId, updates)` — partial document update
- [ ] `deactivateService(serviceId)` — set `isActive: false`
- [ ] `getBookingsAsSeeker(seekerUid)` — real-time stream ordered by `createdAt DESC`
- [ ] `getBookingsAsProvider(providerUid)` — real-time stream ordered by `createdAt DESC`
- [ ] `getBookingById(bookingId)` — real-time single document stream
- [ ] `createBooking(booking)` — write to `bookings` collection
- [ ] `acceptBooking(bookingId)` — update `bookingStatus: confirmed`
- [ ] `declineBooking(bookingId, reason)` — update `bookingStatus: cancelled`
- [ ] `markAsComplete(bookingId)` — update `bookingStatus: completed`
- [ ] `raiseDispute(bookingId, reason)` — update `escrowStatus: disputed`

#### `lib/services/storage_service.dart`
- [ ] `uploadServiceImage(serviceId, imageFile)` — path: `services/{serviceId}/cover.jpg`
- [ ] `uploadAvatar(uid, imageFile)` — path: `avatars/{uid}/profile.jpg`

#### Firestore Indexes (Firebase Console → Firestore → Indexes)
- [ ] `services`: `isActive ASC, createdAt DESC`
- [ ] `bookings`: `seekerUid ASC, createdAt DESC`
- [ ] `bookings`: `providerUid ASC, createdAt DESC`

#### Firestore Security Rules — Sprint 2 additions
```javascript
match /services/{serviceId} {
  allow read: if request.auth != null && isVerified();
  allow create: if request.auth != null
                && isVerified()
                && isProvider();
  allow update, delete:
    if request.auth.uid == resource.data.providerUid;
}

match /bookings/{bookingId} {
  allow read:
    if request.auth.uid == resource.data.seekerUid
    || request.auth.uid == resource.data.providerUid;
  allow create:
    if request.auth != null
    && isVerified()
    && isSeeker();
  allow update:
    if request.auth.uid == resource.data.providerUid
    && !('escrowStatus' in
         request.resource.data.diff(resource.data)
         .affectedKeys());
}

function isVerified() {
  return get(/databases/$(database)/documents/
    users/$(request.auth.uid)).data.kycStatus == 'verified';
}
function isProvider() {
  return 'provider' in
    get(/databases/$(database)/documents/
    users/$(request.auth.uid)).data.roles;
}
function isSeeker() {
  return 'seeker' in
    get(/databases/$(database)/documents/
    users/$(request.auth.uid)).data.roles;
}
```
- [ ] **CRITICAL**: `escrowStatus` must NEVER be writable by client — enforced in rules above

---

## 🟡 Middleware Tasks — Bernard

### Setup (Do this first)
- [ ] Create Paystack account at [paystack.com](https://paystack.com)
- [ ] Get Test Secret Key: Paystack Dashboard → Settings → API Keys
- [ ] Store key in Firebase config:
  `firebase functions:config:set paystack.secret="sk_test_xxx"`
- [ ] Install ngrok for local webhook testing: `npm install -g ngrok`
- [ ] Create `functions/` folder in project root
- [ ] Run `firebase init functions` (select TypeScript)

### Sprint 1 Tasks

#### Email Domain Restriction — `functions/src/index.ts`
- [ ] Write `validateEmailDomain` Firebase Auth Blocking Function
- [ ] Block any email not ending in `@stu.ucc.edu.gh` or `@ucc.edu.gh`
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Test: attempt registration with `test@gmail.com` — must be rejected

```typescript
exports.validateEmailDomain = functions.auth
  .user()
  .beforeCreate(async (user) => {
    const allowed = ['@stu.ucc.edu.gh', '@ucc.edu.gh'];
    const isValid = allowed.some(d => user.email?.endsWith(d));
    if (!isValid) {
      throw new functions.auth.HttpsError(
        'invalid-argument',
        'Only UCC institutional emails are permitted.'
      );
    }
  });
```

#### KYC Status Trigger — `functions/src/index.ts`
- [ ] Write `onKycStatusChange` Firestore trigger
- [ ] Watch `users/{userId}` for `kycStatus` field changes
- [ ] Send approval email when status changes to `verified`
- [ ] Send rejection email when status changes to `rejected`
- [ ] Tool: Firebase Extensions → Trigger Email OR SendGrid

### Sprint 2 Tasks

#### Booking Lifecycle — `functions/src/index.ts`

- [ ] `onBookingCreated` — Firestore onCreate trigger
  - Validate `seekerUid != providerUid` (can't book your own service)
  - Calculate platform fee: `totalAmount * 0.05`
  - Initialize Paystack transaction
  - Store Paystack reference in booking document
  - Send push notification to provider: "New booking request"

- [ ] `onBookingStatusChange` — Firestore onUpdate trigger
  - `pending → confirmed`: notify seeker + send payment link
  - `pending → cancelled`: notify seeker with decline reason
  - `confirmed → completed`: trigger Paystack transfer to provider
  - `any → disputed`: freeze Paystack transfer + alert admin

- [ ] `paystackWebhook` — HTTPS function
  - Verify webhook signature using Paystack secret key
  - `charge.success` → set `escrowStatus: held`, `bookingStatus: confirmed`
  - `transfer.success` → set `escrowStatus: released`
  - `transfer.failed` → set `escrowStatus: disputed`
  - `refund.processed` → set `escrowStatus: refunded`
  - Register URL in Paystack Dashboard → Settings → Webhooks

- [ ] `createPaystackRecipient` — when provider sets MoMo number
  - Call `POST https://api.paystack.co/transferrecipient`
  - Store `recipient_code` in `users/{uid}.paystackRecipientCode`

- [ ] `requestWithdrawal` — HTTPS callable function
  - Verify provider is authenticated
  - Call Paystack Transfer API
  - Deduct 5% platform fee before transfer
  - Record in `withdrawals` Firestore collection

#### Testing Checklist — Bernard
- [ ] Test all webhooks in Paystack Dashboard → Settings → Webhooks
- [ ] Use ngrok to expose local function URL for webhook testing
- [ ] Test full payment flow end-to-end in Paystack test mode
- [ ] Test refund flow
- [ ] Test withdrawal flow
- [ ] Confirm `escrowStatus` is never set by client — only by Cloud Functions

---

## 🔀 Git Workflow
main                    ← stable production code only
│
├── dev               ← integration branch (all PRs merge here first)
│     │
│     ├── frontend/sprint-X     ← Kwesi
│     ├── design/sprint-X       ← Ursula (Figma exports + assets)
│     ├── backend/sprint-X      ← Petronilo & Eric
│     └── middleware/sprint-X   ← Bernard

**Rules:**
- Never push directly to `main`
- All changes go through Pull Requests into `dev`
- At least 1 team member must review and approve before merging
- `dev` → `main` only after full team testing
- Test on emulator/device before opening a PR

**Branch naming:**
frontend/sprint-1
frontend/sprint-2
backend/sprint-1
middleware/sprint-1
design/sprint-2-polish

---

## ⚠️ Dev Mode Bypasses (Remove before production)

The following bypasses are currently active for UI testing.
Petronilo & Eric — when you connect Firebase, revert these:

| File | Bypass Active | How to Revert |
|------|--------------|---------------|
| `auth_provider.dart` | Fake login/register with stub user | Restore Firebase stream in `_init()` |
| `auth_service.dart` | `kycStatus: 'verified'` hardcoded | Uncomment all Firebase calls |
| `firestore_service.dart` | Returns hardcoded stub data | Uncomment all Firestore queries |
| `storage_service.dart` | Returns placeholder image URLs | Uncomment Firebase Storage calls |
| `main.dart` | `pendingKyc` routes to `BottomNavShell` | Route to `PendingApprovalScreen` |
| `pending_approval_screen.dart` | Auto-redirects to home | Restore full pending UI |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Android Studio or VS Code
- Android emulator or physical device
- Developer Mode enabled on Windows (run `start ms-settings:developers`)

### Run the app (Dev Mode — no Firebase needed)
```bash
cd coolapp
flutter pub get
flutter run
```

### Run with Firebase (after Petronilo & Eric complete setup)
```bash
# 1. Add google-services.json to android/app/
# 2. Add GoogleService-Info.plist to ios/Runner/
# 3. Uncomment Firebase.initializeApp() in lib/main.dart
# 4. Uncomment Firebase imports in lib/services/auth_service.dart
# 5. Then run:
flutter run
```

---

## 📋 Agreed Data Contracts
> ⚠️ All three developers must agree before changing any field name

### UserModel
uid              String     Firebase Auth UID
fullName         String     User's full name
universityEmail  String     Must end in @stu.ucc.edu.gh or @ucc.edu.gh
roles            List       ['seeker'] | ['provider'] | ['seeker','provider']
kycStatus        String     'pending' | 'verified' | 'rejected'
momoNumber       String?    Ghanaian mobile number e.g. '0241234567'
createdAt        Timestamp

### ServiceModel
serviceId          String
providerUid        String
providerName       String
providerAvatarUrl  String?
isVerified         bool
title              String
description        String
category           String    snake_case e.g. 'tech_digital'
tags               List
basePrice          double    in GHS
isPriceNegotiable  bool
imageUrl           String?
rating             double    0.0 to 5.0
reviewCount        int
isActive           bool
providerPhone      String?
providerWhatsapp   String?
providerInstagram  String?
providerSnapchat   String?
createdAt          Timestamp

### BookingModel
bookingId      String
seekerUid      String
seekerName     String
providerUid    String
providerName   String
serviceId      String
serviceTitle   String
totalAmount    double    in GHS — includes platform fee
bookingStatus  String    'pending'|'confirmed'|'inProgress'|'completed'|'cancelled'
escrowStatus   String    'awaitingPayment'|'held'|'released'|'disputed'|'refunded'
⚠️ NEVER written by client — Cloud Functions ONLY
paymentRef     String?   Paystack transaction reference
notes          String?
declineReason  String?
disputeReason  String?
createdAt      Timestamp
updatedAt      Timestamp?

---

## 📅 Sprint Timeline
Sprint 1  — Auth & Onboarding          April 2026
Sprint 2  — Marketplace & Bookings     April 2026
Sprint 3  — Firebase + Payments        May 2026
Sprint 4  — Polish + Testing           June 2026
Deadline  — Final submission           July 2026

---

## 📞 Support
For questions contact: support@campuslink.gh

---

*Built with ❤️ by the CampusLink team — University of Cape Coast, Ghana 🇬🇭*
