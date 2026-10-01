import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/together_viewmodel.dart';
import '../widgets/together_scope.dart';
import 'together_home_screen.dart' show saveAnswerSheet;
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class ConversationCardsScreen extends StatelessWidget {
  const ConversationCardsScreen({super.key});

  @override
  Widget build(BuildContext context) => const TogetherScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TogetherViewModel>();
    final categories = vm.cardCategories;
    final card = vm.currentCard;
    final cards = vm.filteredCards;
    final last = vm.lastAnswered;

    return AppScaffold(
      tab: AppTab.kita,
      children: [
        AppNavBar(title: tr('Obrolan')),
        SegmentedControl(
          labels: categories.map((c) => tr(TogetherViewModel.cardCategoryLabels[c] ?? c)).toList(),
          selected: categories.indexOf(vm.selectedCardCategory).clamp(0, categories.length - 1),
          selectedTextColor: AppColors.rose,
          onChanged: (i) => vm.selectCardCategory(categories[i]),
        ),
        SizedBox(
          height: 330,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 26,
                right: 26,
                top: 0,
                height: 300,
                child: Transform.rotate(angle: 5 * math.pi / 180, child: const GlassCard(radius: 28, color: Color(0x66FFFFFF), child: SizedBox.expand())),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 10,
                height: 300,
                child: Transform.rotate(angle: -3 * math.pi / 180, child: const GlassCard(radius: 28, color: Color(0x99FFFFFF), child: SizedBox.expand())),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 20,
                height: 300,
                child: HeroCard(
                  colors: AppColors.roseGradient,
                  padding: const EdgeInsets.all(24),
                  child: card == null
                      ? Center(child: Text(tr('Belum ada kartu di kategori ini.'), style: AppText.body(15, color: Colors.white)))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Expanded(child: Text(tr(TogetherViewModel.cardCategoryDecks[card.category] ?? card.category.toUpperCase()), style: AppText.eyebrow(const Color(0xCCFFFFFF)))),
                              Text('${vm.currentCardIndex % math.max(cards.length, 1) + 1} / ${cards.length}', style: AppText.body(12, weight: FontWeight.w700, color: const Color(0xCCFFFFFF))),
                            ]),
                            Text(card.question, style: AppText.display(22, color: Colors.white, height: 1.25)),
                            if (card.instruction.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(14)),
                                child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                                  const Icon(AppIcons.timer, size: 14, color: Colors.white),
                                  Flexible(child: Text(card.instruction, style: AppText.body(12, weight: FontWeight.w600, color: Colors.white))),
                                ]),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        Row(spacing: 10, children: [
          Expanded(child: PrimaryButton(label: tr('Ganti'), icon: AppIcons.shuffle, secondary: true, height: 50, onPressed: vm.nextConversationCard)),
          Expanded(
            child: PrimaryButton(
              label: tr('Simpan jawaban'),
              icon: AppIcons.notebookPen,
              height: 50,
              onPressed: card == null ? null : () => saveAnswerSheet(context, vm, card),
            ),
          ),
        ]),
        if (last != null)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
              Text(tr('Jawaban terakhir'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.muted)),
              Text('“${last.question}”', style: AppText.body(14, weight: FontWeight.w600)),
              Text('${last.lastAnswer} · ${formatShortDate(last.answeredAt!)}', style: AppText.body(12, color: AppColors.muted)),
            ]),
          ),
      ],
    );
  }
}
