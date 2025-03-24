import express from 'express';
import bodyParser from 'body-parser';
import admin from 'firebase-admin';

(async () => {
  try {
    // Initialize Firebase Admin SDK
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          type: process.env.FIREBASE_TYPE,
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
          client_id: process.env.FIREBASE_CLIENT_ID,
          auth_uri: process.env.FIREBASE_AUTH_URI,
          token_uri: process.env.FIREBASE_TOKEN_URI,
          auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
          client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
          universe_domain: process.env.FIREBASE_UNIVERSE_DOMAIN,
        }),
        databaseURL: process.env.FIREBASE_DATABASE_URL,
      });
    }

    const app = express();
    const PORT = process.env.PORT || 3000;

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
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Payment Success</title>
            <style>
              body {
                text-align: center;
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 20px;
                box-sizing: border-box;
              }
              h1 {
                color: green;
              }
              p {
                font-size: 16px;
              }
            </style>
          </head>
          <body>
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
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Payment Failed</title>
            <style>
              body {
                text-align: center;
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 20px;
                box-sizing: border-box;
              }
              h1 {
                color: red;
              }
              p {
                font-size: 16px;
              }
            </style>
          </head>
          <body>
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
