import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Логирование аналитики от iOS приложения
export const logAnalyticsEvent = functions.https.onCall(async (data, context) => {
  // Проверка App Check (требует настройки в Firebase Console)
  if (!context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check verification failed'
    );
  }

  const { eventType, categoryId, animalId, productId, timestamp } = data;
  
  if (!eventType) {
    throw new functions.https.HttpsError('invalid-argument', 'eventType is required');
  }

  const date = new Date(timestamp || Date.now());
  const dateStr = date.toISOString().split('T')[0].replace(/-/g, '');
  
  const batch = admin.firestore().batch();
  
  // Агрегация по категориям
  if (categoryId) {
    const categoryRef = admin.firestore()
      .collection('analytics')
      .doc('daily')
      .collection(dateStr)
      .doc(`categories_${categoryId}`);
    
    batch.set(categoryRef, {
      count: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  }
  
  // Агрегация по животным
  if (animalId) {
    const animalRef = admin.firestore()
      .collection('analytics')
      .doc('daily')
      .collection(dateStr)
      .doc(`animals_${animalId}`);
    
    batch.set(animalRef, {
      count: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  }
  
  // Агрегация по доходам
  if (productId && eventType === 'purchase_success') {
    const revenueRef = admin.firestore()
      .collection('analytics')
      .doc('daily')
      .collection(dateStr)
      .doc(`revenue_${productId}`);
    
    batch.set(revenueRef, {
      count: admin.firestore.FieldValue.increment(1),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  }
  
  await batch.commit();
  
  return { success: true };
});

// Выдача роли пользователю (только для админов)
export const setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const currentUser = await admin.auth().getUser(context.auth.uid);
  const currentRole = currentUser.customClaims?.role;
  
  if (currentRole !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can set roles');
  }
  
  const { uid, role } = data;
  
  if (!uid || !role) {
    throw new functions.https.HttpsError('invalid-argument', 'uid and role are required');
  }
  
  if (!['admin', 'editor'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
  }
  
  await admin.auth().setCustomUserClaims(uid, { role });
  
  return { success: true };
});
