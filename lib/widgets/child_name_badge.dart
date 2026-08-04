import 'package:flutter/material.dart';

class ChildAccent {
  const ChildAccent({
    required this.bg,
    required this.fg,
    required this.border,
  });

  final Color bg;
  final Color fg;
  final Color border;
}

const List<ChildAccent> _childPalette = [
  ChildAccent(
    bg: Color(0xFFE8F8F6),
    fg: Color(0xFF1A9E92),
    border: Color(0xFF2EC4B6),
  ),
  ChildAccent(
    bg: Color(0xFFFFF4E8),
    fg: Color(0xFFC45C1A),
    border: Color(0xFFF0A060),
  ),
  ChildAccent(
    bg: Color(0xFFEEF3FF),
    fg: Color(0xFF3B5BCC),
    border: Color(0xFF6B8CFF),
  ),
  ChildAccent(
    bg: Color(0xFFEEF8EE),
    fg: Color(0xFF2D8A4E),
    border: Color(0xFF5CBF7A),
  ),
  ChildAccent(
    bg: Color(0xFFFFF0F3),
    fg: Color(0xFFC43D5C),
    border: Color(0xFFF07890),
  ),
];

int _hashKey(Object? value) {
  final s = value?.toString() ?? '';
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = (h * 31 + s.codeUnitAt(i)) & 0x7fffffff;
  }
  return h;
}

ChildAccent childAccentFor({Object? childId, String? nickname}) {
  final key = childId ?? nickname ?? '孩子';
  return _childPalette[_hashKey(key) % _childPalette.length];
}

String childInitial(String? nickname) {
  final name = (nickname ?? '').trim();
  if (name.isEmpty) return '孩';
  return String.fromCharCodes(name.runes.take(1));
}

enum ChildNameBadgeSize { sm, md, lg }

class ChildNameBadge extends StatelessWidget {
  const ChildNameBadge({
    super.key,
    required this.nickname,
    this.childId,
    this.size = ChildNameBadgeSize.md,
    this.showAvatar = true,
  });

  final String nickname;
  final Object? childId;
  final ChildNameBadgeSize size;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final accent = childAccentFor(childId: childId, nickname: nickname);
    final name = nickname.trim().isEmpty ? '同学' : nickname.trim();
    final (padV, padH, avatar, fontSize) = switch (size) {
      ChildNameBadgeSize.sm => (2.0, 8.0, 18.0, 13.0),
      ChildNameBadgeSize.md => (4.0, 10.0, 22.0, 15.0),
      ChildNameBadgeSize.lg => (6.0, 12.0, 28.0, 18.0),
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
        showAvatar ? 4 : padH,
        padV,
        padH,
        padV,
      ),
      decoration: BoxDecoration(
        color: accent.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAvatar) ...[
            Container(
              width: avatar,
              height: avatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.border,
                shape: BoxShape.circle,
              ),
              child: Text(
                childInitial(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize * 0.72,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            SizedBox(width: size == ChildNameBadgeSize.sm ? 4 : 6),
          ],
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent.fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
