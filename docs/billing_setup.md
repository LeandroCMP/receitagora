# ReceitaAgora Billing Setup

Este documento resume as etapas necessárias para ativar o fluxo de assinaturas com In-App Purchases e as funções do Firebase.

## 1. Configuração das lojas

### Google Play
1. Cadastre os produtos de assinatura (`premium_monthly` e `premium_annual`) na Google Play Console.
2. Publique os produtos (estado `Active`).
3. Baixe um JSON de credenciais de serviço com acesso ao *Google Play Android Developer API* e configure a conta de serviço para ter acesso ao app.
4. No Firebase CLI execute:
   ```bash
   firebase functions:config:set billing.android_package="com.seuapp.receitagora"
   ```

### Apple App Store
1. Crie os produtos de assinatura com os mesmos IDs (`premium_monthly` e `premium_annual`).
2. Gere a *App-Specific Shared Secret* e copie o valor.
3. No Firebase CLI execute:
   ```bash
   firebase functions:config:set billing.appstore_shared_secret="<shared-secret>"
   ```

## 2. Deploy das funções

1. Instale as dependências na pasta `functions/`:
   ```bash
   cd functions
   npm install
   npm run build
   ```
2. Faça o deploy:
   ```bash
   firebase deploy --only functions
   ```

## 3. Configurações no app

- Certifique-se de que o Firebase Functions e Firestore estão habilitados no app Flutter.
- Atualize o arquivo `.env` ou os secrets do backend com as chaves do Firebase.
- Publicar uma versão interna nas lojas para testar o fluxo end-to-end.

## 4. Testes manuais

- **Restaurar compras**: utilize a opção “Restaurar compras” na tela de paywall para testar o fluxo após reinstalação.
- **Validação automática**: ao concluir a compra, a função `billingVerifyPurchase` grava/atualiza o documento `users/{uid}/billing/plan` com as informações da assinatura.

Com esses passos o back-end e o front-end ficarão sincronizados garantindo que apenas usuários com assinaturas válidas desfrutem do plano Premium.
