# Estrutura Firestore para usuário premium

O exemplo abaixo mostra um documento completo no caminho `users/{uid}` com os mesmos campos do perfil e um plano premium ativo na subcoleção `billing/plan`. Substitua `UID_DO_USUARIO` pelo identificador real e ajuste os valores conforme necessário.

```json
{
  "users": {
    "UID_DO_USUARIO": {
      "displayName": "Leandro Campos",
      "email": "leandrogamer275@gmail.com",
      "emailVerified": true,
      "photoUrl": "https://lh3.googleusercontent.com/a/ACg8ocKtnZf5zKvR36_u_tJOGuxpV85pS96-c",
      "googleAccount": {
        "email": "leandrogamer275@gmail.com",
        "id": "1095529858227176722735"
      },
      "metadata": {
        "creationTime": "2025-10-17T01:53:03.828Z",
        "lastSignInTime": "2025-10-17T04:11:16.138Z",
        "phoneNumber": null
      },
      "preferences": {
        "allergies": null,
        "bio": null,
        "cookingGoals": null,
        "dietaryPreferences": [],
        "favoriteCuisines": ["Japonesa"]
      },
      "profile": {
        "completed": true,
        "completedAt": "2025-10-17T01:25:50.000Z",
        "providerId": "google.com",
        "updatedAt": "2025-10-17T01:25:50.000Z"
      },
      "_subcollections": {
        "billing": {
          "plan": {
            "type": "premium",
            "productId": "prod_ABC123",
            "priceId": "price_123",
            "transactionId": "in_1PTeste12345",
            "platform": "stripe",
            "status": "active",
            "subscriptionId": "sub_1PAssinaturaABC",
            "customerId": "cus_Nqwe123",
            "autoRenews": true,
            "cancelAtPeriodEnd": false,
            "amount": 2000,
            "currency": "BRL",
            "interval": "month",
            "expiresAt": {
              "_seconds": 1893456000,
              "_nanoseconds": 0
            },
            "createdAt": {
              "_seconds": 1734372000,
              "_nanoseconds": 0
            },
            "updatedAt": {
              "_seconds": 1734458400,
              "_nanoseconds": 0
            }
          }
        },
        "analytics": {},
        "favorites": {}
      }
    }
  }
}
```

- `_subcollections` indica que `billing`, `analytics` e `favorites` devem ser criadas como subcoleções reais do documento `users/{uid}`.
- `type` precisa ser `"premium"` para liberar o plano pago; altere para `"free"` ou apague o documento para voltar ao plano gratuito.
- `priceId`, `subscriptionId`, `status` e `customerId` são preenchidos automaticamente pelas Cloud Functions com os dados vindos do Stripe.
- `amount` representa o valor em centavos (2000 = R$ 20,00) e `currency` segue o padrão ISO (BRL, USD etc.).
- `expiresAt` indica o fim do ciclo atual; quando ausente, o plano é tratado como ativo até nova sincronização.
- Os campos `createdAt` e `updatedAt` ajudam a auditar quando o plano foi criado/sincronizado pela última vez.
