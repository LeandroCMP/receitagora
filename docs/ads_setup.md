# Guia de Implementação de Propagandas

Este guia descreve como adicionar propagandas ao aplicativo Receitagora seguindo
boas práticas observadas em projetos de referência como o Air Sync. O foco é no
uso do Google AdMob, mas os princípios podem ser reaproveitados em outras redes.

## 1. Preparação no Console do AdMob

1. Acesse o [Google AdMob](https://admob.google.com/) e vincule o mesmo projeto
   Firebase já utilizado no aplicativo.
2. Crie um **app** dentro do AdMob para a plataforma desejada (Android e/ou
   iOS).
3. Gere os **IDs de bloco de anúncios** para cada formato que pretende utilizar,
   por exemplo:
   - Banner (fixo ou adaptável)
   - Intersticial
   - Recompensado (rewarded)
4. Registre também os **IDs de teste** fornecidos pela documentação do AdMob,
   evitando violações às políticas enquanto desenvolve.

## 2. Dependências Flutter

1. Adicione o pacote oficial `google_mobile_ads` ao `pubspec.yaml`:
   ```yaml
   dependencies:
     google_mobile_ads: ^5.1.0
   ```
2. Execute `flutter pub get` para baixar as bibliotecas.
3. Atualize o `android/app/build.gradle` e o `ios/Runner/Info.plist` seguindo as
   instruções do README do pacote (permissões, versões mínimas e metas de
   compilação).

## 3. Inicialização

1. No `main.dart`, inicialize o SDK assim que o Firebase for preparado:
   ```dart
   import 'package:google_mobile_ads/google_mobile_ads.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     await MobileAds.instance.initialize();
     runApp(const ReceitagoraApp());
   }
   ```
2. Caso utilize variáveis de ambiente (dotenv), armazene os IDs de produção ali
   e mantenha os IDs de teste hard-coded para builds de desenvolvimento.

## 4. Injeção de Dependências

Crie um serviço dedicado, por exemplo `AdService`, responsável por carregar e
exibir os blocos. Isso mantém a coerência arquitetural:

```dart
abstract class AdService {
  Future<void> loadHomeBanner();
  Widget buildHomeBanner();
  Future<bool> showInterstitialIfReady();
}
```

Implemente-o em `lib/services/ads/ad_service_impl.dart`, injetando os blocos de
anúncios e expondo *streams* para que os controladores apresentem ou escondam
ads conforme o estado de carregamento.

## 5. Integração nas Telas

1. **Home / Busca de Receitas:** posicione banners nos espaços vazios do layout,
   como abaixo do formulário ou no rodapé da lista de resultados.
2. **Tela de Detalhes:** considere intersticiais ao abrir uma receita nova, mas
   limite a frequência para não prejudicar a experiência.
3. **Fluxo de Premium:** sincronize com o `SessionService` para desativar
   propagandas em usuários assinantes (ver plano de monetização).

## 6. Testes e Monitoramento

- Utilize sempre os IDs de teste (`ca-app-pub-3940256099942544/...`) até que o
  app esteja pronto para produção.
- Verifique o console do AdMob para confirmar impressões, cliques e políticas.
- Adicione logs e métricas no Firebase Analytics para acompanhar o impacto na
  retenção.

## 7. Publicação

1. Substitua os IDs de teste pelos IDs reais apenas em builds de produção.
2. Atualize a política de privacidade do app informando o uso de serviços de
   publicidade.
3. Se precisar de consentimento (LGPD/GDPR), integre o SDK de Consentimento do
   Google antes de mostrar anúncios personalizados.

---

Seguindo estes passos, você terá um fluxo consistente para monetizar o
Receitagora com propagandas sem comprometer a arquitetura existente.
