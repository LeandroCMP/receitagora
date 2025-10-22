import 'dart:async';
import 'dart:math' as math;

import 'package:receitagora/models/nutrition/diet_plan.dart';
import 'package:receitagora/models/nutrition/diet_profile.dart';

import 'restaurant_discovery_service.dart';

class RestaurantDiscoveryServiceImpl implements RestaurantDiscoveryService {
  RestaurantDiscoveryServiceImpl();

  static const List<RestaurantFocus> _focusCatalog = [
    RestaurantFocus(
      id: 'balanced',
      label: 'Equilíbrio saudável',
      emoji: '🥗',
      description:
          'Bowls, saladas e grelhados leves para manter o cardápio em dia sem abrir mão do sabor.',
      tags: {'balanced', 'leve', 'salada', 'integral', 'natural', 'lowcarb'},
    ),
    RestaurantFocus(
      id: 'high_protein',
      label: 'Proteínas em destaque',
      emoji: '🥩',
      description: 'Churrascarias, parrillas e casas de grelhados ricas em proteína.',
      tags: {'proteina', 'churrasco', 'grelhado', 'parrilla'},
    ),
    RestaurantFocus(
      id: 'comfort_br',
      label: 'Caseiro brasileiro',
      emoji: '🍛',
      description: 'PF equilibrado, pratos regionais e comida afetiva bem servida.',
      tags: {'caseiro', 'brasileira', 'regional', 'comfort'},
    ),
    RestaurantFocus(
      id: 'italian',
      label: 'Massas e risotos',
      emoji: '🍝',
      description: 'Cantinas e fornerias com massas artesanais e risotos cremosos.',
      tags: {'massas', 'italiano', 'risoto', 'pizza'},
    ),
    RestaurantFocus(
      id: 'seafood',
      label: 'Peixes e frutos do mar',
      emoji: '🐟',
      description: 'Grelhados leves, moquecas e pratos do mar cheios de frescor.',
      tags: {'peixe', 'frutosdomar', 'seafood', 'leve'},
    ),
    RestaurantFocus(
      id: 'vegetarian',
      label: 'Vegetariano & vegano',
      emoji: '🥦',
      description: 'Cozinha plant-based criativa com ingredientes orgânicos e integrais.',
      tags: {'vegetariano', 'vegano', 'plantbased', 'natural', 'integral'},
    ),
    RestaurantFocus(
      id: 'light',
      label: 'Refeições leves',
      emoji: '🥙',
      description: 'Bowls frescos, wraps funcionais e lanches rápidos sem pesar.',
      tags: {'leve', 'lowcarb', 'wrap', 'bowl', 'salada'},
    ),
  ];

