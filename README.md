# Receitagora

Receitagora é um aplicativo Flutter que ajuda o usuário a planejar sua rotina alimentar completa: da descoberta de receitas alinhadas às preferências pessoais até o acompanhamento de bem-estar, listas de compras inteligentes e curadoria de restaurantes próximos. O projeto foi construído com foco em experiências guiadas por IA, navegação fluida com GetX e integração com serviços externos (OpenAI, Firebase e Google Places), mantendo persistência local para garantir uso offline resiliente.

## Sumário
- [Visão geral rápida](#visão-geral-rápida)
- [Tecnologias principais](#tecnologias-principais)
- [Arquitetura e padrões adotados](#arquitetura-e-padrões-adotados)
- [Preparação do ambiente](#preparação-do-ambiente)
  - [Pré-requisitos](#pré-requisitos)
  - [Configuração passo a passo](#configuração-passo-a-passo)
  - [Integrações opcionais](#integrações-opcionais)
- [Execução, build e qualidade](#execução-build-e-qualidade)
- [Funcionalidades em detalhes](#funcionalidades-em-detalhes)
  - [Autenticação e gestão de sessão](#1-autenticação-e-gestão-de-sessão)
  - [Busca de receitas assistida por IA](#2-busca-de-receitas-assistida-por-ia)
  - [Histórico, favoritos e cadernos colaborativos](#3-histórico-favoritos-e-cadernos-colaborativos)
  - [Planos nutricionais personalizados](#4-planos-nutricionais-personalizados)
  - [Laboratório de ingredientes](#5-laboratório-de-ingredientes)
  - [Listas de compras inteligentes](#6-listas-de-compras-inteligentes)
  - [Rotinas de bem-estar e lembretes](#7-rotinas-de-bem-estar-e-lembretes)
  - [Diário emocional](#8-diário-emocional)
  - [Trilhas de habilidades culinárias](#9-trilhas-de-habilidades-culinárias)
  - [Descoberta de restaurantes com Google Places](#10-descoberta-de-restaurantes-com-google-places)
- [Serviços auxiliares e infraestrutura](#serviços-auxiliares-e-infraestrutura)
- [Estilo visual e componentes reutilizáveis](#estilo-visual-e-componentes-reutilizáveis)
- [Boas práticas, monitoramento e próximas evoluções](#boas-práticas-monitoramento-e-próximas-evoluções)

## Visão geral rápida
- **Plataformas suportadas:** Android, iOS, Web e desktop (macOS, Windows, Linux). As permissões e manifestos específicos de cada plataforma já estão preparados para notificações locais, geolocalização e Firebase.
- **Público-alvo:** pessoas que desejam planejar refeições e hábitos saudáveis sem depender de diversas ferramentas isoladas.
- **Experiência do usuário:** onboarding guiado, modo visitante com limites automáticos, cards contextuais no perfil, widgets reutilizáveis e fluxos curtos focados em ações práticas (gerar receitas, salvar favoritos, montar listas, registrar humor etc.).
- **Confiabilidade:** combina armazenamento local (`SharedPreferences`), sincronização com Firestore para dados do usuário e consultas em tempo real a APIs externas (OpenAI e Google Places). Serviços críticos como notificações e uso do app contam com mecanismos de retry e hidratação automática do cache.

## Tecnologias principais
| Camada | Biblioteca/Serviço | Uso principal |
| --- | --- | --- |
| UI e navegação | Flutter 3.27+, Material 3, Google Fonts | Criação de interfaces responsivas, animações e tema consistente em todas as telas |
| Gerência de estado | GetX (`get`) | Injeção de dependências, roteamento declarativo, controllers reativos e bindings por módulo |
| Inteligência Artificial | OpenAI (via `http` + `flutter_dotenv`) | Geração de receitas, planos nutricionais e relatórios do laboratório de ingredientes utilizando prompts estruturados |
| Persistência remota | Firebase Auth, Cloud Firestore, Cloud Functions, Firebase Core | Autenticação social, limites dinâmicos, armazenamento de planos e preferências de usuário |
| Pagamentos | Flutter Stripe | Experiência de checkout para planos premium e sincronização com limites avançados |
| Notificações locais | `flutter_local_notifications`, `timezone` | Agendamento de lembretes (bem-estar, testes de notificações, rotinas) com suporte a fuso horário |
| Persistência local | `shared_preferences`, cache interno GetX | Armazenamento offline de listas de compras, histórico de uso, diário emocional e preferências |
| Geolocalização | `geolocator` + Google Places/Geocoding | Obtenção da posição atual e descoberta de restaurantes próximos via API oficial do Google |
| Internacionalização | `intl` | Formatação de datas, números e textos sensíveis a locale |
| Outras integrações | `share_plus`, `url_launcher`, `collection` | Compartilhamento social, abertura de links externos e utilidades para manipulação de coleções |

## Arquitetura e padrões adotados
- **Modularização por funcionalidade:** cada diretório em `lib/modules` agrupa bindings, controllers, páginas e widgets de um fluxo específico (ex.: `recipe_finder`, `shopping_list`, `restaurant_discovery`). Os módulos são registrados em `lib/application/routes/app_pages.dart`, permitindo lazy loading com GetX.
- **Serviços desacoplados:** contratos ficam em `lib/services/<domínio>/` com implementações em arquivos `*_impl.dart`. Isso facilita troca de provedores (ex.: migrar da API do Google para outra fonte) e simplifica testes unitários.
- **Modelos imutáveis:** entidades (`lib/models`) usam `const` + coleções não modificáveis quando possível. Conversões `fromMap`/`toMap` garantem compatibilidade com Firestore e APIs HTTP.
- **Tratamento de erros consistente:** exceções personalizadas (`AppException`) produzem feedback padronizado via `AppSnackbar`. Controllers exibem estados reativos (`isLoading`, `errorMessage`) enquanto serviços encapsulam lógica de fallback.
- **Resiliência offline:** caches locais são atualizados após operações remotas e reidratados no bootstrap do app (`lib/main.dart`). Serviços como `AppUsageServiceImpl` e `MoodJournalServiceImpl` reconstroem `Completer`s ao detectar falhas, evitando deadlocks.
- **Observadores globais:** `AppLifecycleService` monitora transições de foreground/background para cancelar notificações de teste, recontar uso real e disparar eventos contextuais.

## Preparação do ambiente
### Pré-requisitos
1. Flutter SDK 3.27.0 ou superior (`flutter --version`).
2. Dart 3.2.0 ou superior (já incluso no SDK do Flutter).
3. Xcode (para builds iOS) e Android Studio/SDK (para builds Android).
4. Conta na OpenAI e chave de API válida.
5. (Opcional) Projeto no Firebase com Auth, Firestore e Cloud Functions.
6. (Opcional) Chave da Google Places API com acesso a `places` e `geocoding`.

### Configuração passo a passo
1. **Clonar o repositório e instalar dependências**
   ```bash
   git clone https://github.com/<sua-conta>/receitagora.git
   cd receitagora
   flutter pub get
   ```
2. **Configurar variáveis de ambiente da OpenAI**
   - Edite o arquivo `.env` na raiz do projeto com as suas credenciais reais:
     ```env
     OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx
     OPENAI_BASE_URL=https://api.openai.com/v1
     OPENAI_MODEL=gpt-4o-mini
     ```
   - Sem uma chave válida, os fluxos de receitas, plano nutricional e laboratório exibem mensagens informando a pendência.
3. **Inicializar Firebase (opcional, mas recomendado)**
   - Baixe o `google-services.json` (Android) e o `GoogleService-Info.plist` (iOS) no console do Firebase e coloque em `android/app/` e `ios/Runner/` respectivamente.
   - Caso utilize o FlutterFire CLI, importe o arquivo `firebase_options.dart` dentro de `FirebaseInitializer.ensureInitialized()`.
   - Com Firebase configurado, o app sincroniza perfis, limites, planos nutricionais e histórico multi-dispositivo.
4. **Configurar Google Places para restaurantes (obrigatório para a nova tela)**
   - Crie uma API key no [Google Cloud Console](https://console.cloud.google.com/).
   - Garanta que as APIs **Places API** e **Geocoding API** estejam habilitadas.
   - Defina a chave no `.env`:
     ```env
     GOOGLE_PLACES_API_KEY=AIzaSy...
     ```
   - Sem a chave, a tela de restaurantes exibe uma instrução clara para completar a configuração.
5. **Sincronizar notificações locais**
   - No Android 13+, aceite a permissão `POST_NOTIFICATIONS` adicionada no manifesto.
   - No iOS, a permissão é solicitada na primeira inicialização do `LocalNotificationService`.
6. **Executar o aplicativo**
   ```bash
   flutter run
   ```
   - O bootstrap (`lib/main.dart`) carrega dotenv, inicializa Firebase, hidrata caches (uso do app, listas de compras, diário) e agenda notificações de teste.

### Integrações opcionais
- **Stripe (assinaturas Premium):** configure as chaves públicas/secretas em Functions e ajuste o módulo `lib/modules/billing/` conforme o backend disponível.
- **Cloud Functions personalizadas:** o app já referencia limites dinâmicos e geração de convites. Ajuste `functions/` para refletir sua lógica ou desabilite chamando serviços simulados.
- **Serviços de clima ou sensores externos:** rotinas de bem-estar aceitam extensões para aumentar a inteligência dos lembretes (por exemplo, ajustar hidratação conforme temperatura). Basta estender `WellnessRoutineService`.

## Execução, build e qualidade
- **Desenvolvimento local:** `flutter run` (mobile/web) ou `flutter run -d chrome` (web) com hot reload habilitado.
- **Build de release:**
  ```bash
  flutter build apk --release
  flutter build ios --release
  ```
  Certifique-se de definir variáveis de ambiente sensíveis em tempo de build ou utilizar o `--dart-define` para sobrescrever valores do `.env` quando necessário.
- **Análise estática:** `flutter analyze` mantém o padrão de código definido em `analysis_options.yaml`.
- **Formatação:** `dart format lib` garante consistência de estilo.
- **Testes unitários:** utilize `flutter test`. Camadas de serviço e controllers foram organizadas para permitir mocks de APIs externas.

## Funcionalidades em detalhes
### 1. Autenticação e gestão de sessão
- **Onde está no código:** `lib/modules/login/`, `lib/services/session/`.
- **Como funciona:** usuários podem navegar em modo visitante (com limites dinâmicos) ou autenticar-se via Google para liberar histórico, favoritos e plano nutricional. O splash (`lib/modules/splash/`) restaura a sessão automaticamente e direciona para o fluxo adequado.
- **Detalhes técnicos:** `SessionService` monitora o modo atual, streams de limites e notificações de mudanças de plano Premium. Limites de convidado (buscas/dia, receitas por busca, compartilhamentos) são carregados do Firestore e atualizados em tempo real.

### 2. Busca de receitas assistida por IA
- **Onde está no código:** `lib/modules/recipe_finder/`, `lib/services/recipe/recipe_history_service_impl.dart`, `lib/services/openai/`.
- **Uso pelo usuário:** o usuário adiciona ingredientes, ajusta filtros e dispara a busca. Em modo convidado, limites visíveis informam quantas buscas restam. Os resultados exibem tempo de preparo, nível de dificuldade e observações personalizadas.
- **Implementação técnica:**
  - `GenerateRecipesUseCase` envia prompts estruturados para o modelo definido no `.env`.
  - Respostas são convertidas em `RecipeEntity` e persistidas no histórico local com chave baseada nos ingredientes.
  - Em caso de falha da OpenAI, o controller reutiliza o cache recente para não interromper o fluxo.

### 3. Histórico, favoritos e cadernos colaborativos
- **Onde está no código:** `lib/modules/recipe_history/`, `lib/modules/favorites/`, `lib/modules/favorites_notebooks/`, `lib/services/recipe/notebooks/`.
- **Uso pelo usuário:**
  - O histórico mostra buscas anteriores com filtros por data e permite reabrir combinações imediatamente.
  - Favoritos exibem métricas de engajamento, tags e botões de compartilhamento.
  - Cadernos colaborativos possibilitam agrupar favoritos, convidar amigos, registrar comentários e organizar coleções temáticas.
- **Implementação técnica:**
  - Histórico e cadernos utilizam `SharedPreferences` para cache local e Firestore para sincronização entre dispositivos autenticados.
  - Controllers aplicam paginação reativa e ordenação por uso recente.
  - O compartilhamento usa `share_plus` para gerar mensagens com resumo da receita e links.

### 4. Planos nutricionais personalizados
- **Onde está no código:** `lib/modules/nutrition_plan/`, `lib/services/nutrition/nutrition_plan_service.dart`, `lib/models/nutrition/`.
- **Uso pelo usuário:** após completar o perfil alimentar (objetivo, restrições, rotina), o app gera cardápios semanais com metas de macro e micronutrientes. O usuário pode registrar pesagens, marcar refeições concluídas e solicitar ajustes (variedade, progresso, ajustes automáticos).
- **Implementação técnica:**
  - Apenas assinantes Premium podem gerar ou regenerar planos. A validação ocorre no serviço de sessão.
  - Os prompts enviados à OpenAI incluem o histórico de peso, objetivo (perda, manutenção, ganho) e instruções adicionais para evitar termos bloqueados.
  - O resultado (`NutritionPlan`) é salvo em Firestore, com streams (`watchCurrentPlan`) atualizando a UI instantaneamente.
  - A tela oferece check-ins periódicos e integração com lista de compras derivada do plano.

### 5. Laboratório de ingredientes
- **Onde está no código:** `lib/modules/ingredient_lab/`, `lib/models/ingredient_lab/`.
- **Uso pelo usuário:** o laboratório solicita briefing completo (ingrediente alvo, contexto, objetivo, restrições) e retorna substituições viáveis, alertas de alergia, ajustes de preparo e mini lista de compras.
- **Implementação técnica:**
  - O controller monta prompts ricos em contexto e reutiliza restrições do perfil ativo.
  - O relatório (`IngredientLabReport`) é renderizado em seções de cards com dicas, substituições e observações.
  - A tela suporta layout responsivo: colunas lado a lado em telas largas e empilhadas em mobile.

### 6. Listas de compras inteligentes
- **Onde está no código:** `lib/modules/shopping_list/`, `lib/services/shopping_list/`.
- **Uso pelo usuário:** é possível gerar listas a partir de receitas, criar manualmente ou duplicar listas existentes. Cada lista possui seções (hortifruti, frios, mercearia), status de itens concluídos, notas e opções de compartilhamento.
- **Implementação técnica:**
  - Persistência local usando `SharedPreferences`, com limite automático de 50 listas para evitar crescimento indefinido. Excedentes são descartados preservando as mais recentes.
  - Controllers expõem ações de mesclar ingredientes idênticos, importar do plano nutricional e gerar texto amigável para compartilhamento.
  - O módulo possui rotas próprias (listagem, detalhe) e bindings específicos para reutilizar serviços entre telas.

### 7. Rotinas de bem-estar e lembretes
- **Onde está no código:** `lib/modules/wellness_routines/`, `lib/services/wellness/wellness_routine_service_impl.dart`, `lib/services/notifications/local_notification_service.dart`.
- **Uso pelo usuário:** o app oferece pacotes de lembretes (hidratação, pausas de respiração, sono, movimento). O perfil do usuário exibe um card chamando atenção para ajustar as jornadas ativas.
- **Implementação técnica:**
  - Preferências são persistidas localmente e retomadas no bootstrap.
  - As notificações utilizam canais dedicados e ajustes dinâmicos conforme o usuário interage (ex.: cancelar teste de app fechado quando volta ao foreground).
  - O serviço trata indisponibilidade de alarmes exatos com fallback para notificações aproximadas.

### 8. Diário emocional
- **Onde está no código:** `lib/modules/mood_journal/`, `lib/services/wellness/mood_journal_service_impl.dart`, `lib/models/wellness/mood_entry.dart`.
- **Uso pelo usuário:** registra humor, nível de energia, gatilhos e notas livres. Entradas podem ser editadas ou removidas, e a tela inicial mostra cartões resumindo tendências.
- **Implementação técnica:**
  - O serviço hidrata dados do `SharedPreferences` com validação de integridade e reinicialização automática em caso de corrupção.
  - Formatação de datas utiliza locale pt-BR carregado no bootstrap (`initializeDateFormatting`). Um fallback mantém a tela funcional mesmo que o locale não esteja disponível.

### 9. Trilhas de habilidades culinárias
- **Onde está no código:** `lib/modules/skill_journeys/`, `lib/models/skill/`.
- **Uso pelo usuário:** catálogo de jornadas temáticas (ex.: fundamentos de cortes, panificação, molhos). Cada trilha detalha etapas, dicas e materiais de apoio.
- **Implementação técnica:**
  - Dados são carregados de um serviço local (`SkillJourneyServiceImpl`) que pode ser facilmente conectado a uma API futura.
  - Controllers permitem marcar progresso e exibir cards de destaque no perfil.

### 10. Descoberta de restaurantes com Google Places
- **Onde está no código:** `lib/modules/restaurant_discovery/`, `lib/services/restaurants/`, `lib/services/location/`.
- **Uso pelo usuário:** ao abrir a tela, é possível escolher entre usar a localização atual (com permissão de GPS) ou digitar uma cidade manualmente. Chips de foco sugerem filtros alinhados ao plano nutricional (proteínas, refeições leves, vegetarianos etc.).
- **Implementação técnica:**
  - `RestaurantDiscoveryServiceImpl` consulta `places/textsearch` e `place/details` quando necessário, limitando a 20 resultados ordenados por relevância e distância.
  - A API key é lida de `GOOGLE_PLACES_API_KEY`. Mensagens específicas orientam o usuário quando a chave está ausente ou inválida.
  - Nomes alternativos, tags e coordenadas são combinados para deduplicar resultados e compor cards com endereço, serviços disponíveis e destaques dietéticos.

## Serviços auxiliares e infraestrutura
- **Notificações locais:** `LocalNotificationService` gerencia canais, solicita permissão (Android/iOS) e centraliza agendamento/cancelamento. Também dispara notificações de teste ao iniciar e remove lembretes quando o app retorna ao foreground.
- **Monitoramento de uso:** `AppUsageServiceImpl` registra aberturas do app, sequência atual, recordes e total de acessos. Os dados abastecem um card motivacional no perfil.
- **Lifecycle global:** `AppLifecycleService` observa estados (`resumed`, `paused`, `inactive`, `hidden`) para interromper notificações de app fechado e recalcular métricas de engajamento.
- **Compartilhamento:** `RecipeShareServiceImpl` monta mensagens ricas com título, ingredientes-chave e instruções resumidas.
- **Localização:** `LocationServiceImpl` reaproveita a última coordenada conhecida quando possível e solicita novas leituras usando `LocationSettings` compatíveis com o Geolocator 14.

## Estilo visual e componentes reutilizáveis
- Tema personalizado em `lib/application/ui/receitagora_app_ui_config.dart` com gradientes, tipografia do Google Fonts e extensões (`ReceitagoraSurfaceColors`).
- `AppPageBackground` encapsula planos de fundo com blur/gradiente para manter consistência nas telas.
- Componentes reutilizáveis incluem chips editáveis, cards responsivos e listas com estados vazios personalizados (ex.: `EmptyRecipesView`).
- Responsividade: layout adaptado para telas largas (web/desktop) usando `LayoutBuilder` e colunas condicionais.

## Boas práticas, monitoramento e próximas evoluções
- **Logs e depuração:** serviços utilizam prints condicionais e mensagens claras no UI ao capturar `AppException`.
- **Segurança:** credenciais sensíveis ficam no `.env`. Para produção, prefira `--dart-define` e cofres de segredos da loja correspondente.
- **Observabilidade:** métricas de uso e limites de convidado podem ser integrados a ferramentas externas via Cloud Functions.
- **Roadmap sugerido:** consultar `docs/new_feature_ideas.md` para ideias documentadas de evolução (assistente de substituições, planejamento multiusuário, etc.).

> Em caso de dúvidas adicionais, consulte a documentação oficial do [Flutter](https://docs.flutter.dev/), [GetX](https://pub.dev/packages/get), [Firebase](https://firebase.google.com/docs) e [Google Places](https://developers.google.com/maps/documentation/places/web-service/overview).
