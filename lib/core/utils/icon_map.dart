import 'package:flutter/widgets.dart';

import '../constants/app_colors.dart';
import '../theme/app_icons.dart';

/// Pasangan warna ikon dan latar pastel.
typedef Tone = (Color, Color);

const Tone toneJade = (AppColors.jade, AppColors.jadeSoft);
const Tone toneAmber = (AppColors.amber, AppColors.amberSoft);
const Tone toneRose = (AppColors.rose, AppColors.roseSoft);
const Tone toneLilac = (AppColors.lilac, AppColors.lilacSoft);
const Tone toneSky = (AppColors.sky, AppColors.skySoft);
const Tone toneButter = (AppColors.butter, AppColors.butterSoft);

/// Warna pastel untuk amplop, ditebak dari kunci ikon atau namanya.
Tone toneForCategory(String icon, String name) {
  final k = '$icon ${name.toLowerCase()}';
  if (k.contains('makan') || k.contains('shopping_basket') || k.contains('belanja')) return toneAmber;
  if (k.contains('rumah') || k.contains('bolt') || k.contains('listrik') || k.contains('water') || k.contains('air') || k.contains('router') || k.contains('internet')) {
    return toneSky;
  }
  if (k.contains('transport') || k.contains('directions_car')) return toneLilac;
  if (k.contains('anak') || k.contains('school') || k.contains('sekolah')) return toneButter;
  if (k.contains('hiburan') || k.contains('subscriptions') || k.contains('langganan') || k.contains('jajan')) return toneRose;
  if (k.contains('credit_card') || k.contains('cicilan')) return toneRose;
  return toneJade;
}

/// Warna pastel untuk dompet berdasarkan jenisnya.
Tone toneForWalletType(String type) {
  switch (type) {
    case 'bank':
      return toneSky;
    case 'ewallet':
      return toneLilac;
    case 'cash':
      return toneJade;
    case 'savings':
      return toneButter;
    default:
      return toneJade;
  }
}

/// Memetakan kunci ikon yang disimpan di Firestore ke ikon Material Symbols Rounded.
/// Kunci lama (nama Material) tetap didukung supaya data yang sudah ada tidak rusak.
IconData iconFor(String key) {
  switch (key) {
    case 'bolt':
    case 'zap':
    case 'listrik':
      return AppIcons.zap;
    case 'water_drop':
    case 'droplets':
      return AppIcons.droplets;
    case 'school':
    case 'anak':
      return AppIcons.backpack;
    case 'shopping_basket':
    case 'makan':
      return AppIcons.utensils;
    case 'credit_card':
    case 'card':
      return AppIcons.creditCard;
    case 'directions_car':
    case 'transport':
      return AppIcons.bike;
    case 'router':
    case 'wifi':
      return AppIcons.wifi;
    case 'subscriptions':
    case 'hiburan':
      return AppIcons.popcorn;
    case 'rumah':
    case 'home':
    case 'house':
      return AppIcons.house;
    case 'kesehatan':
      return AppIcons.heartPulse;
    case 'favorite':
    case 'heart':
      return AppIcons.heart;
    case 'restaurant':
      return AppIcons.utensils;
    case 'diamond':
    case 'gem':
      return AppIcons.gem;
    case 'celebration':
      return AppIcons.partyPopper;
    case 'child_care':
    case 'baby':
      return AppIcons.baby;
    case 'flame':
      return AppIcons.flame;
    case 'piggy':
      return AppIcons.piggyBank;
    case 'plane':
      return AppIcons.plane;
    case 'shield':
      return AppIcons.shield;
    case 'graduation':
      return AppIcons.graduationCap;
    case 'air':
      return AppIcons.airVent;
    case 'phone':
      return AppIcons.smartphone;
    case 'bag':
      return AppIcons.shoppingBag;
    case 'coins':
      return AppIcons.coins;
    case 'sprout':
      return AppIcons.sprout;
    case 'build':
    case 'wrench':
      return AppIcons.wrench;
    case 'payments':
      return AppIcons.receipt;
    case 'savings':
      return AppIcons.piggyBank;
    case 'bell':
      return AppIcons.bell;
    case 'thanks':
      return AppIcons.heartHandshake;
    case 'calendar':
      return AppIcons.calendarHeart;
    case 'store':
      return AppIcons.store;
    case 'camera':
      return AppIcons.camera;
    case 'shirt':
      return AppIcons.shirt;
    default:
      return AppIcons.listChecks;
  }
}

IconData iconForWalletType(String type) {
  switch (type) {
    case 'cash':
      return AppIcons.banknote;
    case 'bank':
      return AppIcons.landmark;
    case 'ewallet':
      return AppIcons.smartphone;
    case 'savings':
      return AppIcons.piggyBank;
    default:
      return AppIcons.wallet;
  }
}

String walletTypeLabel(String type) {
  switch (type) {
    case 'cash':
      return 'Tunai';
    case 'bank':
      return 'Bank';
    case 'ewallet':
      return 'E-wallet';
    case 'savings':
      return 'Tabungan';
    default:
      return 'Dompet';
  }
}

/// Ikon untuk urusan, ditebak dari judulnya.
String guessTaskIcon(String title) {
  final t = title.toLowerCase();
  if (t.contains('listrik') || t.contains('pln') || t.contains('token')) return 'zap';
  if (t.contains('galon') || t.contains('air')) return 'droplets';
  if (t.contains('ac') || t.contains('servis')) return 'air';
  if (t.contains('jemput') || t.contains('sekolah') || t.contains('les')) return 'school';
  if (t.contains('belanja') || t.contains('beli')) return 'bag';
  if (t.contains('bayar') || t.contains('tagihan')) return 'payments';
  return 'list';
}
