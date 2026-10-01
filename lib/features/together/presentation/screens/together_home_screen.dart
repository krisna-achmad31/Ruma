import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/photo_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_tab_bar.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/entities/check_in_entity.dart';
import '../../domain/entities/conversation_card_entity.dart';
import '../viewmodels/together_viewmodel.dart';
import '../widgets/together_scope.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/l10n/app_locale.dart';

class TogetherHomeScreen extends StatelessWidget {
  const TogetherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const TogetherScope(child: _Content());
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TogetherViewModel>();
    return AppScaffold(
      tab: AppTab.kita,
      children: [
        LargeTitle(
          title: tr('Kita'),
          trailing: GlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(spacing: 6, children: [
              const Icon(AppIcons.flame, size: 16, color: AppColors.amber),
              Text(tr('{0} hari berdua', [vm.streak]), style: AppText.body(13, weight: FontWeight.w700)),
            ]),
          ),
        ),
        _Polaroid(vm: vm),
        _CheckInCard(vm: vm),
        _PartnerCheckIn(vm: vm),
        _DateNight(vm: vm),
        Row(spacing: 8, children: [
          ShortcutTile(label: tr('Obrolan'), icon: AppIcons.messagesSquare, tone: toneRose, onTap: () => context.push('/together/conversation-cards')),
          ShortcutTile(label: tr('Akhir bulan'), icon: AppIcons.calendarHeart, tone: toneLilac, onTap: () => context.push('/together/reflection')),
          ShortcutTile(label: tr('Jurnal'), icon: AppIcons.bookHeart, tone: toneAmber, onTap: () => context.push('/together/journal')),
        ]),
        _TimelinePreview(vm: vm),
        _TodayCard(vm: vm),
        const _TryToday(),
        _MonthReport(vm: vm),
      ],
    );
  }
}

class _Polaroid extends StatelessWidget {
  final TogetherViewModel vm;

  const _Polaroid({required this.vm});

  Future<void> _take(BuildContext context) async {
    final b64 = await PhotoService().pickBase64();
    if (b64 == null) return;
    await vm.saveDailyPhoto(b64);
    if (context.mounted) showSnack(context, tr('Foto hari ini tersimpan.'));
  }

  @override
  Widget build(BuildContext context) {
    final photo = vm.dailyPhoto;
    final isToday = photo != null && isSameDay(photo.takenAt, DateTime.now());
    return Center(
      child: Transform.rotate(
        angle: -0.026,
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Color(0x268E3F52), blurRadius: 28, offset: Offset(0, 12))],
          ),
          child: Column(
            spacing: 10,
            children: [
              GestureDetector(
                onTap: () => _take(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    color: const Color(0xFFF2E9E4),
                    child: photo == null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 6, children: [
                            const Icon(AppIcons.camera, size: 28, color: AppColors.faint),
                            Text(tr('Foto kalian hari ini'), style: AppText.body(12, color: AppColors.muted)),
                          ])
                        : Image.memory(base64Decode(photo.base64), fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                      Text(isToday || photo == null ? tr('Kita, hari ini') : tr('Kita, terakhir kali'), style: AppText.body(14, weight: FontWeight.w700)),
                      if (photo != null)
                        Text(
                          tr('Difoto {0} · {1}', [photo.byName.split(' ').first, isToday ? '${photo.takenAt.hour.toString().padLeft(2, '0')}.${photo.takenAt.minute.toString().padLeft(2, '0')}' : formatShortDate(photo.takenAt)]),
                          style: AppText.body(11, color: AppColors.muted),
                        ),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => _take(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: AppColors.roseSoft, shape: BoxShape.circle),
                      child: const Icon(AppIcons.camera, size: 17, color: AppColors.rose),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInCard extends StatefulWidget {
  final TogetherViewModel vm;

  const _CheckInCard({required this.vm});

  @override
  State<_CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<_CheckInCard> {
  late final TextEditingController _need = TextEditingController(text: widget.vm.myCheckInToday?.need ?? '');
  bool _sending = false;

  @override
  void dispose() {
    _need.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final done = vm.myCheckInToday != null;
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
            Text(tr('CHECK-IN 2 MENIT'), style: AppText.eyebrow(AppColors.rose)),
            Text(done ? tr('Kamu sudah check-in hari ini') : tr('Gimana kamu hari ini?'), style: AppText.display(22)),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final sel = vm.draftMood == i;
              return GestureDetector(
                onTap: () => vm.setDraftMood(i),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.jadeSoft : const Color(0x0A15201D),
                    shape: BoxShape.circle,
                    border: sel ? Border.all(color: AppColors.jade, width: 2) : null,
                  ),
                  child: Text(CheckInEntity.moodEmojis[i], style: const TextStyle(fontSize: 24)),
                ),
              );
            }),
          ),
          Column(spacing: 8, children: [
            Row(children: [
              Expanded(child: Text(tr('Energi'), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted))),
              Text(tr('{0} dari 5', [vm.draftEnergy]), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.jade)),
            ]),
            Row(
              spacing: 6,
              children: List.generate(5, (i) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => vm.setDraftEnergy(i + 1),
                    child: Container(height: 10, decoration: BoxDecoration(color: i < vm.draftEnergy ? AppColors.jade : AppColors.track, borderRadius: BorderRadius.circular(5))),
                  ),
                );
              }),
            ),
          ]),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.hairline)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Satu hal yang kamu butuhkan'), style: AppText.body(12, weight: FontWeight.w600, color: AppColors.muted)),
              TextField(
                controller: _need,
                maxLines: 2,
                minLines: 1,
                style: AppText.body(15),
                decoration: InputDecoration(border: InputBorder.none, hintText: tr('Misalnya: makan malam tanpa HP'), hintStyle: AppText.body(15, color: AppColors.faint)),
              ),
            ]),
          ),
          PrimaryButton(
            label: done ? tr('Perbarui check-in') : tr('Kirim ke {0}', [vm.partnerName]),
            icon: AppIcons.send,
            height: 50,
            loading: _sending,
            onPressed: () async {
              setState(() => _sending = true);
              await vm.sendCheckIn(_need.text.trim());
              if (!context.mounted) return;
              setState(() => _sending = false);
              showSnack(context, tr('Check-in terkirim ke {0}.', [vm.partnerName]));
            },
          ),
        ],
      ),
    );
  }
}

