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
import '../../../../core/widgets/pastel_hero.dart';
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
      gap: 20,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                Text(tr('Kita'), style: AppText.largeTitle),
                Row(spacing: 6, children: [
                  const Object3D('fire', size: 18),
                  Flexible(child: Text(tr('{0} hari check-in berturut-turut', [vm.streak]), style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted))),
                ]),
              ]),
            ),
            _PhotoTile(vm: vm),
          ],
        ),
        _CheckInCard(vm: vm),
        _PartnerCheckIn(vm: vm),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
            Expanded(child: _DateNight(vm: vm)),
            Expanded(
              child: _SceneCard(
                tone: PastelTone.mint,
                object: 'calendar',
                eyebrow: tr('Tiap akhir bulan'),
                title: tr('Ngobrol akhir bulan'),
                note: tr('Jawab berdua, baca bareng.'),
                onTap: () => context.push('/together/reflection'),
              ),
            ),
          ]),
        ),
        _TodayCard(vm: vm),
        Row(spacing: 8, children: [
          ShortcutTile(label: tr('Obrolan'), icon: AppIcons.messagesSquare, tone: toneLilac, onTap: () => context.push('/together/conversation-cards')),
          ShortcutTile(label: tr('Jurnal'), icon: AppIcons.bookHeart, tone: toneButter, onTap: () => context.push('/together/journal')),
          ShortcutTile(label: tr('Perjalanan'), icon: AppIcons.milestone, tone: toneRose, onTap: () => context.push('/together/love-timeline')),
        ]),
        _TimelinePreview(vm: vm),
        _MonthReport(vm: vm),
      ],
    );
  }
}

/// Foto harian "Kita, hari ini" dalam bentuk ubin kecil di header. Ketuk untuk memotret.
class _PhotoTile extends StatelessWidget {
  final TogetherViewModel vm;

  const _PhotoTile({required this.vm});

  Future<void> _take(BuildContext context) async {
    final b64 = await PhotoService().pickBase64();
    if (b64 == null) return;
    await vm.saveDailyPhoto(b64);
    if (context.mounted) showSnack(context, tr('Foto hari ini tersimpan.'));
  }

  @override
  Widget build(BuildContext context) {
    final photo = vm.dailyPhoto;
    return GestureDetector(
      onTap: () => _take(context),
      child: Transform.rotate(
        angle: -0.07,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.roseSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Color(0x268E3F52), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: photo == null
                ? const Center(child: Object3D('camera', size: 30))
                : Image.memory(base64Decode(photo.base64), fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
      ),
    );
  }
}

/// Kartu pastel tinggi dengan objek 3D di pojok, dipakai berpasangan.
class _SceneCard extends StatelessWidget {
  final PastelTone tone;
  final String object;
  final String eyebrow;
  final String title;
  final String note;
  final VoidCallback onTap;

