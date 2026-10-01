import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../viewmodels/together_viewmodel.dart';
import '../widgets/together_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

/// Ngobrol akhir bulan: empat pertanyaan, dibuka tanggal 25 sampai akhir bulan.
/// Jawaban pasangan baru terbuka setelah kamu mengisi, supaya dibaca bareng.
class ReflectionScreen extends StatelessWidget {
  const ReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) => const TogetherScope(child: _Content());
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(TogetherViewModel vm) {
    if (_seeded || vm.currentReflection == null) return;
    final answers = vm.myAnswers;
    for (int i = 0; i < _controllers.length && i < answers.length; i++) {
      _controllers[i].text = answers[i] ?? '';
    }
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TogetherViewModel>();
    _seed(vm);
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final questions = vm.reflectionQuestions;
    final showPartner = vm.iCompleted && vm.partnerCompleted;

    return AppScaffold(
      bottom: vm.reflectionOpen
          ? PrimaryButton(
              label: vm.iCompleted ? tr('Perbarui jawaban') : tr('Simpan & baca bareng'),
              icon: AppIcons.bookOpenCheck,
              loading: _saving,
              onPressed: () async {
                setState(() => _saving = true);
                await vm.saveReflectionAnswers(_controllers.map((c) => c.text.trim().isEmpty ? null : c.text.trim()).toList());
                if (!context.mounted) return;
                setState(() => _saving = false);
                showSnack(context, vm.partnerCompleted ? tr('Tersimpan. Jawaban {0} sudah terbuka.', [vm.partnerName]) : tr('Tersimpan. Tunggu {0} mengisi, lalu baca bareng.', [vm.partnerName]));
              },
            )
          : null,
      children: [
        AppNavBar(title: tr('Ngobrol akhir bulan'), actionIcon: AppIcons.history, onAction: () => context.push('/together/reflection/history')),
        PastelHero(
          tone: PastelTone.mint,
          object: 'calendar',
          objectSize: 104,
          objectRotation: -8,
          label: tr('Ngobrol akhir bulan'),
          head: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Text(monthNamesId[now.month - 1], style: AppText.display(34, letterSpacing: -1, height: 1)),
            Text(
              vm.reflectionOpen ? tr('Dibuka 25 sampai {0} {1}. Jawab, lalu baca bareng.', [lastDay, shortMonthNamesId[now.month - 1]]) : tr('Dibuka tanggal 25'),
              style: AppText.body(13, color: AppColors.muted, height: 1.4),
            ),
          ]),
        ),
        if (vm.partner != null)
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(spacing: 12, children: [
              Avatar(name: vm.partnerName, color: AppColors.rose, size: 36),
              Expanded(
                child: Text(
                  vm.partnerCompleted
                      ? (vm.iCompleted ? tr('Kalian berdua sudah mengisi. Baca jawaban {0} di bawah, lalu obrolkan.', [vm.partnerName]) : tr('{0} sudah mengisi. Jawabannya terbuka setelah kamu selesai, biar kalian baca bareng.', [vm.partnerName]))
                      : tr('{0} belum mengisi. Kamu bisa mulai duluan.', [vm.partnerName]),
                  style: AppText.body(13, height: 1.35),
                ),
              ),
            ]),
          ),
        if (!vm.reflectionOpen)
          InfoBanner(icon: AppIcons.lock, color: AppColors.rose, background: AppColors.roseSoft, text: tr('Pertanyaan bulan ini bisa dijawab mulai tanggal 25.')),
        ...List.generate(questions.length, (i) {
          final filled = _controllers[i].text.trim().isNotEmpty;
          final partnerAnswer = showPartner && i < vm.partnerAnswers.length ? vm.partnerAnswers[i] : null;
          return GlassCard(
            borderColor: !filled && vm.reflectionOpen ? AppColors.rose : null,
            borderWidth: !filled && vm.reflectionOpen ? 1.5 : 1,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: filled ? AppColors.jade : AppColors.roseSoft, shape: BoxShape.circle),
                    child: filled
                        ? const Icon(AppIcons.check, size: 13, color: Colors.white)
                        : Text('${i + 1}', style: AppText.body(12, weight: FontWeight.w700, color: AppColors.rose)),
                  ),
                  Expanded(child: Text(questions[i], style: AppText.body(14, weight: FontWeight.w700))),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: filled ? AppColors.fieldFill : const Color(0xCCFFFFFF), borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _controllers[i],
                    enabled: vm.reflectionOpen,
                    maxLines: null,
                    style: AppText.body(14, height: 1.4),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(border: InputBorder.none, hintText: tr('Tulis jawabanmu…'), hintStyle: AppText.body(14, color: AppColors.faint)),
                  ),
                ),
                if (partnerAnswer != null && partnerAnswer.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(14)),
                    child: Text('${vm.partnerName}: $partnerAnswer', style: AppText.body(13, height: 1.4)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
