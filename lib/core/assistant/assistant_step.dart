class AssistantStep {
  final String titleKey;
  final String messageKey;
  final int? targetTabIndex;

  const AssistantStep({
    required this.titleKey,
    required this.messageKey,
    this.targetTabIndex,
  });
}
