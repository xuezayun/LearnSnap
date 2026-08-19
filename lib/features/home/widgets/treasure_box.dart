import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/task_list_group.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/kid_style.dart';

class TreasureBox extends StatefulWidget {
  const TreasureBox({
    super.key,
    required this.title,
    required this.taskType,
    required this.category,
    required this.onTap,
    this.compact = false,
    this.index = 0,
  });

  final String title;
  final String taskType;
  final TaskCategory category;
  final VoidCallback onTap;
  final bool compact;
  final int index;

  @override
  State<TreasureBox> createState() => _TreasureBoxState();
}

class _TreasureBoxState extends State<TreasureBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 380 + widget.index * 40),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = lookForTaskType(widget.taskType);
    final done = widget.category == TaskCategory.completed;
    final cta = kidCtaLabel(widget.category);
    final chip = kidChipLabel(widget.category);
    final iconSize = widget.compact ? 30.0 : 28.0;
    final badgeSize = widget.compact ? 58.0 : 54.0;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: look.color.withValues(alpha: 0.35), width: 2),
          ),
          shadowColor: look.color.withValues(alpha: 0.35),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: look.color.withValues(alpha: 0.22),
                    offset: const Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              padding: EdgeInsets.all(widget.compact ? 18 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        decoration: BoxDecoration(
                          color: look.wash,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(look.icon, size: iconSize, color: look.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.nunito(
                                fontSize: widget.compact ? 20 : 17,
                                fontWeight: FontWeight.w800,
                                color: done
                                    ? AppColors.inkMuted
                                    : AppColors.ink,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MiniTag(
                                  label: look.label,
                                  color: look.color,
                                  wash: look.wash,
                                ),
                                _MiniTag(
                                  label: chip,
                                  color: done
                                      ? AppColors.success
                                      : (widget.category == TaskCategory.rejected
                                          ? AppColors.accentSun
                                          : look.color),
                                  wash: done
                                      ? const Color(0xFFEEF8EE)
                                      : look.wash,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _QuestButton(
                    label: cta,
                    color: done ? AppColors.success : look.color,
                    compact: widget.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    required this.color,
    required this.wash,
  });

  final String label;
  final Color color;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _QuestButton extends StatelessWidget {
  const _QuestButton({
    required this.label,
    required this.color,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 44 : 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: compact ? 16 : 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
