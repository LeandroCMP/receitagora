import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import Stripe from 'stripe';

admin.initializeApp();

const db = admin.firestore();
const REGION = 'us-central1';
const STRIPE_API_VERSION: Stripe.LatestApiVersion = '2023-10-16';

let stripeClient: Stripe | null = null;

function getStripe(): Stripe {
  if (stripeClient) {
    return stripeClient;
  }

  const secret = functions.config().stripe?.secret_key as string | undefined;
  if (!secret) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Stripe secret key is not configured. Execute `firebase functions:config:set stripe.secret_key=...`.'
    );
  }

  stripeClient = new Stripe(secret, { apiVersion: STRIPE_API_VERSION });
  return stripeClient;
}

function getPublishableKey(): string {
  const publishableKey = functions.config().stripe?.publishable_key as string | undefined;
  if (!publishableKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Stripe publishable key is not configured. Execute `firebase functions:config:set stripe.publishable_key=...`.'
    );
  }
  return publishableKey;
}

function requireAuth(context: functions.https.CallableContext): string {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Você precisa estar autenticado para gerenciar assinaturas.'
    );
  }
  return context.auth.uid;
}

interface PlanDefinition {
  id: string;
  name: string;
  description: string;
  priceConfigKey: string;
  intervalHint: string;
  highlighted: boolean;
}

const configuredPlans: PlanDefinition[] = [
  {
    id: 'premium_monthly',
    name: 'Premium mensal',
    description:
      'Renovação automática a cada mês com acesso ilimitado a receitas, compartilhamentos e histórico estendido.',
    priceConfigKey: 'price_monthly',
    intervalHint: 'month',
    highlighted: true,
  },
  {
    id: 'premium_annual',
    name: 'Premium anual',
    description: 'Economize dois meses garantindo acesso ilimitado durante todo o ano.',
    priceConfigKey: 'price_annual',
    intervalHint: 'year',
    highlighted: false,
  },
];

async function resolvePlanConfigs() {
  const planConfigs = functions.config().stripe ?? {};
  const stripe = getStripe();

  const plans = [] as Array<Record<string, unknown>>;

  for (const definition of configuredPlans) {
    const priceId = planConfigs[definition.priceConfigKey] as string | undefined;
    if (!priceId) {
      continue;
    }

    try {
      const price = await stripe.prices.retrieve(priceId);
      if (!price.unit_amount || !price.currency || !price.recurring) {
        continue;
      }

      plans.push({
        id: definition.id,
        name: definition.name,
        description: definition.description,
        priceId,
        interval: price.recurring.interval ?? definition.intervalHint,
        amount: price.unit_amount,
        currency: price.currency.toUpperCase(),
        highlighted: definition.highlighted,
      });
    } catch (error) {
      functions.logger.error('Failed to retrieve price', priceId, error);
      continue;
    }
  }

  if (plans.length === 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Nenhum plano de assinatura está configurado no Stripe.'
    );
  }

  return plans;
}