  const _SceneCard({required this.tone, required this.object, required this.eyebrow, required this.title, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 176),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tone.colors),
          border: Border.all(color: const Color(0xB3FFFFFF)),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(children: [
            Positioned(right: -8, top: -6, child: Object3D(object, size: 82, rotation: 8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, spacing: 2, children: [
                Text(eyebrow, style: AppText.body(11, weight: FontWeight.w700, color: tone.label)),
                Text(title, style: AppText.display(18, height: 1.1)),
                Text(note, style: AppText.body(11, color: AppColors.muted, height: 1.3)),
              ]),
            ),
          ]),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xF0FFFFFF), Color(0xE6FADFE6)]),
        border: Border.all(color: const Color(0xB3FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x22B9536B), blurRadius: 28, offset: Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(children: [
            Expanded(child: Text(done ? tr('Kamu sudah check-in hari ini') : tr('Gimana kamu hari ini?'), style: AppText.display(20, letterSpacing: -0.3))),
            Pill(tr('2 menit'), icon: AppIcons.timer, color: AppColors.rose, background: const Color(0xCCFFFFFF)),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final sel = vm.draftMood == i;
              return GestureDetector(
                onTap: () => vm.setDraftMood(i),
                child: Column(spacing: 4, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? Colors.white : const Color(0x80FFFFFF),
                      shape: BoxShape.circle,
                      border: sel ? Border.all(color: AppColors.rose, width: 2) : null,
                      boxShadow: sel ? const [BoxShadow(color: Color(0x33B9536B), blurRadius: 14, offset: Offset(0, 6))] : null,
                    ),
                    child: Image.asset(AppIcons.moodAsset(i), width: sel ? 40 : 34, height: sel ? 40 : 34),
                  ),
                  Text(
                    [tr('Berat'), tr('Capek'), tr('Biasa'), tr('Oke'), tr('Senang')][i],
                    style: AppText.body(11, weight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.rose : AppColors.faint),
                  ),
                ]),
              );
            }),
          ),
          Column(spacing: 8, children: [
            Row(children: [
              Expanded(child: Text(tr('Energi'), style: AppText.body(13, weight: FontWeight.w600))),
              Text(tr('{0} dari 5', [vm.draftEnergy]), style: AppText.body(13, weight: FontWeight.w700, color: AppColors.rose)),
            ]),
            Row(
              spacing: 6,
              children: List.generate(5, (i) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => vm.setDraftEnergy(i + 1),
                    child: Container(height: 10, decoration: BoxDecoration(color: i < vm.draftEnergy ? AppColors.rose : const Color(0x26B9536B), borderRadius: BorderRadius.circular(5))),
                  ),
                );
              }),
            ),
          ]),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            decoration: BoxDecoration(color: const Color(0xB3FFFFFF), borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Satu hal yang kamu butuhkan'), style: AppText.body(11, weight: FontWeight.w600, color: AppColors.faint)),
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
            color: AppColors.rose,
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
      padding: const EdgeInsets.all(14),
      child: Row(spacing: 12, children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.roseSoft, borderRadius: BorderRadius.circular(15)),
          child: c == null ? Avatar(name: vm.partnerName, color: AppColors.rose, size: 34) : Image.asset(AppIcons.moodAsset(c.mood), width: 32, height: 32),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 3, children: [
            Text(
              c == null ? tr('{0} belum check-in', [vm.partnerName]) : tr('{0}, {1}, energi {2} dari 5', [vm.partnerName, tr(CheckInEntity.moodLabels[c.mood]).toLowerCase(), c.energy]),
              style: AppText.body(14, weight: FontWeight.w700),
            ),
            Text(
              c == null ? tr('Kabar dari {0} akan muncul di sini.', [vm.partnerName]) : (c.need.isEmpty ? tr(CheckInEntity.moodLabels[c.mood]) : '“${c.need}”'),
              style: AppText.body(12, color: AppColors.muted, height: 1.35),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () async {
            await vm.addJournalEntry(title: tr('Peluk jauh buat {0}', [vm.partnerName]), text: tr('Dikirim dari check-in harian.'), type: 'makasih');
            if (context.mounted) showSnack(context, tr('Pelukan terkirim.'));
          },
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.roseSoft, shape: BoxShape.circle),
            child: const Object3D('red_heart', size: 22),
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
    return _SceneCard(
      tone: PastelTone.lilac,
      object: 'wine_glass',
      eyebrow: d == null ? tr('Belum dijadwalkan') : '${dayNamesId[d.date.weekday - 1]}, ${formatShortDate(d.date)}',
      title: d == null ? tr('Date night') : d.title,
      note: d == null ? tr('Jadwalkan di kalender.') : tr('Tandai supaya urusan lain menyesuaikan.'),
      onTap: () => context.push('/urusan/calendar'),
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
    return PastelHero(
      tone: PastelTone.night,
      object: 'speech_balloon',
      objectSize: 84,
      reserve: 70,
      label: tr('Obrolan malam ini, {0}  {1}/{2}', [tr(TogetherViewModel.cardCategoryLabels[card.category] ?? card.category).toLowerCase(), idx, total]),
      onTap: () => context.push('/together/conversation-cards'),
      head: Text(card.question, style: AppText.display(21, color: Colors.white, height: 1.25)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(spacing: 10, children: [
            Expanded(
              child: GestureDetector(
                onTap: () => saveAnswerSheet(context, vm, card),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23)),
                  alignment: Alignment.center,
                  child: Text(tr('Simpan jawaban'), style: AppText.body(14, weight: FontWeight.w700)),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/together/conversation-cards'),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(23)),
                child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                  const Icon(AppIcons.shuffle, size: 15, color: Colors.white),
                  Text(tr('Kartu lain'), style: AppText.body(14, weight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            const Object3D('light_bulb', size: 18),
            Expanded(
              child: Text(
                tr('Coba hari ini: tanya satu hal yang dia pikirkan minggu ini, lalu dengarkan sampai selesai.'),
                style: AppText.body(12, color: const Color(0xA6FFFFFF), height: 1.4),
              ),
            ),
          ]),
        ],
      ),
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
                              IconBox(icon: p.$3, size: 26, color: p.$4, background: Colors.transparent),
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
