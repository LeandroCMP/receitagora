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
2. Edite o arquivo `.env` que acompanha o projeto e preencha com as suas
   credenciais da OpenAI:
   ```env
   OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx
   OPENAI_BASE_URL=https://api.openai.com/v1
   OPENAI_MODEL=gpt-4o-mini
   ```
   > **Importante:** substitua o valor padrão pela sua chave real antes de gerar
   > builds de produção. O arquivo está versionado para garantir que o asset
   > exista durante o empacotamento, mas você pode manter um arquivo separado
   > com as chaves reais fora do Git ao distribuir o projeto.

3. Execute o aplicativo:
   ```bash
   flutter run
   ```

> **Dica:** sem uma chave válida da OpenAI o aplicativo não consegue gerar
> receitas. Configure a credencial antes de buscar sugestões.

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

### Erros comuns

- **Sem chave configurada:** quando `OPENAI_API_KEY` está ausente, o app exibe
  uma mensagem informando que a geração depende da credencial e nenhuma receita
  é retornada até que a chave seja configurada corretamente.
- **Falhas com a OpenAI (HTTP 400/429):** as mensagens de erro são exibidas
  diretamente na interface para que você saiba o motivo da falha (ex.: limite
  de cota, formato incompatível ou URL incorreta). Corrija a configuração e
  tente novamente para receber respostas reais da OpenAI.
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
