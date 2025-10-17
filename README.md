# Receitagora

Aplicativo Flutter que sugere receitas personalizadas a partir dos ingredientes
disponíveis. O projeto adota GetX e separação em camadas para manter o código
organizado, integra-se à API da OpenAI para gerar sugestões gastronômicas e usa
Firebase (Auth, Firestore e Storage) para persistir perfis, favoritos e limites
de uso dinâmicos.

A experiência visual combina tema claro vibrante inspirado em referências de
design gastronômico, telas com gradientes responsivos e animações suaves. Usuários
logados contam com onboarding de perfil (bio, preferências e objetivos), edição
completa de dados, favoritos com métricas e tags, histórico de receitas e
compartilhamento visual. Visitantes continuam navegando pelo app com limites
controlados automaticamente e feedback consistente em toda a interface.

## Configuração

1. Instale as dependências do Flutter listadas em `pubspec.yaml`:
   ```bash
   flutter pub get
   ```
2. (Opcional, mas recomendado) Configure o Firebase para cada plataforma:
   - **Android:** faça o download do `google-services.json` no [Console do Firebase](https://console.firebase.google.com/)
     e coloque o arquivo em `android/app/google-services.json`.
   - **iOS:** baixe o `GoogleService-Info.plist` e adicione ao runner em `ios/Runner/GoogleService-Info.plist`.
     Ambos os arquivos estão listados no `.gitignore` para evitar commits acidentais.
   - Caso utilize o FlutterFire CLI para gerar `firebase_options.dart`, basta importar
     o arquivo dentro de `FirebaseInitializer.ensureInitialized` para aplicar as
     opções explicitamente.
   - Quando os arquivos não estiverem presentes, o app iniciará normalmente e registrará
     no log que a configuração do Firebase está pendente, permitindo que você inclua os
     arquivos posteriormente sem travar o fluxo de execução.
3. Edite o arquivo `.env` que acompanha o projeto e preencha com as suas
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

4. Execute o aplicativo:
   ```bash
   flutter run
   ```

> **Dica:** sem uma chave válida da OpenAI o aplicativo não consegue gerar
> receitas. Configure a credencial antes de buscar sugestões.

### Fluxo de acesso e limites dinâmicos

- **Splash screen & onboarding:** ao abrir o app, a sessão é restaurada
  automaticamente. Caso o usuário esteja logado e ainda não tenha completado o
  perfil, o fluxo direciona para o preenchimento rápido de bio, preferências,
  objetivos e restrições alimentares (com opção de pular, mas sem ignorar a
  etapa).
- **Modo visitante:** por padrão permite até **2 buscas por dia**, devolvendo
  no máximo **2 receitas por consulta** e **50 compartilhamentos por sessão**.
  Esses limites são carregados dinamicamente do Firestore e reiniciados a cada
  novo dia.
- **Login com Google:** remove as restrições do modo visitante, habilita
  favoritos sincronizados, histórico de receitas, compartilhamento ilimitado e
  exibe o avatar no topo da tela principal.

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

### Resultado das receitas

- As consultas utilizam os ingredientes informados combinados com os dados de
  perfil (quando disponíveis) para gerar receitas alinhadas às preferências do
  usuário, indicando dificuldade, tempo médio e observações.
- O histórico local garante uma experiência resiliente: caso a API da OpenAI
  esteja indisponível, as últimas receitas válidas são reapresentadas e ficam
  acessíveis para consulta rápida.

## Estrutura do Projeto

- `lib/application`: configuração global (tema, rotas, bindings e utilitários de
  layout/feedback).
- `lib/models`: modelos de domínio como `UserModel`, compartilhados entre
  serviços e camadas de UI.
- `lib/modules`: módulos funcionais (splash, login, receita, favoritos, perfil),
  cada um com bindings, controllers, páginas e widgets alinhados ao padrão do
  projeto.
- `lib/services`: abstrações e implementações para autenticação, sessão,
  favoritos, histórico de receitas, OpenAI, compartilhamento e limites dinâmicos.
- `docs/ads_setup.md`: guia passo a passo para habilitar propagandas com AdMob
  mantendo a arquitetura do projeto alinhada ao padrão atual.

## Suporte

Em caso de dúvidas sobre a execução do projeto, consulte a documentação do
[Flutter](https://docs.flutter.dev/) e do [GetX](https://pub.dev/packages/get).
