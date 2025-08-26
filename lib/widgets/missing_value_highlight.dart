import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/styles.dart';

/// Widget for highlighting missing values in tables and forms
class MissingValueHighlight extends StatelessWidget {
  final Widget child;
  final bool isMissing;
  final String? tooltip;
  final VoidCallback? onTap;

  const MissingValueHighlight({
    Key? key,
    required this.child,
    required this.isMissing,
    this.tooltip,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isMissing) {
      return child;
    }

    Widget highlightedChild = Container(
      decoration: AppStyles.missingValueDecoration,
      child: child,
    );

    if (tooltip != null) {
      highlightedChild = Tooltip(
        message: tooltip!,
        child: highlightedChild,
      );
    }

    if (onTap != null) {
      highlightedChild = InkWell(
        onTap: onTap,
        child: highlightedChild,
      );
    }

    return highlightedChild;
  }
}

/// Animated missing value indicator
class AnimatedMissingIndicator extends StatefulWidget {
  final bool isMissing;
  final Widget child;

  const AnimatedMissingIndicator({
    Key? key,
    required this.isMissing,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedMissingIndicator> createState() =>
      _AnimatedMissingIndicatorState();
}

class _AnimatedMissingIndicatorState extends State<AnimatedMissingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: AppColors.missingValueBg,
      end: AppColors.missingValueBg.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isMissing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedMissingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isMissing != oldWidget.isMissing) {
      if (widget.isMissing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMissing) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          color: _colorAnimation.value,
          border: const Border(
            left: BorderSide(color: AppColors.missingValueBorder, width: 3),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Missing value badge for showing count of missing fields
class MissingValueBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const MissingValueBadge({
    Key? key,
    required this.count,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Progress indicator for showing completion percentage
class CompletionProgressIndicator extends StatelessWidget {
  final double percentage;
  final Color? color;
  final double height;
  final bool showLabel;

  const CompletionProgressIndicator({
    Key? key,
    required this.percentage,
    this.color,
    this.height = 8.0,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _getColorForPercentage(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Text(
            '${percentage.round()}% Complete',
            style: AppStyles.captionTextStyle.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (showLabel) const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

/// Field status indicator showing if field is complete, missing, or has suggestions
class FieldStatusIndicator extends StatelessWidget {
  final bool isMissing;
  final bool hasSuggestions;
  final VoidCallback? onTap;

  const FieldStatusIndicator({
    Key? key,
    required this.isMissing,
    required this.hasSuggestions,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    if (isMissing && hasSuggestions) {
      icon = Icons.lightbulb;
      color = AppColors.warning;
      tooltip = 'Missing value - suggestions available';
    } else if (isMissing) {
      icon = Icons.error;
      color = AppColors.error;
      tooltip = 'Missing value';
    } else {
      icon = Icons.check_circle;
      color = AppColors.success;
      tooltip = 'Value present';
    }

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      ),
    );
  }
}