  static const List<_RestaurantVenue> _venues = [
    _RestaurantVenue(
      id: 'sp_raiz_do_campo',
      name: 'Raiz do Campo',
      cityLabel: 'São Paulo, SP',
      normalizedCity: 'sao paulo',
      address: 'R. Augusta, 1234 - Consolação',
      primaryCuisine: 'Natural contemporâneo',
      priceRange: 'R\$ 45 - R\$ 68',
      rating: 4.6,
      latitude: -23.5558,
      longitude: -46.6623,
      focusKeywords: {'balanced', 'leve', 'salada', 'integral', 'natural', 'vegetariano', 'vegano'},
      specialties: [
        'Buffet leve com grãos, saladas e grelhados do dia',
        'Combos low carb com sobremesas sem açúcar refinado',
      ],
      dietHighlights: [
        'Opções ricas em fibras e proteína vegetal',
        'Sucos prensados a frio e sobremesas sem lactose',
      ],
      services: ['Almoço no local', 'Entrega programada', 'Retirada'],
    ),
    _RestaurantVenue(
      id: 'sp_casa_do_grelhado',
      name: 'Casa do Grelhado Paulista',
      cityLabel: 'São Paulo, SP',
      normalizedCity: 'sao paulo',
      address: 'Av. Brigadeiro Luís Antônio, 2010 - Jardins',
      primaryCuisine: 'Grelhados e parrilla',
      priceRange: 'R\$ 62 - R\$ 95',
      rating: 4.7,
      latitude: -23.5622,
      longitude: -46.6559,
      focusKeywords: {'proteina', 'churrasco', 'grelhado', 'parrilla', 'lowcarb'},
      specialties: [
        'Cortes nobres com acompanhamento de vegetais na brasa',
        'Menu executivo hiperproteico com entrada e sobremesa leve',
      ],
      dietHighlights: [
        'Sugestões low carb alinhadas ao ganho de massa',
        'Molhos sem farinha e opção de arroz integral',
      ],
      services: ['Almoço e jantar', 'Reserva online', 'Delivery parceiro'],
    ),
    _RestaurantVenue(
      id: 'sp_trattoria_delle_nonne',
      name: 'Trattoria delle Nonne',
      cityLabel: 'São Paulo, SP',
      normalizedCity: 'sao paulo',
      address: 'R. Oscar Freire, 987 - Jardins',
      primaryCuisine: 'Massas artesanais',
      priceRange: 'R\$ 58 - R\$ 92',
      rating: 4.8,
      latitude: -23.561,
      longitude: -46.6689,
      focusKeywords: {'massas', 'italiano', 'risoto', 'comfort'},
      specialties: [
        'Massa fresca integral com molho de tomates rústico',
        'Risoto de abóbora com queijo de cabra e sementes tostadas',
      ],
      dietHighlights: [
        'Porções com ajuste de carboidrato conforme preferência',
        'Opções sem lactose e integrais mediante solicitação',
      ],
      services: ['Jantar no local', 'Menu degustação', 'Delivery noturno'],
    ),
    _RestaurantVenue(
      id: 'sp_mar_azul',
      name: 'Mar Azul Pinheiros',
      cityLabel: 'São Paulo, SP',
      normalizedCity: 'sao paulo',
      address: 'R. dos Pinheiros, 1145 - Pinheiros',
      primaryCuisine: 'Peixes e frutos do mar',
      priceRange: 'R\$ 55 - R\$ 98',
      rating: 4.5,
      latitude: -23.5661,
      longitude: -46.6941,
      focusKeywords: {'peixe', 'frutosdomar', 'leve', 'balanced'},
      specialties: [
        'Bowl de salmão grelhado com quinoa cítrica',
        'Moqueca de frutos do mar com leite de coco leve',
      ],
      dietHighlights: [
        'Sugestões ricas em ômega-3 para planos focados em saúde cardiovascular',
        'Possibilidade de substituir arroz por legumes salteados',
      ],
      services: ['Almoço executivo', 'Festival do mar aos sábados', 'Delivery próprio'],
    ),
    _RestaurantVenue(
      id: 'rj_orla_fit',
      name: 'Orla Fit Bistrô',
      cityLabel: 'Rio de Janeiro, RJ',
      normalizedCity: 'rio de janeiro',
      address: 'Av. Atlântica, 3200 - Copacabana',
      primaryCuisine: 'Saudável praiano',
      priceRange: 'R\$ 42 - R\$ 75',
      rating: 4.6,
      latitude: -22.986,
      longitude: -43.205,
      focusKeywords: {'balanced', 'leve', 'salada', 'bowl', 'lowcarb'},
      specialties: [
        'Bowls refrescantes com peixes marinados e frutas cítricas',
        'Wrap integral com frango, abacate e creme de castanhas',
      ],
      dietHighlights: [
        'Cardápio com indicação de calorias e macro nutrientes',
        'Sucos funcionais alinhados ao plano de hidratação',
      ],
      services: ['Café da manhã estendido', 'Entrega na praia', 'Programa de assinatura'],
    ),
    _RestaurantVenue(
      id: 'rj_fogo_atlantico',
      name: 'Fogo do Atlântico',
      cityLabel: 'Rio de Janeiro, RJ',
      normalizedCity: 'rio de janeiro',
      address: 'Av. das Américas, 5000 - Barra da Tijuca',
      primaryCuisine: 'Parrilla e frutos do mar',
      priceRange: 'R\$ 68 - R\$ 120',
      rating: 4.7,
      latitude: -22.999,
      longitude: -43.365,
      focusKeywords: {'proteina', 'churrasco', 'grelhado', 'frutosdomar', 'seafood'},
      specialties: [
        'Rodízio de grelhados com cortes magros e frutos do mar',
        'Pratos low carb com legumes tostados e purê de couve-flor',
      ],
      dietHighlights: [
        'Orientação de combinações ricas em proteína para cada perfil',
        'Estações com saladas frescas e grãos integrais',
      ],
      services: ['Jantar no local', 'Reserva de eventos', 'Delivery via parceiros'],
    ),
    _RestaurantVenue(
      id: 'rj_cantina_lapa',
      name: 'Cantina da Lapa',
      cityLabel: 'Rio de Janeiro, RJ',
      normalizedCity: 'rio de janeiro',
      address: 'R. do Lavradio, 180 - Lapa',
      primaryCuisine: 'Italiana clássica',
      priceRange: 'R\$ 48 - R\$ 82',
      rating: 4.4,
      latitude: -22.9136,
      longitude: -43.1797,
      focusKeywords: {'massas', 'italiano', 'risoto', 'comfort'},
      specialties: [
        'Espaguete artesanal ao molho pomodoro com manjericão fresco',
        'Risoto de frutos do mar com caldo leve e toque cítrico',
      ],
      dietHighlights: [
        'Opções de massa integral e redução de sódio sob demanda',
        'Entradas frias alinhadas a planos focados em leveza',
      ],
      services: ['Almoço no local', 'Noite da massa às quintas', 'Delivery noturno'],
    ),
    _RestaurantVenue(
      id: 'rj_mesa_carioca',
      name: 'Mesa Carioca',
      cityLabel: 'Rio de Janeiro, RJ',
      normalizedCity: 'rio de janeiro',
      address: 'R. Maria Angélica, 45 - Jardim Botânico',
      primaryCuisine: 'Brasileira contemporânea',
      priceRange: 'R\$ 52 - R\$ 88',
      rating: 4.5,
      latitude: -22.9681,
      longitude: -43.222,
      focusKeywords: {'caseiro', 'brasileira', 'regional', 'comfort', 'balanced'},
      specialties: [
        'Prato feito equilibrado com arroz integral, feijão cremoso e proteína grelhada',
        'Moqueca vegetariana com banana-da-terra assada',
      ],
      dietHighlights: [
        'Cardápio destaca substituições alinhadas a restrições alimentares',
        'Sobremesas com açúcar mascavo e frutas da estação',
      ],
      services: ['Almoço executivo', 'Menu família aos domingos', 'Delivery próprio'],
    ),
    _RestaurantVenue(
      id: 'bh_quintal_serra',
      name: 'Quintal da Serra',
      cityLabel: 'Belo Horizonte, MG',
      normalizedCity: 'belo horizonte',
      address: 'R. Fernandes Tourinho, 600 - Savassi',
      primaryCuisine: 'Cozinha mineira leve',
      priceRange: 'R\$ 39 - R\$ 72',
      rating: 4.6,
      latitude: -19.9378,
      longitude: -43.9301,
      focusKeywords: {'caseiro', 'regional', 'comfort', 'balanced'},
      specialties: [
        'PF mineiro com feijão tropeiro mais leve e salada morna',
        'Tilápia assada com purê de mandioquinha e legumes ao vapor',
      ],
      dietHighlights: [
        'Indicação de trocas para planos de redução calórica',
        'Sobremesas com doce de leite zero adição de açúcar',
      ],
      services: ['Self-service equilibrado', 'Delivery no centro', 'Eventos corporativos'],
    ),
    _RestaurantVenue(
      id: 'bh_brasa_moderna',
      name: 'Brasa Moderna',
      cityLabel: 'Belo Horizonte, MG',
      normalizedCity: 'belo horizonte',
      address: 'Av. Álvares Cabral, 805 - Centro',
      primaryCuisine: 'Parrilla urbana',
      priceRange: 'R\$ 55 - R\$ 96',
      rating: 4.7,
      latitude: -19.9285,
      longitude: -43.9412,
      focusKeywords: {'proteina', 'churrasco', 'grelhado', 'parrilla'},
      specialties: [
        'Bife ancho com legumes tostados e chimichurri leve',
        'Sanduíche de roast beef em pão integral e maionese de ervas',
      ],
      dietHighlights: [
        'Sugestões para bulking controlado com acompanhamento de macros',
        'Menu kids com versões sem fritura',
      ],
      services: ['Almoço executivo', 'Delivery noite', 'Assinatura de marmitas'],
    ),
    _RestaurantVenue(
      id: 'bh_horta_urbana',
      name: 'Horta Urbana',
      cityLabel: 'Belo Horizonte, MG',
      normalizedCity: 'belo horizonte',
      address: 'R. Santa Catarina, 975 - Lourdes',
      primaryCuisine: 'Vegetariano criativo',
      priceRange: 'R\$ 42 - R\$ 70',
      rating: 4.8,
      latitude: -19.9261,
      longitude: -43.9406,
      focusKeywords: {'vegetariano', 'vegano', 'plantbased', 'natural', 'integral', 'balanced'},
      specialties: [
        'Moqueca de banana-da-terra com arroz de coco e farofa crocante',
        'Lasanha de abobrinha com ricota de castanhas',
      ],
      dietHighlights: [
        'Cardápio com opções sem glúten e sem lactose',
        'Sobremesas à base de frutas e cacau puro',
      ],
      services: ['Buffet por peso', 'Feira orgânica aos sábados', 'Entrega via app'],
    ),
    _RestaurantVenue(
      id: 'bh_cantina_pampulha',
      name: 'Cantina Pampulha',
      cityLabel: 'Belo Horizonte, MG',
      normalizedCity: 'belo horizonte',
      address: 'Av. Otacílio Negrão de Lima, 3000 - Pampulha',
      primaryCuisine: 'Italiana mineira',
      priceRange: 'R\$ 47 - R\$ 85',
      rating: 4.5,
      latitude: -19.851,
      longitude: -43.9718,
      focusKeywords: {'massas', 'italiano', 'risoto', 'comfort'},
      specialties: [
        'Nhoque de mandioquinha com ragu de fraldinha',
        'Risoto de queijo canastra com cogumelos salteados',
      ],
      dietHighlights: [
        'Troca de massa tradicional por integral sob pedido',
        'Opções de meia porção para controle de calorias',
      ],
      services: ['Almoço de domingo', 'Delivery regional', 'Eventos familiares'],
    ),
    _RestaurantVenue(
      id: 'ct_jardim_oriente',
      name: 'Jardim do Oriente',
      cityLabel: 'Curitiba, PR',
      normalizedCity: 'curitiba',
      address: 'Av. Vicente Machado, 1200 - Centro',
      primaryCuisine: 'Asiático leve',
      priceRange: 'R\$ 44 - R\$ 78',
      rating: 4.6,
      latitude: -25.4365,
      longitude: -49.2769,
      focusKeywords: {'leve', 'bowl', 'peixe', 'frutosdomar', 'balanced'},
      specialties: [
        'Bowl de salmão selado com arroz de jasmim integral',
        'Ramen leve com caldo vegetal e cogumelos sazonais',
      ],
      dietHighlights: [
        'Caldo sem glutamato e massas integrais sob solicitação',
        'Sucos quentes e frios com ervas digestivas',
      ],
      services: ['Almoço executivo', 'Tea time oriental', 'Delivery próprio'],
    ),
    _RestaurantVenue(
      id: 'ct_foggo_parrilla',
      name: 'Foggo Parrilla',
      cityLabel: 'Curitiba, PR',
      normalizedCity: 'curitiba',
      address: 'R. Saldanha Marinho, 1650 - Batel',
      primaryCuisine: 'Parrilla uruguaia',
      priceRange: 'R\$ 65 - R\$ 110',
      rating: 4.7,
      latitude: -25.4421,
      longitude: -49.2803,
      focusKeywords: {'proteina', 'churrasco', 'grelhado', 'parrilla'},
      specialties: [
        'Assado de tira com salada morna de grãos',
        'Hambúrguer artesanal servido no pão de fermentação natural',
      ],
      dietHighlights: [
        'Acompanhamentos low carb para planos de ganho de massa',
        'Oferece cortes magros marinados com ervas frescas',
      ],
      services: ['Jantar no local', 'Assinatura corporativa', 'Delivery via apps'],
    ),
    _RestaurantVenue(
      id: 'ct_emporio_organico',
      name: 'Empório Orgânico Centro',
      cityLabel: 'Curitiba, PR',
      normalizedCity: 'curitiba',
      address: 'R. XV de Novembro, 500 - Centro',
      primaryCuisine: 'Orgânico e plant-based',
      priceRange: 'R\$ 36 - R\$ 68',
      rating: 4.5,
      latitude: -25.4296,
      longitude: -49.2713,
      focusKeywords: {'vegetariano', 'vegano', 'plantbased', 'natural', 'integral', 'balanced'},
      specialties: [
        'Buffet orgânico com pratos regionais reinterpretados',
        'Tortas salgadas integrais com recheios sazonais',
      ],
      dietHighlights: [
        'Ingredientes certificados e sem conservantes',
        'Sobremesas adoçadas com frutas e melado',
      ],
      services: ['Almoço no local', 'Mercearia orgânica', 'Entrega por assinatura'],
    ),
    _RestaurantVenue(
      id: 'ct_nonna_curitiba',
      name: 'Nonna di Curitiba',
      cityLabel: 'Curitiba, PR',
      normalizedCity: 'curitiba',
      address: 'R. Padre Anchieta, 2100 - Bigorrilho',
      primaryCuisine: 'Italiana artesanal',
      priceRange: 'R\$ 50 - R\$ 88',
      rating: 4.6,
      latitude: -25.4454,
      longitude: -49.2911,
      focusKeywords: {'massas', 'italiano', 'risoto', 'comfort'},
      specialties: [
        'Talharim artesanal ao pesto de manjericão com castanhas',
        'Risoto de limão siciliano com camarões salteados',
      ],
      dietHighlights: [
        'Massas frescas também em versão integral',
        'Pratos com ajuste de sódio para necessidades específicas',
      ],
      services: ['Jantar romântico', 'Delivery noturno', 'Cursos de massa fresca'],
    ),
    _RestaurantVenue(
      id: 'po_braseiro_guaiba',
      name: 'Braseiro do Guaíba',
      cityLabel: 'Porto Alegre, RS',
      normalizedCity: 'porto alegre',
      address: 'Av. Edvaldo Pereira Paiva, 1200 - Praia de Belas',
      primaryCuisine: 'Churrasco gaúcho',
      priceRange: 'R\$ 60 - R\$ 115',
      rating: 4.7,
      latitude: -30.033,
      longitude: -51.2287,
      focusKeywords: {'proteina', 'churrasco', 'grelhado', 'parrilla'},
      specialties: [
        'Costela fogo de chão com legumes defumados',
        'Buffet de saladas com grãos e molhos autorais',
      ],
      dietHighlights: [
        'Indicação de cortes magros para planos de manutenção',
        'Sobremesas com frutas assadas e especiarias',
      ],
      services: ['Rodízio completo', 'Take away por peso', 'Delivery em embalagens térmicas'],
    ),
    _RestaurantVenue(
      id: 'po_casa_verde',
      name: 'Casa Verde Jardim',
      cityLabel: 'Porto Alegre, RS',
      normalizedCity: 'porto alegre',
      address: 'R. Dona Laura, 55 - Moinhos de Vento',
      primaryCuisine: 'Vegetariano contemporâneo',
      priceRange: 'R\$ 40 - R\$ 74',
      rating: 4.6,
      latitude: -30.0344,
      longitude: -51.2131,
      focusKeywords: {'vegetariano', 'vegano', 'plantbased', 'natural', 'leve'},
      specialties: [
        'Prato do dia com grãos orgânicos e vegetais assados',
        'Tigelas de açaí salgado com toppings funcionais',
      ],
      dietHighlights: [
        'Ingredientes sem glúten preparados em área dedicada',
        'Bebidas fermentadas e kombuchas autorais',
      ],
      services: ['Almoço garden', 'Eventos intimistas', 'Delivery veg'],
    ),
    _RestaurantVenue(
      id: 'po_porto_mediterraneo',
      name: 'Porto Mediterrâneo',
      cityLabel: 'Porto Alegre, RS',
      normalizedCity: 'porto alegre',
      address: 'R. Padre Chagas, 300 - Moinhos de Vento',
      primaryCuisine: 'Mediterrânea do mar',
      priceRange: 'R\$ 58 - R\$ 102',
      rating: 4.5,
      latitude: -30.0279,
      longitude: -51.226,
      focusKeywords: {'peixe', 'frutosdomar', 'leve', 'balanced'},
      specialties: [
        'Polvo grelhado com purê de grão-de-bico e azeite cítrico',
        'Linguado ao limão com legumes salteados',
      ],
      dietHighlights: [
        'Sugestões com destaque de ômega-3 e calorias estimadas',
        'Entradas frias com conservas caseiras de legumes',
      ],
      services: ['Menu harmonizado', 'Festival do mar', 'Delivery premium'],
    ),
    _RestaurantVenue(
      id: 'po_forneria_porto',
      name: 'Forneria do Porto',
      cityLabel: 'Porto Alegre, RS',
      normalizedCity: 'porto alegre',
      address: 'R. Joaquim Nabuco, 90 - Cidade Baixa',
      primaryCuisine: 'Forneria italiana',
      priceRange: 'R\$ 48 - R\$ 86',
      rating: 4.4,
      latitude: -30.0423,
      longitude: -51.2198,
      focusKeywords: {'massas', 'italiano', 'pizza', 'comfort'},
      specialties: [
        'Pizza de fermentação lenta com farinhas especiais',
        'Pappardelle com ragu de cogumelos e azeite trufado',
      ],
      dietHighlights: [
        'Opção de massa sem glúten e pizza com massa de couve-flor',
        'Sobremesas individuais com controle de porção',
      ],
      services: ['Rodízio de pizza sazonal', 'Take away', 'Delivery rápido'],
    ),
    _RestaurantVenue(
      id: 'sa_sabor_baia',
      name: 'Sabor da Baía',
      cityLabel: 'Salvador, BA',
      normalizedCity: 'salvador',
      address: 'Largo do Farol da Barra, 15 - Barra',
      primaryCuisine: 'Baiana do mar',
      priceRange: 'R\$ 46 - R\$ 88',
      rating: 4.7,
      latitude: -13.0059,
      longitude: -38.5322,
      focusKeywords: {'frutosdomar', 'peixe', 'regional', 'leve'},
      specialties: [
        'Moqueca de peixe com azeite de dendê moderado e arroz integral',
        'Camarões grelhados com purê de banana-da-terra assada',
      ],
      dietHighlights: [
        'Indicação de versões menos calóricas sem perder o sabor',
        'Sucos e águas aromatizadas com frutas tropicais',
      ],
      services: ['Almoço vista mar', 'Delivery na orla', 'Eventos ao pôr do sol'],
    ),
    _RestaurantVenue(
      id: 'sa_terraco_carne',
      name: 'Terraço da Carne',
      cityLabel: 'Salvador, BA',
      normalizedCity: 'salvador',
      address: 'Av. Tancredo Neves, 2227 - Caminho das Árvores',
      primaryCuisine: 'Steakhouse tropical',
      priceRange: 'R\$ 62 - R\$ 110',
      rating: 4.5,
      latitude: -12.9991,
      longitude: -38.5129,
      focusKeywords: {'proteina', 'churrasco', 'grelhado', 'regional'},
      specialties: [
        'Prime rib com manteiga de ervas nordestinas',
        'Mix de espetos magros com saladas crocantes',
      ],
      dietHighlights: [
        'Acompanhamentos com raízes assadas e farofas leves',
        'Drinks sem álcool pensados para hidratação',
      ],
      services: ['Jantar panorâmico', 'Adega climatizada', 'Delivery noturno'],
    ),
    _RestaurantVenue(
      id: 'sa_raizes_tropicais',
      name: 'Raízes Tropicais',
      cityLabel: 'Salvador, BA',
      normalizedCity: 'salvador',
      address: 'R. das Hortênsias, 360 - Pituba',
      primaryCuisine: 'Natural tropical',
      priceRange: 'R\$ 38 - R\$ 69',
      rating: 4.6,
      latitude: -12.9898,
      longitude: -38.4372,
      focusKeywords: {'vegetariano', 'vegano', 'plantbased', 'natural', 'leve'},
      specialties: [
        'Prato do dia com grãos tropicais, legumes grelhados e frutas assadas',
        'Tigelas frias com mix de folhas, quinoa e molhos cítricos',
      ],
      dietHighlights: [
        'Combinações detox alinhadas a planos de reeducação alimentar',
        'Sobremesas com cacau e castanhas regionais',
      ],
      services: ['Almoço leve', 'Mercadinho de produtores locais', 'Entrega sustentável'],
    ),
    _RestaurantVenue(
      id: 'sa_cantina_solar',
      name: 'Cantina Solar',
      cityLabel: 'Salvador, BA',
      normalizedCity: 'salvador',
      address: 'R. do Carmo, 45 - Santo Antônio Além do Carmo',
      primaryCuisine: 'Italiana tropicalizada',
      priceRange: 'R\$ 44 - R\$ 82',
      rating: 4.4,
      latitude: -12.9792,
      longitude: -38.5166,
      focusKeywords: {'massas', 'italiano', 'risoto', 'comfort'},
      specialties: [
        'Tagliatelle com frutos do mar e toque de coentro',
        'Risoto de queijo coalho com redução de maracujá',
      ],
      dietHighlights: [
        'Possibilidade de massa sem glúten e versões sem lactose',
        'Entradas frias com legumes marinados e azeites infusionados',
      ],
      services: ['Jantar romântico', 'Delivery artesanal', 'Cursos de culinária'],
    ),
  ];

