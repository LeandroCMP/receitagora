# Configuração do Stripe para o ReceitaAgora

Este guia resume todas as etapas necessárias para ativar o fluxo de assinaturas premium usando Stripe, cobrindo consoles das lojas, variáveis das Cloud Functions e webhooks.

## 1. Criação dos produtos e preços no Stripe

1. Acesse o [Stripe Dashboard](https://dashboard.stripe.com) e crie um **produto** chamado `Receita Agora Premium`.
2. Adicione dois **preços recorrentes**:
   - **Mensal** (`premium_monthly`): R$ 20,00 cobrados a cada mês.
   - **Anual** (`premium_annual`): valor correspondente a 12 meses (ex.: R$ 200,00) cobrados uma vez ao ano.
3. Anote os identificadores dos preços (`price_xxx`). Eles serão usados nas configurações das funções.

## 2. Variáveis de ambiente das Cloud Functions

No diretório do projeto, execute os comandos abaixo substituindo pelos valores reais obtidos no Stripe:

```
firebase functions:config:set \
  stripe.secret_key="sk_live_..." \
  stripe.publishable_key="pk_live_..." \
  stripe.price_monthly="price_xxx" \
  stripe.price_annual="price_yyy" \
  stripe.webhook_secret="whsec_..." \
  stripe.portal_return_url="https://seu-dominio.com/conta"
```

- `stripe.secret_key` e `stripe.publishable_key` são, respectivamente, as chaves secreta e publicável da sua conta Stripe.
- `stripe.price_monthly` e `stripe.price_annual` apontam para os preços criados na etapa anterior.
- `stripe.webhook_secret` é o segredo gerado ao configurar o endpoint webhook (ver próximo tópico).
- `stripe.portal_return_url` define para onde o usuário será redirecionado ao sair do portal de assinaturas.

Depois de definir as variáveis, publique as funções:

```
cd functions
npm install
npm run build
firebase deploy --only functions
```

## 3. Webhook do Stripe

1. Em Developers > Webhooks no dashboard do Stripe, crie um endpoint apontando para:
   `https://us-central1-SEU_PROJETO.cloudfunctions.net/billingWebhook`
2. Selecione, no mínimo, os eventos:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
3. Copie o Signing secret (`whsec_...`) e atribua ao `stripe.webhook_secret` conforme mostrado na etapa anterior.

O webhook é responsável por manter o documento `users/{uid}/billing/plan` sincronizado, atualizando status, valores e datas de expiração.

## 4. Configurações no aplicativo Flutter

1. Execute `flutter pub get` após atualizar o `pubspec.yaml` com as dependências (`flutter_stripe`, `cloud_functions`, `url_launcher`, etc.).
   - No `android/app/build.gradle.kts`, garanta a presença de `implementation("com.stripe:stripe-android-issuing-push-provisioning:1.1.0")` para evitar erros do R8 ao compilar a versão de release.
2. No painel do Firebase Console, habilite Cloud Functions e Firestore.
3. Distribua um build interno (TestFlight/Google Play Internal Testing) para validar a cobrança usando contas de teste.
4. Garanta que o arquivo `.env` ou demais configurações locais contenham as chaves do Firebase correspondentes ao mesmo projeto usado pelas funções.

## 5. Testes recomendados

- **Assinatura nova:** realize a compra no ambiente de testes e confirme se o documento `billing/plan` é criado com `status: active` e `type: premium`.
- **Cancelamento:** acione o botão “Cancelar assinatura” no aplicativo e verifique se `cancelAtPeriodEnd` passa a ser `true` e o portal reflete a próxima data de expiração.
- **Falha de pagamento:** force um pagamento inválido (cartão de teste `4000 0000 0000 0341`) e observe se o webhook atualiza o status para `payment_pending`/`unpaid`.
- **Portal do cliente:** abra o portal via app, atualize método de pagamento e confirme se os dados são sincronizados após a alteração.

Seguindo estas etapas, o fluxo de cobrança Stripe ficará totalmente operacional para o ReceitaAgora, com sincronização em tempo real entre o backend e o aplicativo Flutter.
