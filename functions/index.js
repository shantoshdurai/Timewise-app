const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.setSaturdaySchedule = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const uid = context.auth.uid;
  const userDoc = await admin.firestore().collection("users").doc(uid).get();

  if (!userDoc.exists || userDoc.data().role !== "mentor") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only mentors can perform this action.",
    );
  }

  const { sourceDay, departmentId, yearId } = data;
  const validDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
  if (!validDays.includes(sourceDay)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The source day is invalid.",
    );
  }

  const db = admin.firestore();

  try {
    const sectionsRef = db.collection("departments").doc(departmentId)
        .collection("years").doc(yearId).collection("sections");
    const sectionsSnapshot = await sectionsRef.get();

    if (sectionsSnapshot.empty) {
      throw new functions.https.HttpsError("not-found", "No sections found.");
    }

    const allPromises = [];

    sectionsSnapshot.forEach((sectionDoc) => {
      const sectionId = sectionDoc.id;
      const scheduleRef = sectionsRef.doc(sectionId).collection("schedule");

      const promise = db.runTransaction(async (transaction) => {
        const sourceDaySnapshot = await transaction.get(
          scheduleRef.where("day", "==", sourceDay),
        );

        const saturdaySnapshot = await transaction.get(
          scheduleRef.where("day", "==", "Saturday"),
        );

        saturdaySnapshot.forEach((doc) => {
          transaction.delete(doc.ref);
        });

        sourceDaySnapshot.forEach((doc) => {
          const classData = doc.data();
          const newSaturdayClassRef = scheduleRef.doc();
          transaction.set(newSaturdayClassRef, {
            ...classData,
            day: "Saturday",
          });
        });
      });
      allPromises.push(promise);
    });

    await Promise.all(allPromises);

    return {
      success: true,
      message: `Successfully set Saturday's schedule based on ${sourceDay} for ${allPromises.length} sections.`,
    };
  } catch (error) {
    functions.logger.error("Error setting Saturday schedule:", error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occurred while updating the schedules.",
      error,
    );
  }
});
