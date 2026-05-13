// functions/index.js
//
// ✅ PRODUCTION CLOUD FUNCTIONS FOR CAMPUSLINK
//
// DEPLOY: firebase deploy --only functions
//
// SETUP:
//   1. cd functions && npm install
//   2. firebase functions:config:set paystack.secret="sk_live_YOUR_KEY"
//   3. firebase functions:config:set paystack.webhook_secret="YOUR_WEBHOOK_SECRET"
//   4. firebase deploy --only functions
//
// FUNCTIONS IN THIS FILE:
//
//   onBookingCompleted     — Triggered when bookingStatus → 'completed'
//                            Calls Paystack Transfer API to release funds to provider
//
//   onBookingCancelled     — Triggered when bookingStatus → 'cancelled'
//                            Calls Paystack Refund API to return funds to seeker
//
//   paystackWebhook        — HTTP webhook called by Paystack after payment
//                            Updates escrowStatus to 'held' when payment succeeds
//
//   onKycSubmitted         — Triggered when kycFrontUrl is written to a user doc
//                            Placeholder for admin review notification
//
//   approveKyc             — HTTPS Callable — called by admin dashboard
//                            Sets kycStatus to 'verified' or 'rejected'

const functions = require('firebase-functions');
const admin     = require('firebase-admin');
const axios     = require('axios');
const crypto    = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// Read Paystack secret from Firebase environment config
// Set with: firebase functions:config:set paystack.secret="sk_live_..."
const PAYSTACK_SECRET       = functions.config().paystack?.secret       || '';
const PAYSTACK_WEBHOOK_SECRET = functions.config().paystack?.webhook_secret || '';

// =============================================================================
// 1. ESCROW RELEASE — onBookingCompleted
// =============================================================================
// Triggered: when bookingStatus changes to 'completed' in any booking document.
// Action:    Calls Paystack Transfer API to transfer funds to provider's MoMo.
//            Then updates escrowStatus to 'released'.
//
// Paystack Transfer API docs:
//   https://paystack.com/docs/transfers/single-transfers/

