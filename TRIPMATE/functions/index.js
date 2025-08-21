const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');

admin.initializeApp();

// Set your Razorpay credentials via Firebase config:
// firebase functions:config:set razorpay.key_id="rzp_test_xxx" razorpay.key_secret="xxxx"

exports.createRazorpayOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  const { amount, currency, receipt, notes } = data || {};
  if (!amount || !currency || !receipt) {
    throw new functions.https.HttpsError('invalid-argument', 'amount, currency, receipt required');
  }
  const key_id = functions.config().razorpay?.key_id;
  const key_secret = functions.config().razorpay?.key_secret;
  if (!key_id || !key_secret) {
    throw new functions.https.HttpsError('failed-precondition', 'Razorpay keys not configured');
  }
  const rzp = new Razorpay({ key_id, key_secret });
  try {
    const order = await rzp.orders.create({ amount, currency, receipt, notes: notes || {} });
    // Do not return secret
    return { id: order.id, amount: order.amount, currency: order.currency, receipt: order.receipt, key: key_id };
  } catch (e) {
    throw new functions.https.HttpsError('internal', e.message || 'Razorpay order error');
  }
});

exports.verifyRazorpaySignature = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  const { orderId, paymentId, signature } = data || {};
  if (!orderId || !paymentId || !signature) {
    throw new functions.https.HttpsError('invalid-argument', 'orderId, paymentId, signature required');
  }
  const key_secret = functions.config().razorpay?.key_secret;
  if (!key_secret) {
    throw new functions.https.HttpsError('failed-precondition', 'Razorpay secret not configured');
  }
  const payload = `${orderId}|${paymentId}`;
  const expected = crypto.createHmac('sha256', key_secret).update(payload).digest('hex');
  const valid = expected === signature;
  return { valid };
});


