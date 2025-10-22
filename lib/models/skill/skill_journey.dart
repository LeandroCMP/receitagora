class SkillJourneyStep {
  const SkillJourneyStep({
    required this.title,
    required this.description,
    required this.durationMinutes,
  });

  final String title;
  final String description;
  final int durationMinutes;
}

class SkillJourney {
  const SkillJourney({
    required this.id,
    required this.title,
    required this.description,
    required this.focus,
    required this.level,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final String focus;
  final String level;
  final List<SkillJourneyStep> steps;

  int get totalDurationMinutes =>
      steps.fold(0, (total, step) => total + step.durationMinutes);
}