class _PartnerCheckIn extends StatelessWidget {
  final TogetherViewModel vm;

  const _PartnerCheckIn({required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = vm.partnerLatestCheckIn;
    if (vm.partner == null) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(spacing: 14, children: [
        Avatar(name: vm.partnerName, color: AppColors.rose, size: 44),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
            Text(
              c == null ? tr('{0} belum check-in', [vm.partnerName]) : tr('{0} · {1} · energi {2}/5', [vm.partnerName, c.emoji, c.energy]),
              style: AppText.body(14, weight: FontWeight.w700),
            ),
            Text(
              c == null ? tr('Kabar dari {0} akan muncul di sini.', [vm.partnerName]) : (c.need.isEmpty ? tr(CheckInEntity.moodLabels[c.mood]) : '“${c.need}”'),
              style: AppText.body(13, color: AppColors.muted, height: 1.35),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () async {
            await vm.addJournalEntry(title: tr('Peluk jauh buat {0}', [vm.partnerName]), text: tr('Dikirim dari check-in harian.'), type: 'makasih');
            if (context.mounted) showSnack(context, tr('Pelukan terkirim.'));
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.roseSoft, shape: BoxShape.circle),
            child: const Icon(AppIcons.heart, size: 18, color: AppColors.rose),
          ),
        ),
      ]),
    );
  }
}

class _DateNight extends StatelessWidget {
  final TogetherViewModel vm;

  const _DateNight({required this.vm});

  @override
  Widget build(BuildContext context) {
    final d = vm.nextDateNight;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/urusan/calendar'),
      child: Row(spacing: 12, children: [
        const IconBox(icon: AppIcons.wine, color: AppColors.rose, background: AppColors.roseSoft, size: 42),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
            Text(d == null ? tr('Belum ada date night') : '${d.title} ${dayNamesId[d.date.weekday - 1]}, ${formatShortDate(d.date)}', style: AppText.body(15, weight: FontWeight.w700)),
            Text(d == null ? tr('Jadwalkan di kalender dengan kategori Berdua.') : tr('Tandai di kalender supaya urusan lain menyesuaikan.'), style: AppText.body(12, color: AppColors.muted)),
          ]),
        ),
        const Icon(AppIcons.chevronRight, size: 16, color: AppColors.faint),
      ]),
    );
  }
}

class _TimelinePreview extends StatelessWidget {
  final TogetherViewModel vm;