async function getOrCreateCustomer(uid: string, context: functions.https.CallableContext) {
  const stripe = getStripe();
  const docRef = db.collection('users').doc(uid).collection('billing').doc('stripe');
  const snapshot = await docRef.get();
  if (snapshot.exists) {
    const data = snapshot.data();
    if (data && data.customerId) {
      await docRef.set(
        { updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
      return data.customerId as string;
    }
  }

  const customer = await stripe.customers.create({
    email: context.auth?.token?.email ?? undefined,
    name: context.auth?.token?.name ?? undefined,
    metadata: {
      uid,
    },
  });

  await docRef.set(
    {
      customerId: customer.id,
      email: customer.email ?? null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return customer.id;
}

async function syncSubscriptionWithFirestore(uid: string, subscription: Stripe.Subscription | null) {
  const planRef = db.collection('users').doc(uid).collection('billing').doc('plan');

  if (!subscription) {
    await planRef.delete().catch(() => undefined);
    return;
  }

  const premiumStatuses = new Set(['trialing', 'active', 'past_due', 'unpaid']);
  if (!premiumStatuses.has(subscription.status)) {
    await planRef.delete().catch(() => undefined);
    return;
  }

  const price = subscription.items.data[0]?.price ?? null;
  const amount = price?.unit_amount ?? null;
  const currency = price?.currency?.toUpperCase() ?? null;
  const interval = price?.recurring?.interval ?? null;
  const customerId =
    typeof subscription.customer === 'string'
      ? subscription.customer
      : subscription.customer?.id ?? null;

  const payload: Record<string, unknown> = {
    type: 'premium',
    platform: 'stripe',
    status: subscription.status,
    productId: price?.product ?? null,
    priceId: price?.id ?? null,
    amount,
    currency,
    interval,
    subscriptionId: subscription.id,
    transactionId: subscription.latest_invoice ?? null,
    autoRenews: !subscription.cancel_at_period_end,
    cancelAtPeriodEnd: subscription.cancel_at_period_end ?? false,
    expiresAt: subscription.current_period_end
      ? admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000)
      : null,
    customerId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const existing = await planRef.get();
  if (!existing.exists) {
    payload.createdAt = admin.firestore.FieldValue.serverTimestamp();
  }

  await planRef.set(payload, { merge: true });
}

export const billingListPlans = functions
  .region(REGION)
  .https.onCall(async (_data, _context) => {
    const plans = await resolvePlanConfigs();
    return {
      publishableKey: getPublishableKey(),
      plans,
    };
  });

export const billingCreateSubscriptionSession = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const priceId = typeof data?.priceId === 'string' ? data.priceId.trim() : '';
    if (!priceId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Informe o identificador do plano desejado.'
      );
    }

    const plans = await resolvePlanConfigs();
    const plan = plans.find((item) => item['priceId'] === priceId);
    if (!plan) {
      throw new functions.https.HttpsError(
        'not-found',
        'Plano selecionado não está disponível no momento.'
      );
    }

    const stripe = getStripe();
    const customerId = await getOrCreateCustomer(uid, context);

    try {
      const subscription = await stripe.subscriptions.create({
        customer: customerId,
        items: [{ price: priceId }],
        payment_behavior: 'default_incomplete',
        payment_settings: {
          save_default_payment_method: 'on_subscription',
          payment_method_types: ['card'],
        },
        metadata: {
          uid,
          plan_id: plan['id'] as string,
        },
        expand: ['latest_invoice.payment_intent'],
      });

      const latestInvoice = subscription.latest_invoice as Stripe.Invoice | null;
      const paymentIntent = latestInvoice?.payment_intent as Stripe.PaymentIntent | null;
      if (!paymentIntent?.client_secret) {
        throw new functions.https.HttpsError(
          'internal',
          'Não foi possível criar a cobrança neste momento. Tente novamente mais tarde.'
        );
      }

      const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer: customerId },
        { apiVersion: STRIPE_API_VERSION }
      );

      if (!ephemeralKey.secret) {
        throw new functions.https.HttpsError(
          'internal',
          'Não foi possível autorizar o pagamento com o Stripe. Tente novamente.'
        );
      }

      return {
        publishableKey: getPublishableKey(),
        customerId,
        ephemeralKey: ephemeralKey.secret,
        paymentIntentClientSecret: paymentIntent.client_secret,
        subscriptionId: subscription.id,
        merchantDisplayName: 'Receita Agora',
      };
    } catch (error) {
      functions.logger.error('Failed to create subscription session', error);
      throw new functions.https.HttpsError(
        'internal',
        'Não foi possível iniciar a assinatura. Verifique seus dados e tente novamente.'
      );
    }
  });