exports.onBookingCompleted = functions
  .region('us-central1')
  .firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();

    // Only run when bookingStatus transitions to 'completed'
    if (before.bookingStatus === after.bookingStatus) return null;
    if (after.bookingStatus !== 'completed') return null;

    // Must have funds held in escrow to release
    if (after.escrowStatus !== 'held') {
      console.warn(`Booking ${context.params.bookingId} completed but escrow not held. Status: ${after.escrowStatus}`);
      return null;
    }

    const bookingId  = context.params.bookingId;
    const providerUid = after.providerUid;

    try {
      // Step 1: Fetch provider's MoMo number from Firestore
      const providerDoc = await db.collection('users').doc(providerUid).get();
      if (!providerDoc.exists) {
        throw new Error(`Provider ${providerUid} not found`);
      }

      const providerData  = providerDoc.data();
      const momoNumber    = providerData.momoNumber;
      const providerName  = providerData.fullName;

      if (!momoNumber) {
        throw new Error(`Provider ${providerUid} has no MoMo number`);
      }

      // Step 2: Calculate payout (total minus 5% platform fee)
      const totalAmount   = after.totalAmount;          // GHS (e.g. 126.00)
      const platformFee   = totalAmount * 0.05;
      const providerPayout = totalAmount - platformFee; // 95% goes to provider

      // Paystack uses kobo/pesewas (smallest currency unit)
      // For GHS: 1 GHS = 100 pesewas
      const amountInPesewas = Math.round(providerPayout * 100);

      // Step 3: Create a Paystack Transfer Recipient for this provider's MoMo
      // (In production, cache recipient_code in Firestore to avoid re-creating)
      const recipientResponse = await axios.post(
        'https://api.paystack.co/transferrecipient',
        {
          type:          'mobile_money',
          name:          providerName,
          account_number: momoNumber,
          bank_code:     _getMomoNetworkCode(momoNumber), // MTN, VOD, ATL
          currency:      'GHS',
        },
        {
          headers: {
            Authorization: `Bearer ${PAYSTACK_SECRET}`,
            'Content-Type': 'application/json',
          },
        }
      );

      const recipientCode = recipientResponse.data.data.recipient_code;

      // Step 4: Initiate the transfer
      const transferResponse = await axios.post(
        'https://api.paystack.co/transfer',
        {
          source:    'balance',
          amount:    amountInPesewas,
          recipient: recipientCode,
          reason:    `CampusLink payout — Booking ${bookingId}`,
          currency:  'GHS',
        },
        {
          headers: {
            Authorization: `Bearer ${PAYSTACK_SECRET}`,
            'Content-Type': 'application/json',
          },
        }
      );

      const transferCode = transferResponse.data.data.transfer_code;

      // Step 5: Update Firestore — escrowStatus released, store transfer ref
      await change.after.ref.update({
        escrowStatus:    'released',
        transferCode:    transferCode,
        releasedAt:      admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:       admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Booking ${bookingId}: GHS ${providerPayout.toFixed(2)} released to ${momoNumber}`);
      return null;

    } catch (error) {
      console.error(`❌ Booking ${bookingId} release failed:`, error.message);

      // Mark as failed so admin can investigate — do NOT leave as 'held'
      await change.after.ref.update({
        escrowStatus:  'releaseFailed',
        releaseError:  error.message,
        updatedAt:     admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

// =============================================================================
// 2. ESCROW REFUND — onBookingCancelled
// =============================================================================
// Triggered: when bookingStatus changes to 'cancelled'.
// Action:    If funds were held, refund to seeker via Paystack.

exports.onBookingCancelled = functions
  .region('us-central1')
  .firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();

    if (before.bookingStatus === after.bookingStatus) return null;
    if (after.bookingStatus !== 'cancelled') return null;

    // Only refund if funds were actually held
    if (after.escrowStatus !== 'held') {
      // Payment never happened — just mark as cancelled, no financial action
      return null;
    }

    const bookingId = context.params.bookingId;
    const paymentRef = after.paymentRef; // Paystack reference from initial payment

    if (!paymentRef) {
      console.warn(`Booking ${bookingId}: no paymentRef found, cannot refund`);
      return null;
    }

    try {
      const amountInPesewas = Math.round(after.totalAmount * 100);

      // Initiate Paystack refund
      await axios.post(
        'https://api.paystack.co/refund',
        {
          transaction: paymentRef,
          amount:      amountInPesewas,
        },
        {
          headers: {
            Authorization: `Bearer ${PAYSTACK_SECRET}`,
            'Content-Type': 'application/json',
          },
        }
      );

      await change.after.ref.update({
        escrowStatus: 'refunded',
        refundedAt:   admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Booking ${bookingId}: GHS ${after.totalAmount} refunded`);
      return null;

    } catch (error) {
      console.error(`❌ Booking ${bookingId} refund failed:`, error.message);
      await change.after.ref.update({
        escrowStatus: 'refundFailed',
        refundError:  error.message,
        updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    }
  });

// =============================================================================
// 3. PAYSTACK WEBHOOK — paystackWebhook
// =============================================================================
// Paystack calls this URL after a payment is processed.
// It verifies the signature, then updates escrowStatus to 'held'.
//
// CONFIGURE IN PAYSTACK DASHBOARD:
//   Settings → API Keys & Webhooks → Webhook URL:
//   https://us-central1-YOUR_PROJECT.cloudfunctions.net/paystackWebhook
//
// The booking document must have paymentRef set BEFORE this fires.
// Flow:
//   1. Flutter client calls initializePayment Cloud Function (or direct Paystack)
//   2. User completes MoMo payment
//   3. Paystack fires this webhook
//   4. We find the booking by paymentRef and set escrowStatus = 'held'

exports.paystackWebhook = functions
  .region('us-central1')
  .https
  .onRequest(async (req, res) => {
    // Paystack sends the signature in the header
    const signature = req.headers['x-paystack-signature'];

    // Verify the webhook is genuinely from Paystack
    const hash = crypto
      .createHmac('sha512', PAYSTACK_WEBHOOK_SECRET)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (hash !== signature) {
      console.warn('Paystack webhook: invalid signature');
      return res.sendStatus(401);
    }

    const event = req.body;
    console.log(`Paystack event received: ${event.event}`);

    // We only care about successful charge completions
    if (event.event !== 'charge.success') {
      return res.sendStatus(200); // Acknowledge but ignore other events
    }

    const paymentRef = event.data.reference;
    const amountPaid = event.data.amount / 100; // Convert from pesewas to GHS

    try {
      // Find the booking with this payment reference
      const bookingQuery = await db
        .collection('bookings')
        .where('paymentRef', '==', paymentRef)
        .limit(1)
        .get();

      if (bookingQuery.empty) {
        console.warn(`No booking found for payment ref: ${paymentRef}`);
        return res.sendStatus(200); // Still ACK to avoid Paystack retries
      }

      const bookingDoc = bookingQuery.docs[0];

      // Update escrowStatus to 'held' — funds are secured
      await bookingDoc.ref.update({
        escrowStatus: 'held',
        amountPaid:   amountPaid,
        paidAt:       admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Escrow held for booking ${bookingDoc.id}, GHS ${amountPaid}`);
      return res.sendStatus(200);

    } catch (error) {
      console.error('Webhook processing error:', error);
      // Return 200 anyway — Paystack will retry on 5xx, which could cause
      // duplicate updates. Better to fail silently and investigate via logs.
      return res.sendStatus(200);
    }
  });

// =============================================================================
// 4. KYC SUBMITTED — onKycSubmitted
// =============================================================================
// Triggered: when a user document is updated with kycFrontUrl (after upload).
// Action:    Sends an admin notification email and creates a review queue entry.
//
// For the MVP the "review" can be manual (an admin checks the Firebase Console).
// For production: integrate with a document review API or admin dashboard.

exports.onKycSubmitted = functions
  .region('us-central1')
  .firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();

    // Only trigger when kycFrontUrl is first added (submission, not re-submission)
    const justSubmitted = !before.kycFrontUrl && after.kycFrontUrl;
    if (!justSubmitted) return null;

    const uid      = context.params.uid;
    const userName = after.fullName;
    const email    = after.universityEmail;

    // Write to a kycQueue collection for admin to review
    await db.collection('kycQueue').doc(uid).set({
      uid:           uid,
      fullName:      userName,
      email:         email,
      frontUrl:      after.kycFrontUrl,
      backUrl:       after.kycBackUrl || null,
      submittedAt:   admin.firestore.FieldValue.serverTimestamp(),
      reviewStatus:  'pending', // pending | approved | rejected
    });

    console.log(`KYC submission queued for ${userName} (${uid})`);
    return null;
  });

// =============================================================================
// 5. APPROVE / REJECT KYC — approveKyc (HTTPS Callable)
// =============================================================================
// Called by: Admin dashboard (a separate web app or Firebase Console extension).
// NOT callable from the student app — requires admin role check.
//
// To call from admin dashboard:
//   const functions = getFunctions();
//   const approveKyc = httpsCallable(functions, 'approveKyc');
//   await approveKyc({ uid: 'user-uid', decision: 'verified', reason: '' });

exports.approveKyc = functions
  .region('us-central1')
  .https
  .onCall(async (data, context) => {
    // Require the caller to have the 'admin' custom claim
    // Set with: admin.auth().setCustomUserClaims(uid, { admin: true })
    if (!context.auth || !context.auth.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can approve KYC submissions.'
      );
    }

    const { uid, decision, reason } = data;

    if (!uid || !decision) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid and decision are required.'
      );
    }

    if (!['verified', 'rejected'].includes(decision)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'decision must be "verified" or "rejected".'
      );
    }

    // Update the user's kycStatus in Firestore
    // The live stream in AuthProvider will pick this up automatically
    await db.collection('users').doc(uid).update({
      kycStatus:    decision,
      kycReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      kycRejectReason: reason || null,
      updatedAt:    admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update the KYC queue entry
    await db.collection('kycQueue').doc(uid).update({
      reviewStatus: decision,
      reviewedAt:   admin.firestore.FieldValue.serverTimestamp(),
      reviewedBy:   context.auth.uid,
    });

    console.log(`KYC ${decision} for user ${uid} by admin ${context.auth.uid}`);
    return { success: true };
  });

// =============================================================================
// HELPER: Get Paystack bank code for Ghanaian MoMo networks
// =============================================================================
// Paystack requires a bank_code to route transfers to the correct MoMo network.
// Numbers starting with 024/054/055/059 are MTN; 020/050 are Telecel; etc.

function _getMomoNetworkCode(phoneNumber) {
  const cleaned = phoneNumber.replace(/[\s\-]/g, '');
  const prefix = cleaned.substring(0, 3);

  const mtnPrefixes      = ['024', '054', '055', '059', '025'];
  const telecelPrefixes  = ['020', '050'];
  const airteltigo       = ['026', '056', '027', '057', '023', '053'];

  if (mtnPrefixes.includes(prefix))     return 'MTN';   // Paystack bank_code for MTN Ghana
  if (telecelPrefixes.includes(prefix)) return 'VOD';   // Telecel (formerly Vodafone)
  if (airteltigo.includes(prefix))      return 'ATL';   // AirtelTigo

  return 'MTN'; // Default fallback
}
