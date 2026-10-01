import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/family_scope.dart';
import '../../../../core/widgets/pastel_hero.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../life_stage/domain/entities/family_stage.dart';
import '../../../life_stage/presentation/viewmodels/life_stage_viewmodel.dart';
import '../../../life_stage/presentation/widgets/life_stage_scope.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

final _weatherRepository = WeatherRepositoryImpl();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyScope<HomeViewModel>(
      create: (user) => HomeViewModel(
        homeRepository: buildHomeRepository(),
        taskRepository: buildTaskRepository(),
        togetherRepository: buildTogetherRepository(),
        financeRepository: buildFinanceRepository(),
        settingsRepository: buildSettingsRepository(),
        weatherRepository: _weatherRepository,
        familyId: user.familyId,
        uid: user.uid,
        userName: user.name,
      ),
      child: const LifeStageScope(child: _HomeContent()),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final now = DateTime.now();
    final city = vm.family?.location ?? '';
    final today = [formatLongDate(now), if (city.isNotEmpty) city, if (vm.weather != null) vm.weather!.label].join(', ');

    return AppScaffold(
      tab: AppTab.today,
      gap: 20,
      children: [
        LargeTitle(
          title: tr('Hari ini'),
          subtitle: '${greetingFor(now)}, ${vm.firstName}. $today',
          subtitleAbove: true,
          trailing: Row(
            spacing: 8,
            children: [
              GlassCircleButton(icon: AppIcons.search, size: 44, onTap: () => context.push('/search')),
              _BellButton(unread: vm.unreadCount > 0),
            ],
          ),
        ),
        _SafeToSpendHero(vm: vm),
        const _StageSpotlight(),
        _PartnerCard(vm: vm),
        _Priorities(vm: vm),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  final bool unread;

  const _BellButton({required this.unread});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.glass, shape: BoxShape.circle, border: Border.all(color: AppColors.glassEdge)),
              child: const Object3D('bell', size: 26),
            ),
            if (unread)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: AppColors.amber, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SafeToSpendHero extends StatelessWidget {
  final HomeViewModel vm;

  const _SafeToSpendHero({required this.vm});

  @override
  Widget build(BuildContext context) {
    final hasBudget = vm.budgetTotal > 0;
    return PastelHero(
      tone: PastelTone.jade,
      object: 'money_bag',
      objectSize: 118,
      objectRotation: -10,
      label: tr('Aman dipakai hari ini'),
      onTap: () => context.go('/finance'),
      head: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          HeroNumber(hasBudget ? formatRupiah(vm.safeToSpendToday) : tr('Rp0'), size: 44, color: Colors.white),
          HeroBar(value: vm.budgetRemainingFraction, tone: PastelTone.jade),
          Text(
            hasBudget
                ? tr('Sisa {0} untuk {1} hari ke gajian', [formatRupiahShort(vm.budgetRemaining), vm.daysToPayday])
                : tr('Buat amplop dulu supaya angka ini bisa dihitung.'),
            style: AppText.body(12, color: const Color(0xB3FFFFFF)),
          ),
        ],
      ),
      body: const _QuickAdd(),
    );
  }
}

//// Sorotan fase hidup: rencana yang cocok dengan fase pilihan keluarga, rencana lain yang berjalan,
/// atau ajakan memulai rencana yang cocok.
class _StageSpotlight extends StatelessWidget {
  const _StageSpotlight();

  static const _allocationColors = [AppColors.jade, AppColors.sky, AppColors.rose, AppColors.amber, AppColors.butter];
  static const _kinds = ['wedding', 'baby', 'lebaran'];

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeStageViewModel>();
    final stage = context.select<HomeViewModel, String>((vm) => vm.family?.lifeStage ?? '');
    bool active(String k) => switch (k) { 'wedding' => life.wedding != null, 'baby' => life.baby != null, _ => life.lebaran != null };