export const billingFinalizeSubscription = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const subscriptionId = typeof data?.subscriptionId === 'string' ? data.subscriptionId : null;
    if (!subscriptionId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Assinatura inválida.'
      );
    }

    try {
      const stripe = getStripe();
      const subscription = await stripe.subscriptions.retrieve(subscriptionId, {
        expand: ['latest_invoice.payment_intent'],
      });

      if (subscription.metadata?.uid && subscription.metadata.uid !== uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Esta assinatura não pertence ao seu usuário.'
        );
      }

      await syncSubscriptionWithFirestore(uid, subscription);
      return { status: subscription.status };
    } catch (error) {
      functions.logger.error('Failed to finalize subscription', subscriptionId, error);
      throw new functions.https.HttpsError(
        'internal',
        'Não foi possível atualizar o status da assinatura. Ela será sincronizada automaticamente em instantes.'
      );
    }
  });

export const billingCancelSubscription = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const subscriptionId = typeof data?.subscriptionId === 'string' ? data.subscriptionId : null;
    if (!subscriptionId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Assinatura inválida.'
      );
    }

    const stripe = getStripe();
    try {
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      if (subscription.metadata?.uid && subscription.metadata.uid !== uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Esta assinatura não pertence ao seu usuário.'
        );
      }

      const updated = await stripe.subscriptions.update(
        subscriptionId,
        {
          cancel_at_period_end: true,
        },
        {
          expand: ['latest_invoice.payment_intent'],
        }
      );

      await syncSubscriptionWithFirestore(uid, updated);
      return { status: updated.status };
    } catch (error) {
      functions.logger.error('Failed to cancel subscription', subscriptionId, error);
      throw new functions.https.HttpsError(
        'internal',
        'Não foi possível solicitar o cancelamento agora. Tente novamente em instantes.'
      );
    }
  });

export const billingCreatePortalSession = functions
  .region(REGION)
  .https.onCall(async (_data, context) => {
    const uid = requireAuth(context);
    const customerId = await getOrCreateCustomer(uid, context);
    const portalReturnUrl =
      (functions.config().stripe?.portal_return_url as string | undefined) ?? 'https://receitagora.app';

    const stripe = getStripe();
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: portalReturnUrl,
    });

    return {
      url: session.url,
      expiresAt: session.expires_at ?? null,
    };
  });

export const billingWebhook = functions
  .region(REGION)
  .https.onRequest(async (req, res) => {
    const signature = req.headers['stripe-signature'];
    const webhookSecret = functions.config().stripe?.webhook_secret as string | undefined;

    if (!signature || !webhookSecret) {
      res.status(400).send('Missing Stripe webhook configuration.');
      return;
    }

    let event: Stripe.Event;
    try {
      event = getStripe().webhooks.constructEvent(req.rawBody, signature, webhookSecret);
    } catch (error) {
      functions.logger.error('Webhook signature verification failed', error);
      res.status(400).send(`Webhook Error: ${(error as Error).message}`);
      return;
    }

    try {
      switch (event.type) {
        case 'customer.subscription.created':
        case 'customer.subscription.updated':
        case 'customer.subscription.deleted': {
          const subscription = event.data.object as Stripe.Subscription;
          const uid = subscription.metadata?.uid;
          if (uid) {
            await syncSubscriptionWithFirestore(uid, subscription);
          }
          break;
        }
        case 'invoice.payment_succeeded':
        case 'invoice.payment_failed': {
          const invoice = event.data.object as Stripe.Invoice;
          if (invoice.subscription) {
            const subscription = await getStripe().subscriptions.retrieve(
              typeof invoice.subscription === 'string' ? invoice.subscription : invoice.subscription.id,
              { expand: ['latest_invoice.payment_intent'] }
            );
            const uid = subscription.metadata?.uid;
            if (uid) {
              await syncSubscriptionWithFirestore(uid, subscription);
            }
          }
          break;
        }
        default:
          break;
      }
    } catch (error) {
      functions.logger.error('Failed to handle webhook event', event.type, error);
      res.status(500).send('Internal error handling webhook.');
      return;
    }

    res.json({ received: true });
  });
