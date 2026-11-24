import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../theme/app_theme.dart';
import 'assistant_step.dart';

class AssistantGuideOverlay extends StatelessWidget {
  final List<AssistantStep> steps;
  final int currentStepIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onDismiss;

  const AssistantGuideOverlay({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.onNext,
    required this.onPrevious,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty || currentStepIndex < 0 || currentStepIndex >= steps.length) {
      return const SizedBox.shrink();
    }

    final step = steps[currentStepIndex];
    final isLast = currentStepIndex == steps.length - 1;
    final isFirst = currentStepIndex == 0;

    return Stack(
      children: [
        // Dark translucent scrim background
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Prevent clicks leaking
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
        ),

        // Mascot Coach Dialog at the bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Mascot Avatar + Title + Step Counter
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryNavy, AppTheme.primaryTeal],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryNavy.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.shield, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr(step.titleKey),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.tr('assistant_step_counter')
                                      .replaceFirst('%d', '${currentStepIndex + 1}')
                                      .replaceFirst('%d', '${steps.length}'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black45, size: 20),
                            onPressed: onDismiss,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Speech Bubble Content
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryNavy.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          AppStrings.tr(step.messageKey),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons: Skip, Back, Next / Finish
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: onDismiss,
                            child: Text(
                              AppStrings.tr('assistant_btn_skip'),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (!isFirst)
                                TextButton(
                                  onPressed: onPrevious,
                                  child: Text(
                                    AppStrings.tr('assistant_btn_back'),
                                    style: const TextStyle(
                                      color: AppTheme.primaryNavy,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: isLast ? onDismiss : onNext,
                                child: Text(
                                  isLast
                                      ? AppStrings.tr('assistant_btn_finish')
                                      : AppStrings.tr('assistant_btn_next'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
