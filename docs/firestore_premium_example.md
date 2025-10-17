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
            "productId": "premium_monthly",
            "transactionId": "manual-test",
            "platform": "manual",
            "autoRenews": false,
            "expiresAt": {
              "_seconds": 1893456000,
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
- `expiresAt` é opcional, mas, se informado, precisa apontar para uma data futura (o exemplo usa 1º de janeiro de 2030 UTC).
- Ajuste os demais campos para refletir os dados reais do usuário no seu ambiente.
