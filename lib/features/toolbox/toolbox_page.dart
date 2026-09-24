import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../dictation/dictation_entry_card.dart';
import '../dictation/dictation_page.dart';

class ToolboxPage extends StatelessWidget {
  const ToolboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工具箱')),
      body: AppScaffoldBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Text(
            //   '练习小工具放在这里，不占用今日打卡。',
            //   style: GoogleFonts.nunito(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w700,
            //     color: AppColors.inkMuted,
            //     height: 1.4,
            //   ),
            // ),
            const SizedBox(height: 14),
            DictationEntryCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DictationPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
