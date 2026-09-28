import 'package:flutter/material.dart';

import '../../widgets/app_scaffold_bg.dart';
import '../dictation/dictation_entry_card.dart';
import '../dictation/dictation_page.dart';
import '../oral/oral_entry_card.dart';
import '../oral/oral_page.dart';
import '../wrong_book/wrong_book_page.dart';
import '../wrong_book/wrong_entry_card.dart';

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
            const SizedBox(height: 12),
            OralEntryCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OralPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            WrongEntryCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WrongBookPage(),
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