  static final List<String> _supportedCities = _venues
      .map((venue) => venue.normalizedCity)
      .toSet()
      .toList(growable: false);

  @override
  List<RestaurantFocus> baseFocuses() => _focusCatalog;

  @override
  List<RestaurantFocus> focusSuggestionsForPlan(NutritionPlan? plan) {
    if (plan == null) {
      return const <RestaurantFocus>[];
    }

    final profile = plan.profile;
    final ids = <String>{};

    switch (profile.goal) {
      case DietGoal.gainMass:
        ids.addAll({'high_protein', 'balanced'});
        break;
      case DietGoal.loseWeight:
        ids.addAll({'balanced', 'light', 'seafood'});
        break;
      case DietGoal.maintain:
        ids.addAll({'balanced', 'comfort_br', 'seafood'});
        break;
      case DietGoal.reeducate:
        ids.addAll({'balanced', 'light', 'vegetarian'});
        break;
    }

    if (profile.prefersBrazilianCuisine) {
      ids.add('comfort_br');
    }

    if (profile.prefersSeasonalProduce) {
      ids.add('vegetarian');
    }

    if (profile.goal == DietGoal.gainMass && profile.exercisesRegularly) {
      ids.add('high_protein');
    }

    return _focusCatalog.where((focus) => ids.contains(focus.id)).toList(growable: false);
  }

