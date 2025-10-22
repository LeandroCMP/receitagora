import 'package:get/get.dart';

import 'package:receitagora/models/skill/skill_journey.dart';

import 'skill_journey_service.dart';

class SkillJourneyServiceImpl extends GetxService implements SkillJourneyService {
  SkillJourneyServiceImpl();

  final List<SkillJourney> _journeys = <SkillJourney>[
    const SkillJourney(
      id: 'knife_skills_foundations',
      title: 'Fundamentos de Facas',
      description:
          'Domine cortes essenciais e técnicas de segurança para acelerar o preparo das receitas.',
      focus: 'Técnica',
      level: 'Iniciante',
      steps: <SkillJourneyStep>[
        SkillJourneyStep(
          title: 'Segurança e postura',
          description:
              'Aprenda empunhadura correta, posicionamento dos dedos e cuidados básicos antes de cortar.',
          durationMinutes: 12,
        ),
        SkillJourneyStep(
          title: 'Cortes em hortaliças',
          description:
              'Pratique cortes em bastonete, brunoise e julienne usando legumes firmes como cenoura e pepino.',
          durationMinutes: 18,
        ),
        SkillJourneyStep(
          title: 'Proteínas com precisão',
          description:
              'Faça filetagem simples de peito de frango e porcionamento de peixe mantendo a textura.',
          durationMinutes: 20,
        ),
      ],
    ),
    const SkillJourney(
      id: 'sauces_creative_basics',
      title: 'Bases de Molhos Criativos',
      description:
          'Construa repertório de molhos rápidos para transformar refeições do dia a dia.',
      focus: 'Sabores',
      level: 'Intermediário',
      steps: <SkillJourneyStep>[
        SkillJourneyStep(
          title: 'Emulsões estáveis',
          description:
              'Monte vinagrete, maionese caseira e molho de iogurte entendendo a química das emulsões.',
          durationMinutes: 16,
        ),
        SkillJourneyStep(
          title: 'Reduções aromáticas',
          description:
              'Reduza caldo com ervas e especiarias para criar bases concentradas que elevam grelhados.',
          durationMinutes: 22,
        ),
        SkillJourneyStep(
          title: 'Finalizações rápidas',
          description:
              'Combine manteiga noisette, ervas frescas e cítricos para finalizar massas e legumes.',
          durationMinutes: 14,
        ),
      ],
    ),
    const SkillJourney(
      id: 'plant_based_week',
      title: 'Semana Plant-Based Descomplicada',
      description:
          'Planeje sete dias de refeições vegetais com foco em proteínas completas e variedade.',
      focus: 'Planejamento',
      level: 'Todos os níveis',
      steps: <SkillJourneyStep>[
        SkillJourneyStep(
          title: 'Bases proteicas',
          description:
              'Prepare lotes de grão-de-bico, lentilha e tofu temperados para usar durante a semana.',
          durationMinutes: 25,
        ),
        SkillJourneyStep(
          title: 'Montagem express',
          description:
              'Monte tigelas e wraps balanceados combinando texturas, molhos frescos e crocantes.',
          durationMinutes: 18,
        ),
        SkillJourneyStep(
          title: 'Reaproveitamento inteligente',
          description:
              'Reinvente sobras em sopas cremosas e salteados rápidos com especiarias.',
          durationMinutes: 20,
        ),
      ],
    ),
  ];

  @override
  List<SkillJourney> get journeys => List.unmodifiable(_journeys);

  @override
  SkillJourney? findById(String id) {
    for (final journey in _journeys) {
      if (journey.id == id) {
        return journey;
      }
    }
    return null;
  }
}
