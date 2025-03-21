/* eslint-disable max-len */
import {onValueCreated} from "firebase-functions/v2/database";
import * as admin from "firebase-admin";
import moment from "moment-timezone";

admin.initializeApp();

const db = admin.firestore();
const rtdb = admin.database();

// Example rate
const ratePerKwh = 17;

/**
 * This v2 function triggers whenever a new value is written
 * at /meterData/{meterName}/{pushId}, i.e. a newly created child.
 *
 * It's equivalent to the v1 "functions.database.ref(...).onCreate(...)"
 * but in v2 we use onValueCreated(...).
 */
export const onNewMeterReading = onValueCreated(
  "/meterData/{meterName}/{pushId}",
  async (event) => {
    // event.params: { meterName, pushId }
    const meterName = event.params.meterName; // e.g. "meterA"

    const meterCtrlRef = rtdb.ref(`/meterControl/${meterName}/enabled`);

    // event.data is the DataSnapshot for the newly created child
    //   =>  event.data?.val() is the actual object
    const readingData = event.data?.val();
    if (!readingData || readingData.totalEnergy === undefined) {
      console.log(`No 'totalEnergy' for meter=${meterName}, skipping.`);
      return;
    }

    const newEnergy = Math.abs(readingData.totalEnergy);
    console.log(`New reading for meter=${meterName}, totalEnergy=${newEnergy}`);

    // 1) Find the user doc in Firestore with meterName == meterName
    const userSnap = await db
      .collection("users")
      .where("meterName", "==", meterName)
      .where("active", "==", true)
      .limit(1)
      .get();

    if (userSnap.empty) {
      console.log(`No active user found for meter=${meterName}`);
      await meterCtrlRef.set(false);
      return;
    }

    const userDoc = userSnap.docs[0];
    const userData = userDoc.data();
    const oldBalance: number = userData.balance || 0;
    const lastEnergy: number = userData.lastTotalEnergy || 0;

    // usage = new - old
    let usage = newEnergy - lastEnergy;
    if (usage < 0) {
      console.log(`Usage negative => usage=${usage}. Setting usage=0`);
      usage = 0;
    }

    const cost = usage * ratePerKwh;
    const newBalance = oldBalance - cost;

    console.log(
      `User ${userDoc.id}: usage=${usage.toFixed(3)} kWh, ` +
      `cost=${cost.toFixed(2)}, oldBal=${oldBalance}, newBal=${newBalance}`
    );

    // Update user doc
    await userDoc.ref.update({
      balance: newBalance,
      lastTotalEnergy: newEnergy,
    });

    // Check the current meterControl state
    const meterCtrlSnap = await meterCtrlRef.get();
    const currentEnabled = meterCtrlSnap.exists() ? !!meterCtrlSnap.val() : true;
    // If no entry in DB, default to "true" (meter on)

    if (newBalance > 0) {
      // Positive or zero balance => definitely keep meter on
      console.log(`Balance >= 0. Ensuring meter ${meterName} is ON.`);
      await meterCtrlRef.set(true);
    } else {
      // newBalance < 0 => we have potential shutoff scenario
      console.log(`User has negative balance. Checking grace period & currentEnabled: ${currentEnabled}`);
      const now = moment().tz("Asia/Manila");
      const hour = now.hour(); // 0..23
      const isGracePeriod = (hour >= 21 || hour < 8);

      // Only apply grace if meter is currently ON
      if (isGracePeriod && currentEnabled) {
        console.log("Grace period (9pm–8am) + meter is ON => keep meter ON despite negative balance.");
      } else {
        console.log(`Outside grace or meter already OFF => turning off meter=${meterName}.`);
        await meterCtrlRef.set(false);
      }
    }

    return;
  }
);