    final preferred = FamilyStage.planFor(stage);
    final kind = active(preferred) ? preferred : _kinds.firstWhere(active, orElse: () => preferred);
    final hero = active(kind) ? _activeHero(context, life, kind) : _promoHero(context, kind);
    final others = _kinds.where((k) => k != kind).map(_shortcut).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        hero,
        Row(
          spacing: 10,
          children: [
            for (final o in others)
              Expanded(
                child: GlassCard(
                  onTap: () => context.push(o.$4),
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    spacing: 8,
                    children: [
                      Object3D(o.$1, size: 30),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.$2, style: AppText.body(13, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(o.$3, style: AppText.body(10, color: AppColors.faint), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static (String, String, String, String) _shortcut(String kind) => switch (kind) {
        'wedding' => ('ring', tr('Siap nikah'), tr('Anggaran & vendor'), '/life/wedding'),
        'baby' => ('baby_bottle', tr('Menyambut bayi'), tr('Persalinan & jaga malam'), '/life/baby'),
        _ => ('crescent_moon', tr('Lebaran & THR'), tr('Rencana THR & mudik'), '/life/lebaran'),
      };

  Widget _activeHero(BuildContext context, LifeStageViewModel life, String kind) {
    switch (kind) {
      case 'wedding':
        final w = life.wedding!;
        return _countdownHero(
          context,
          tone: PastelTone.rose,
          object: 'ring',
          label: tr('Fase kalian: siap nikah'),
          number: '${life.daysUntil(w.weddingDate).clamp(0, 9999)}',
          caption: tr('hari lagi ke akad. {0} dari {1} persiapan beres.', [w.prepDone, w.prep.length]),
          progress: w.prep.isEmpty ? null : w.prepDone / w.prep.length,
          cta: tr('Buka persiapan nikah'),
          route: '/life/wedding',
        );
      case 'baby':
        final b = life.baby!;
        final week = b.weekOf(DateTime.now());
        return _countdownHero(
          context,
          tone: PastelTone.sky,
          object: 'baby_bottle',
          label: tr('Fase kalian: menyambut bayi'),
          number: '$week',
          caption: tr('minggu. Perkiraan lahir {0}.', [formatFullDate(b.dueDate)]),
          progress: week / 40,
          cta: tr('Buka rencana bayi'),
          route: '/life/baby',
        );
      default:
        final l = life.lebaran!;
        final total = l.allocatedTotal;
        return PastelHero(
          tone: PastelTone.butter,
          object: 'crescent_moon',
          label: tr('Fase kalian: Lebaran'),
          plus: true,
          onTap: () => context.push('/life/lebaran'),
          head: _countdownHead(
            PastelTone.butter,
            '${life.daysUntil(l.eidDate).clamp(0, 9999)}',
            tr('hari lagi. Sisihkan {0} per bulan mulai sekarang, biar THR nggak habis sebelum mudik.', [formatRupiahShort(life.lebaranMonthlySetAside(l))]),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      spacing: 3,
                      children: [
                        for (int i = 0; i < l.allocations.length; i++)
                          if (l.allocations[i].total > 0)
                            Expanded(
                              flex: (l.allocations[i].total / total * 1000).round().clamp(1, 1000),
                              child: ColoredBox(color: _allocationColors[i % _allocationColors.length]),
                            ),
                      ],
                    ),
                  ),
                ),
              HeroButton(label: tr('Lanjutkan rencana Lebaran'), onTap: () => context.push('/life/lebaran')),
            ],
          ),
        );
    }
  }

  Widget _promoHero(BuildContext context, String kind) {
    final (tone, object, title, body, route) = switch (kind) {
      'wedding' => (PastelTone.rose, 'ring', tr('Siapkan pernikahan berdua'), tr('Anggaran nikah, jadwal bayar vendor, dan obrolan penting sebelum tinggal serumah.'), '/life/wedding'),
      'baby' => (PastelTone.sky, 'baby_bottle', tr('Siapkan kedatangan si kecil'), tr('Anggaran persalinan, tas persalinan, dan gantian jaga malam.'), '/life/baby'),
      _ => (PastelTone.butter, 'crescent_moon', tr('Siapkan Lebaran dari sekarang'), tr('Bagi THR ke zakat, mudik, salam tempel, dan tabungan sebelum habis duluan.'), '/life/lebaran'),
    };
    return PastelHero(
      tone: tone,
      object: object,
      label: tr('Fase hidup'),
      plus: true,
      onTap: () => context.push(route),
      head: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(title, style: AppText.display(24, letterSpacing: -0.6, height: 1.1)),
          Text(body, style: AppText.body(13, color: AppColors.muted, height: 1.4)),
        ],
      ),
      body: Row(
        spacing: 12,
        children: [
          HeroButton(label: tr('Mulai rencana'), onTap: () => context.push(route)),
          Text(tr('Gratis 14 hari'), style: AppText.body(12, weight: FontWeight.w600, color: tone.label)),
        ],
      ),
    );
  }

  static Widget _countdownHead(PastelTone tone, String number, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        HeroNumber(number, size: 64, color: tone.text),
        Text(caption, style: AppText.body(13, color: tone.subtext, height: 1.4)),
      ],
    );
  }

  Widget _countdownHero(
    BuildContext context, {
    required PastelTone tone,
    required String object,
    required String label,
    required String number,
    required String caption,
    required String cta,
    required String route,
    double? progress,
  }) {
    return PastelHero(
      tone: tone,
      object: object,
      label: label,
      plus: true,
      onTap: () => context.push(route),
      head: _countdownHead(tone, number, caption),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          if (progress != null) HeroBar(value: progress, tone: tone),
          HeroButton(label: cta, onTap: () => context.push(route)),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final HomeViewModel vm;

  const _PartnerCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = vm.partnerCheckIn;
    if (vm.partner == null) {
      return GlassCard(
        onTap: () => context.push('/invite'),
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 14,
          children: [
            const IconBox(icon: AppIcons.userPlus, color: AppColors.rose, background: AppColors.roseSoft, size: 48),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(tr('Ajak pasanganmu'), style: AppText.body(16, weight: FontWeight.w700)),
                  Text(tr('Rumah tangga lebih ringan kalau dipikul berdua.'), style: AppText.body(13, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRight, size: 16, color: AppColors.faint),
          ],
        ),
      );
    }
    final thanks = vm.latestThanksFromPartner;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/together'),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(16)),
                  child: c == null ? const Object3D('red_heart', size: 28) : Image.asset(AppIcons.moodAsset(c.mood), width: 32, height: 32),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        c == null ? tr('{0} belum check-in', [vm.partnerName]) : tr('{0} {1}, energi {2} dari 5', [vm.partnerName, _moodPhrase(c.mood), c.energy]),
                        style: AppText.body(14, weight: FontWeight.w700),
                      ),
                      Text(
                        c == null ? tr('Tanya kabarnya sebentar, dua menit cukup.') : (c.need.isEmpty ? tr('Belum menulis kebutuhan hari ini.') : '“${c.need}”'),
                        style: AppText.body(12, color: AppColors.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (vm.partnerOpenLoad >= 3)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(16)),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Text(
                      tr('Minggu ini {0} pegang {1} urusan, termasuk yang nggak kelihatan.', [vm.partnerName, vm.partnerOpenLoad]),
                      style: AppText.body(12, height: 1.35),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/urusan'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
                      child: Text(tr('Bantu satu'), style: AppText.body(12, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          if (thanks != null)
            Row(
              spacing: 8,
              children: [
                const Object3D('red_heart', size: 16),
                Expanded(child: Text(tr('{0} bilang {1}', [thanks.authorName.split(' ').first, thanks.title.toLowerCase()]), style: AppText.body(12, color: AppColors.muted))),
              ],
            ),
        ],
      ),
    );
  }

  static String _moodPhrase(int mood) => [tr('lagi berat'), tr('lagi capek'), tr('biasa aja'), tr('lagi baik'), tr('lagi senang')][mood.clamp(0, 4)];
}

