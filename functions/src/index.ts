import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import axios from 'axios';
import { google } from 'googleapis';

type VerificationResult = {
  valid: boolean;
  expiresAt?: Date;
  autoRenews: boolean;
  transactionId?: string;
};

type VerifyPurchaseInput = {
  platform: string;
  productId: string;
  verificationData: string;
  transactionId?: string;
};

admin.initializeApp();

const db = admin.firestore();
const PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';

export const billingVerifyPurchase = functions
  .region('us-central1')
  .https.onCall(async (data: VerifyPurchaseInput, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Faça login para concluir a compra.',
      );
    }

    const platform = String(data.platform ?? '').toLowerCase();
    const productId = data.productId;
    const verificationData = data.verificationData;
    const transactionId = data.transactionId;

    if (!platform || !productId || !verificationData) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Dados de verificação incompletos.',
      );
    }

    let verification: VerificationResult;
    if (platform === 'android') {
      verification = await verifyAndroidPurchase(productId, verificationData);
    } else if (platform === 'ios' || platform === 'apple') {
      verification = await verifyApplePurchase(productId, verificationData);
    } else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Plataforma de compra desconhecida.',
      );
    }

    if (!verification.valid) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Não foi possível validar sua assinatura. Verifique com a loja do seu dispositivo.',
      );
    }

    const expiresAt = verification.expiresAt
      ? admin.firestore.Timestamp.fromDate(verification.expiresAt)
      : null;

    const planDoc = db
      .collection('users')
      .doc(context.auth.uid)
      .collection('billing')
      .doc('plan');

    await planDoc.set(
      {
        type: 'premium',
        productId,
        platform,
        transactionId: verification.transactionId ?? transactionId ?? null,
        autoRenews: verification.autoRenews,
        expiresAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      success: true,
      platform,
      autoRenews: verification.autoRenews,
      expiresAt: verification.expiresAt?.toISOString() ?? null,
    };
  });

async function verifyAndroidPurchase(
  productId: string,
  purchaseToken: string,
): Promise<VerificationResult> {
  const packageName = functions.config().billing?.android_package;
  if (!packageName) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Configuração da Play Store ausente (billing.android_package).',
    );
  }

  try {
    const auth = await google.auth.getClient({ scopes: [PLAY_SCOPE] });
    const publisher = google.androidpublisher({ version: 'v3', auth });
    const { data } = await publisher.purchases.subscriptions.get({
      packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    if (!data) {
      return { valid: false, autoRenews: false };
    }

    const expiryTimeMillis = data.expiryTimeMillis
      ? Number.parseInt(data.expiryTimeMillis, 10)
      : undefined;
    const expiresAt = expiryTimeMillis ? new Date(expiryTimeMillis) : undefined;
    const cancelReason = data.cancelReason ?? 0;
    const paymentState = data.paymentState ?? 0;
    const autoRenews = Boolean(data.autoRenewing);
    const orderId = data.orderId ?? purchaseToken;

    const paid = paymentState === 1 || paymentState === 2 || paymentState === 3;
    const active = !expiresAt || expiresAt.getTime() > Date.now();
    const valid = paid && active && cancelReason === 0;

    return {
      valid,
      expiresAt,
      autoRenews,
      transactionId: orderId,
    };
  } catch (error: any) {
    functions.logger.error('Erro ao validar compra Android', error);
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Não foi possível validar sua assinatura com a Google Play Store.',
    );
  }
}

async function verifyApplePurchase(
  productId: string,
  receiptData: string,
): Promise<VerificationResult> {
  const sharedSecret = functions.config().billing?.appstore_shared_secret;
  if (!sharedSecret) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Configuração da App Store ausente (billing.appstore_shared_secret).',
    );
  }

  const payload = {
    'receipt-data': receiptData,
    password: sharedSecret,
    'exclude-old-transactions': true,
  };

  const endpoints = [
    'https://buy.itunes.apple.com/verifyReceipt',
    'https://sandbox.itunes.apple.com/verifyReceipt',
  ];

  for (let index = 0; index < endpoints.length; index += 1) {
    const endpoint = endpoints[index];
    try {
      const response = await axios.post(endpoint, payload);
      const status = response.data?.status;

      if (status === 21007 && endpoint.includes('buy')) {
        continue; // retry against sandbox
      }

      if (status !== 0) {
        throw new Error(`Apple verification returned status ${status}`);
      }

      const latest: any[] = Array.isArray(response.data?.latest_receipt_info)
        ? response.data.latest_receipt_info
        : [];

      const matching = latest
        .filter((entry) => entry.product_id === productId)
        .sort((a, b) => {
          const aExpiry = Number.parseInt(a.expires_date_ms ?? '0', 10);
          const bExpiry = Number.parseInt(b.expires_date_ms ?? '0', 10);
          return bExpiry - aExpiry;
        });

      const transaction = matching[0] ?? latest[0];
      if (!transaction) {
        return { valid: false, autoRenews: false };
      }

      const expiresDateMs = transaction.expires_date_ms
        ? Number.parseInt(transaction.expires_date_ms, 10)
        : undefined;
      const expiresAt = expiresDateMs ? new Date(expiresDateMs) : undefined;
      const canceled = transaction.cancellation_date_ms != null;
      const active = !expiresAt || expiresAt.getTime() > Date.now();

      const renewals: any[] = Array.isArray(response.data?.pending_renewal_info)
        ? response.data.pending_renewal_info
        : [];
      const renewalEntry = renewals.find(
        (item) => item.product_id === productId,
      );
      const autoRenewsRaw = renewalEntry?.auto_renew_status;
      const autoRenews = autoRenewsRaw === '1' || autoRenewsRaw === 1;

      return {
        valid: active && !canceled,
        expiresAt,
        autoRenews,
        transactionId:
            transaction.original_transaction_id ?? transaction.transaction_id,
      };
    } catch (error: any) {
      const status = error?.response?.data?.status;
      if (status === 21007 && index === 0) {
        continue;
      }
      functions.logger.error('Erro ao validar compra Apple', error?.response?.data ?? error);
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Não foi possível validar sua assinatura com a App Store.',
      );
    }
  }

  return { valid: false, autoRenews: false };
}
