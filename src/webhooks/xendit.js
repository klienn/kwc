import express from 'express';
import bodyParser from 'body-parser';
import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json'); 
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

(async () => {
  try {
    // Initialize Firebase Admin SDK
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: 'https://kwc-register-7c3e1.firebaseio.com'
      });
    }

    const app = express();
    const PORT = 3000;

    app.use(bodyParser.json());

    app.post('/xendit/webhook', async (req, res) => {
      try {
        const event = req.body;

        console.log('Received event:', event);

        if (event.event === 'ewallet.capture') {
          const { reference_id, status, capture_amount, metadata } = event.data;

          console.log(`Payment for ${reference_id} is now ${status}. Amount: ${capture_amount}`);
    
          if (reference_id === 'test-payload') {
            res.status(200).send('Webhook received');
          }
          if (status === 'SUCCEEDED') {
            const userId = metadata.userId;
            // Convert amount to a number to ensure it's a valid input for increment
            const amountNumber = parseFloat(capture_amount) / 100;

            console.log(`Payment ${reference_id} completed successfully. Adding ${amountNumber} to user ${userId}`);
 
            if (isNaN(amountNumber)) {
              throw new Error(`Invalid amount value: ${capture_amount}`);
            }

            // Reference to the user's document in Firestore
            const userRef = admin.firestore().collection('users').doc(userId);

            // Update the user's balance or add transaction history
            await userRef.set({
              balance: admin.firestore.FieldValue.increment(amountNumber),
              transactions: admin.firestore.FieldValue.arrayUnion({
                transactionId: reference_id,
                amount: amountNumber,
                status,
                timestamp: new Date().toISOString()
              })
            }, { merge: true });

            // Add a new message for successful transaction
            await userRef.collection('messages').add({
              title: 'Payment Successful',
              referenceId: reference_id,
              message: `Your payment of ₱${amountNumber} was successful.`,
              read: false,
              timestamp: new Date().toISOString()
            });

            console.log(`User ${userId} balance updated successfully.`);
          } else if (status === 'FAILED') {
            const userId = metadata.userId;

            // Reference to the user's document in Firestore
            const userRef = admin.firestore().collection('users').doc(userId);

            // Add a new message for failed transaction
            await userRef.collection('messages').add({
              title: 'Payment Failed',
              referenceId: reference_id,
              message: `Your payment of ₱${parseFloat(capture_amount) / 100} has failed. Please try again.`,
              read: false,
              timestamp: new Date().toISOString()
            });

            console.log(`User ${userId} has been notified of the failed payment.`);
          }
        }

        res.status(200).send('Webhook received');
      } catch (error) {
        console.error('Error handling webhook:', error);
        res.status(500).send('Internal Server Error');
      }
    });

    // Route for payment success
    app.get('/payment-success', (req, res) => {
      res.send(`
        <html>
          <body style="text-align: center;">
            <h1>Payment Successful!</h1>
            <p>Your payment was successfully processed.</p>
            <p>Please close this window and return to the app.</p>
          </body>
        </html>
      `);
    });

    // Route for payment failure
    app.get('/payment-failure', (req, res) => {
      res.send(`
        <html>
          <body style="text-align: center;">
            <h1>Payment Failed</h1>
            <p>Unfortunately, your payment could not be processed.</p>
            <p>Please close this window and try again later.</p>
          </body>
        </html>
      `);
    });

    app.listen(PORT, () => {
      console.log(`Webhook server is running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Error initializing server:', error);
    process.exit(1);
  }
})();
