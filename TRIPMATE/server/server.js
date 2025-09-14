// server/index.js
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const axios = require('axios');
const crypto = require('crypto');
const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json'); // download from Firebase console
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID;
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET;

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.post('/create_order', async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt } = req.body;
    const options = { amount, currency, receipt, payment_capture: 1 };
    const auth = {
      username: RAZORPAY_KEY_ID,
      password: RAZORPAY_KEY_SECRET
    };
    const resp = await axios.post('https://api.razorpay.com/v1/orders', options, { auth });
    res.json(resp.data);
  } catch (err) {
    console.error('create_order error', err.response?.data ?? err.message);
    res.status(500).json({ error: err.response?.data ?? err.message });
  }
});

app.post('/verify_payment', async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature, bookingId } = req.body;
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto.createHmac('sha256', RAZORPAY_KEY_SECRET).update(body).digest('hex');

    if (expectedSignature === razorpay_signature) {
      // mark booking paid in Firestore
      await db.collection('bookings').doc(bookingId).update({
        status: 'paid',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        paymentId: razorpay_payment_id,
        razorpayOrderId: razorpay_order_id,
      });
      return res.json({ success: true });
    } else {
      // signature mismatch
      return res.status(400).json({ success: false, message: 'Invalid signature' });
    }
  } catch (err) {
    console.error('verify_payment error', err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Server running on port', PORT));