  @override
  Future<RestaurantSearchResult> searchNearby({
    required double latitude,
    required double longitude,
    RestaurantFocus? focus,
    int limit = 12,
  }) async {
    final matches = _venues
        .map((venue) => _VenueMatch(
              venue: venue,
              distanceKm: _distanceKm(latitude, longitude, venue.latitude, venue.longitude),
            ))
        .where((match) => _matchesFocus(match.venue, focus))
        .toList(growable: false);

    matches.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final limited = matches.take(limit).toList(growable: false);
    final resolvedCity =
        limited.isNotEmpty ? limited.first.venue.cityLabel : _resolveNearestCityLabel(latitude, longitude);
    final suggestions = limited
        .map((match) => match.venue.toSuggestion(distanceKm: match.distanceKm))
        .toList(growable: false);

    return RestaurantSearchResult(
      restaurants: suggestions,
      resolvedLocationLabel: resolvedCity,
      appliedFocus: focus,
      referenceCoordinates: LocationCoordinates(latitude: latitude, longitude: longitude),
    );
  }

  @override
  Future<RestaurantSearchResult> searchByCity({
    required String city,
    RestaurantFocus? focus,
    int limit = 12,
  }) async {
    final normalizedInput = _normalize(city);
    final resolvedKey = _resolveCityKey(normalizedInput);

    final venues = _venues
        .where((venue) =>
            venue.normalizedCity == resolvedKey ||
            venue.normalizedCity.contains(resolvedKey) ||
            resolvedKey.contains(venue.normalizedCity))
        .toList(growable: false);

    final filtered = venues.where((venue) => _matchesFocus(venue, focus)).toList(growable: false);
    filtered.sort((a, b) => b.rating.compareTo(a.rating));

    final suggestions = filtered.take(limit).map((venue) => venue.toSuggestion()).toList(growable: false);

    final resolvedLabel = filtered.isNotEmpty
        ? filtered.first.cityLabel
        : venues.isNotEmpty
            ? venues.first.cityLabel
            : _titleCase(city);

    return RestaurantSearchResult(
      restaurants: suggestions,
      resolvedLocationLabel: resolvedLabel,
      appliedFocus: focus,
      referenceCoordinates: null,
    );
  }

