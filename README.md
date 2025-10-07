# Receitagora

Aplicativo Flutter para sugerir receitas com base nos ingredientes que o usuário
tem em casa. A solução utiliza GetX, Clean Architecture e integra-se com a API
da OpenAI para gerar receitas possíveis seguindo as restrições informadas.
A experiência agora conta com splash screen animada, tela de boas-vindas e um
modo visitante elegante em tema escuro. O botão de login com Google já aparece
na interface e será habilitado em uma versão futura.

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

> **Dica:** mesmo sem acesso à OpenAI o aplicativo continua funcionando graças
> a um gerador local de receitas. Ainda assim, configurar uma chave válida
> garante resultados mais criativos produzidos pela IA.

### Fluxo de acesso e limites do modo visitante

- **Splash screen & login:** ao abrir o app você verá uma tela de introdução e,
  em seguida, a tela de autenticação com duas opções — o login social com Google
  (em breve) ou o modo visitante.
- **Modo visitante:** permite até **3 buscas por dia**, com retorno máximo de
  **2 receitas por pesquisa**. O contador é reiniciado diariamente de forma
  automática.
- **Login com Google (em breve):** assim que habilitado, removerá os limites de
  busca, preservará o histórico de sessão e exibirá o avatar do usuário na tela
  principal.

### Erros comuns e fallback

- **Sem chave ou falha de rede:** o app automaticamente gera receitas locais
  com base nos ingredientes informados. A experiência continua fluindo, mas
  vale revisar a configuração para aproveitar as sugestões da OpenAI quando
  estiver disponível.
- **HTTP 429 ao gerar receitas:** indica excesso de requisições em um curto
  período ou falta de créditos/limite de faturamento. As respostas da IA são
  tentadas com repetição exponencial; caso o limite persista o app alterna para
  receitas locais para que você não fique sem sugestões.
- **HTTP 400** com mensagem sobre `response_format`: o modelo configurado não
  suporta o modo JSON. Ajuste a variável `OPENAI_MODEL` para um modelo
  compatível, como `gpt-4o-mini`.
- **HTTP 400** com indicação de URL inválida: verifique se `OPENAI_BASE_URL`
  aponta para o endpoint correto (`https://api.openai.com/v1`).
- **HTTP 400** informando limite de contexto: reduza a quantidade de
  ingredientes enviada no pedido para caber no limite de tokens do modelo.

## Estrutura do Projeto

- `lib/core`: configurações, serviços e tratamento de erros compartilhados.
- `lib/modules/auth`: telas, bindings e controladores do login social e modo
  visitante.
- `lib/modules/splash`: controlador e tela da splash screen animada.
- `lib/modules/recipe_finder`: módulo principal com camadas de domínio,
  dados e apresentação seguindo Clean Architecture.
- `lib/app`: inicialização do GetX, rotas e tema visual.

## Suporte

Em caso de dúvidas sobre a execução do projeto, consulte a documentação do
[Flutter](https://docs.flutter.dev/) e do [GetX](https://pub.dev/packages/get).
