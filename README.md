# Receitagora

Aplicativo Flutter para sugerir receitas com base nos ingredientes que o usuário
tem em casa. A solução utiliza GetX, Clean Architecture e integra-se com a API
da OpenAI para gerar até três receitas possíveis seguindo as restrições
informadas.

## Configuração

1. Instale as dependências do Flutter listadas em `pubspec.yaml`:
   ```bash
   flutter pub get
   ```
2. Crie um arquivo `.env` na raiz do projeto, utilizando o template disponibilizado
   em `.env.example`:
   ```bash
   cp .env.example .env
   ```
3. Edite o arquivo `.env` e preencha com as suas credenciais da OpenAI:
   ```env
   OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx
   OPENAI_BASE_URL=https://api.openai.com/v1
   OPENAI_MODEL=gpt-4o-mini
   ```
   > **Importante:** mantenha suas chaves privadas fora do controle de versão. O
   > arquivo `.env` já está ignorado pelo Git.

4. Execute o aplicativo:
   ```bash
   flutter run
   ```

> **Atenção:** a geração das receitas depende de credenciais válidas da OpenAI.
> Sem a configuração da chave a aplicação exibirá um alerta informando que não
> foi possível se conectar ao ChatGPT.

### Erros comuns

- **HTTP 429 ao gerar receitas:** pode indicar tanto excesso de requisições em
  um curto período quanto falta de créditos ou limite de faturamento alcançado
  na conta da OpenAI. A aplicação exibirá mensagens diferentes para cada
  situação. Caso o problema seja de cota, verifique o painel de billing da
  OpenAI. Para rate limits temporários, aguarde alguns instantes e tente
  novamente.

## Estrutura do Projeto

- `lib/core`: configurações, serviços e tratamento de erros compartilhados.
- `lib/modules/recipe_finder`: módulo principal com camadas de domínio,
  dados e apresentação seguindo Clean Architecture.
- `lib/app`: inicialização do GetX, rotas e tema visual.

## Suporte

Em caso de dúvidas sobre a execução do projeto, consulte a documentação do
[Flutter](https://docs.flutter.dev/) e do [GetX](https://pub.dev/packages/get).