class _Priorities extends StatelessWidget {
  final HomeViewModel vm;

  const _Priorities({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.priorities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionHeader(
          title: tr('Perlu dipikirkan'),
          trailing: Row(
            spacing: 8,
            children: [
              Pill(tr('{0}/{1} beres', [vm.weekDone, vm.weekTotal])),
              GestureDetector(
                onTap: () => context.go('/urusan?add=1'),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                  child: const Icon(AppIcons.plus, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        ListCard(
          children: items.isEmpty
              ? [EmptyNote(tr('Belum ada urusan minggu ini. Tambah dengan tombol +.'))]
              : items.map((t) => _PriorityRow(task: t, vm: vm)).toList(),
        ),
      ],
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final TaskEntity task;
  final HomeViewModel vm;

  const _PriorityRow({required this.task, required this.vm});

  @override
  Widget build(BuildContext context) {
    final label = task.dueDate == null ? '' : relativeDayLabel(task.dueDate!);
    final urgent = label == tr('Hari ini') || label == tr('Kemarin');
    final color = urgent ? AppColors.amber : AppColors.faint;
    return ListRow(
      icon: iconFor(task.icon),
      iconColor: AppColors.muted,
      iconBackground: AppColors.fieldFill,
      title: task.title,
      subtitle: vm.roleLine(task),
      trailingText: label,
      trailingColor: color,
      onTap: () => vm.toggleTask(task),
    );
  }
}

class _QuickAdd extends StatefulWidget {
  const _QuickAdd();

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    final message = await context.read<HomeViewModel>().quickAdd(text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (message.endsWith('tercatat.')) _controller.clear();
    showSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
      decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(26)),
      child: Row(
        spacing: 10,
        children: [
          const Object3D('sparkles', size: 22),
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppText.body(14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: tr('Catat: sayur 45rb pakai gopay'),
                hintStyle: AppText.body(14, color: AppColors.faint),
              ),
            ),
          ),
          GestureDetector(
            onTap: _busy ? null : _submit,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
              child: _busy
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(AppIcons.plus, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
