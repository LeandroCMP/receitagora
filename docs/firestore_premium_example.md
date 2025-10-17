# Exemplo de documento Firestore para usuário premium

Para liberar manualmente o plano premium de um usuário, crie/edite o documento em `users/{uid}/billing/plan` com o seguinte conteúdo JSON:

```json
{
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
```

> `expiresAt` representa 1º de janeiro de 2030 00:00:00 UTC (Timestamp futuro). Ajuste conforme necessário ou remova o campo para um acesso sem expiração.