  static bool _matchesFocus(_RestaurantVenue venue, RestaurantFocus? focus) {
    if (focus == null) {
      return true;
    }
    return focus.tags.any(venue.focusKeywords.contains);
  }

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return double.parse((earthRadius * c).toStringAsFixed(2));
  }

  static double _degToRad(double degree) => degree * (math.pi / 180);

  static String _resolveNearestCityLabel(double latitude, double longitude) {
    _VenueMatch? closest;
    for (final venue in _venues) {
      final distance = _distanceKm(latitude, longitude, venue.latitude, venue.longitude);
      if (closest == null || distance < closest.distanceKm) {
        closest = _VenueMatch(venue: venue, distanceKm: distance);
      }
    }
    return closest?.venue.cityLabel ?? 'Sua região';
  }

  static String _resolveCityKey(String normalizedInput) {
    if (normalizedInput.isEmpty) {
      return normalizedInput;
    }
    if (_supportedCities.contains(normalizedInput)) {
      return normalizedInput;
    }
    for (final city in _supportedCities) {
      if (city.contains(normalizedInput) || normalizedInput.contains(city)) {
        return city;
      }
    }
    return normalizedInput;
  }

  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_normalizationMap[char] ?? char);
    }
    final simplified = buffer.toString();
    return simplified.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _titleCase(String input) {
    final words = _normalize(input).split(' ');
    if (words.isEmpty) {
      return input.trim();
    }
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static const Map<String, String> _normalizationMap = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
}

class _VenueMatch {
  const _VenueMatch({required this.venue, required this.distanceKm});

  final _RestaurantVenue venue;
  final double distanceKm;
}

class _RestaurantVenue {
  const _RestaurantVenue({
    required this.id,
    required this.name,
    required this.cityLabel,
    required this.normalizedCity,
    required this.address,
    required this.primaryCuisine,
    required this.priceRange,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.focusKeywords,
    required this.specialties,
    required this.dietHighlights,
    required this.services,
  });

  final String id;
  final String name;
  final String cityLabel;
  final String normalizedCity;
  final String address;
  final String primaryCuisine;
  final String priceRange;
  final double rating;
  final double latitude;
  final double longitude;
  final Set<String> focusKeywords;
  final List<String> specialties;
  final List<String> dietHighlights;
  final List<String> services;

  RestaurantSuggestion toSuggestion({double? distanceKm}) {
    return RestaurantSuggestion(
      id: id,
      name: name,
      city: cityLabel,
      address: address,
      primaryCuisine: primaryCuisine,
      priceRange: priceRange,
      rating: rating,
      specialties: specialties,
      dietHighlights: dietHighlights,
      services: services,
      distanceKm: distanceKm,
    );
  }
}
