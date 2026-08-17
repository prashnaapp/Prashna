/**
 * Maps Google Play obfuscatedExternalAccountId → Firebase uid.
 *
 * Written during client verifyPlayPurchase so RTDN can resolve the user
 * without trusting client-supplied UIDs.
 *
 * Collection: play_account_links/{obfuscatedAccountId}
 */
import { FieldValue } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';

export function obfuscatedAccountIdForUid(uid) {
  const hex = createHash('sha256').update(String(uid).trim()).digest('hex');
  return hex.length <= 64 ? hex : hex.substring(0, 64);
}

export function playAccountLinkDoc(db, obfuscatedAccountId) {
  return db.collection('play_account_links').doc(obfuscatedAccountId);
}

export function createPlayAccountLinkStore(db) {
  return {
    async upsert(uid) {
      const obfuscatedAccountId = obfuscatedAccountIdForUid(uid);
      await playAccountLinkDoc(db, obfuscatedAccountId).set(
        {
          uid,
          obfuscatedAccountId,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return obfuscatedAccountId;
    },

    async resolveUid(obfuscatedAccountId) {
      const id = String(obfuscatedAccountId || '').trim();
      if (!id) return null;
      const snap = await playAccountLinkDoc(db, id).get();
      if (!snap.exists) return null;
      return snap.data()?.uid || null;
    },
  };
}
