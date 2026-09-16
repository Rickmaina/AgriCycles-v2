import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared status tracker (Section 4.2). Renders a linear sequence of
/// state labels with the current step highlighted. Terminal/branch
/// states render as a red chip instead of a linear step.
///
/// Used identically by vet visits, marketplace orders, and any future
/// state machine — the caller supplies labels + current index.
class StatusTracker extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
  final bool vertical;
  final String? terminalLabel;

  const StatusTracker({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.vertical = true,
    this.terminalLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (terminalLabel != null) return _terminal();
    return vertical ? _vertical() : _horizontal();
  }

  Widget _terminal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              terminalLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vertical() {
    return Column(
      children: List.generate(steps.length, (i) {
        final done = i < currentIndex;
        final current = i == currentIndex;
        final last = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    _dot(done: done, current: current),
                    if (!last)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: done ? AppColors.primary : AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : 16),
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          current ? FontWeight.w700 : FontWeight.w500,
                      color: done
                          ? AppColors.textPrimary
                          : current
                              ? AppColors.primary
                              : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _horizontal() {
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < currentIndex;
        final current = i == currentIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == 0
                          ? Colors.transparent
                          : done || current
                              ? AppColors.primary
                              : AppColors.border,
                    ),
                  ),
                  _dot(done: done, current: current),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == steps.length - 1
                          ? Colors.transparent
                          : done
                              ? AppColors.primary
                              : AppColors.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: done
                      ? AppColors.textPrimary
                      : current
                          ? AppColors.primary
                          : AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _dot({required bool done, required bool current}) {
    if (done) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (current) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
      ),
    );
  }
}