  const _TimelinePreview({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.loveTimeline.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionHeader(title: tr('Perjalanan kita'), action: tr('Lihat semua'), actionColor: AppColors.rose, onAction: () => context.push('/together/love-timeline')),
        if (items.isEmpty)
          GlassCard(child: EmptyNote(tr('Belum ada momen tercatat.'), icon: AppIcons.milestone))
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: items
                  .map((m) => Expanded(
                        child: GlassCard(
                          radius: 18,
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                            IconBox(icon: iconFor(m.icon), color: AppColors.rose, background: AppColors.roseSoft, size: 32),
                            Text(m.title, style: AppText.body(12, weight: FontWeight.w700, height: 1.25), maxLines: 3, overflow: TextOverflow.ellipsis),
                            Text(formatShortDate(m.date), style: AppText.body(11, color: AppColors.faint)),
                          ]),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final TogetherViewModel vm;

  const _TodayCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final card = vm.todayCard;
    if (card == null) return const SizedBox.shrink();
    final idx = vm.conversationCards.where((c) => c.category == card.category).toList().indexOf(card) + 1;
    final total = vm.conversationCards.where((c) => c.category == card.category).length;
    return HeroCard(
      colors: AppColors.roseGradient,
      onTap: () => context.push('/together/conversation-cards'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                tr('Obrolan malam ini · {0}', [tr(TogetherViewModel.cardCategoryLabels[card.category] ?? card.category)]),
                style: AppText.body(12, weight: FontWeight.w600, color: const Color(0xCCFFFFFF)),
              ),
            ),
            Text('$idx/$total', style: AppText.body(12, weight: FontWeight.w700, color: const Color(0xCCFFFFFF))),
          ]),
          Text(card.question, style: AppText.display(21, color: Colors.white, height: 1.25)),
          Row(spacing: 10, children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/together/conversation-cards'),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(21)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 6, children: [
                    const Icon(AppIcons.shuffle, size: 15, color: Colors.white),
                    Text(tr('Kartu lain'), style: AppText.body(13, weight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => saveAnswerSheet(context, vm, card),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 6, children: [
                    const Icon(AppIcons.bookmark, size: 15, color: AppColors.rose),
                    Text(tr('Simpan jawaban'), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.rose)),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _TryToday extends StatelessWidget {
  const _TryToday();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
        Text(tr('COBA HARI INI'), style: AppText.eyebrow(const Color(0x99FFFFFF))),
        Text(tr('“Rumah tenang bukan yang tanpa masalah, tapi yang masalahnya dibicarakan.”'), style: AppText.display(17, color: Colors.white, height: 1.3)),
        Text(tr('Tanya satu hal yang dia pikirkan minggu ini, lalu dengarkan sampai selesai.'), style: AppText.body(13, color: const Color(0xB3FFFFFF), height: 1.35)),
      ]),
    );
  }
}

class _MonthReport extends StatelessWidget {
  final TogetherViewModel vm;

  const _MonthReport({required this.vm});

  @override
  Widget build(BuildContext context) {
    final thanks = vm.journalEntries.where((j) => j.isThanks && j.date.month == DateTime.now().month).length;
    final checkins = vm.checkIns.where((c) => c.createdAt.month == DateTime.now().month).length;
    final pillars = [
      (tr('Urusan'), thanks >= 3 ? tr('Saling bantu') : tr('Mulai saling bantu'), AppIcons.listChecks, AppColors.jade, AppColors.jadeSoft),
      (tr('Uang'), tr('Lihat rekap'), AppIcons.wallet, AppColors.amber, AppColors.amberSoft),
      (tr('Kita'), checkins >= 20 ? tr('Hangat') : (checkins >= 8 ? tr('Terjaga') : tr('Perlu waktu')), AppIcons.heart, AppColors.rose, AppColors.roseSoft),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(children: [
            Expanded(child: Text(tr('Rapor rumah tangga {0}', [monthNamesId[DateTime.now().month - 1]]), style: AppText.body(15, weight: FontWeight.w700))),
            const PlusBadge(),
          ]),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: pillars
                  .map((p) => Expanded(
                        child: GestureDetector(
                          onTap: p.$1 == tr('Uang') ? () => context.push('/finance/report') : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: p.$5, borderRadius: BorderRadius.circular(16)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                              Icon(p.$3, size: 16, color: p.$4),
                              Text(p.$1, style: AppText.body(11, weight: FontWeight.w600, color: AppColors.muted)),
                              Text(p.$2, style: AppText.body(14, weight: FontWeight.w700, color: p.$4)),
                            ]),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> saveAnswerSheet(BuildContext context, TogetherViewModel vm, ConversationCardEntity card) async {
  final text = await showTextSheet(context, title: tr('Jawaban kalian'), hint: tr('Catat kesimpulan obrolan kalian'), confirmLabel: tr('Simpan jawaban'));
  if (text == null) return;
  await vm.saveCardAnswer(card, text);
  if (context.mounted) showSnack(context, tr('Jawaban tersimpan.'));
}
