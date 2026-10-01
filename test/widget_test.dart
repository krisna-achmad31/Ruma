import 'package:flutter_test/flutter_test.dart';
import 'package:seruma/core/utils/format.dart';
import 'package:seruma/features/finance/domain/entities/category_entity.dart';
import 'package:seruma/features/finance/domain/entities/wallet_entity.dart';
import 'package:seruma/features/finance/domain/usecases/parse_quick_entry.dart';

void main() {
  const wallets = [
    WalletEntity(id: 'w_bca', name: 'BCA', subtitle: '', type: 'bank', balance: 0, isDefault: true, order: 1),
    WalletEntity(id: 'w_gopay', name: 'GoPay', subtitle: '', type: 'ewallet', balance: 0, isDefault: false, order: 2),
  ];
  const categories = [
    CategoryEntity(id: 'c_makan', name: 'Makan & Harian', icon: 'makan', color: '#000000', budgetAmount: 0, spentAmount: 0, walletId: '', order: 1, subCategories: []),
    CategoryEntity(id: 'c_rumah', name: 'Rumah & Tagihan', icon: 'rumah', color: '#000000', budgetAmount: 0, spentAmount: 0, walletId: '', order: 2, subCategories: []),
  ];
  final parse = ParseQuickEntry();

  group('ParseQuickEntry', () {
    test('membaca nominal, dompet, dan amplop dari kalimat', () {
      final e = parse('beli sayur 45rb pakai gopay', wallets: wallets, categories: categories)!;
      expect(e.amount, 45000);
      expect(e.walletId, 'w_gopay');
      expect(e.categoryId, 'c_makan');
      expect(e.isIncome, isFalse);
      expect(e.title.toLowerCase(), contains('sayur'));
    });

    test('mengenali juta dengan koma dan pemasukan', () {
      final e = parse('gaji 8,5jt bca', wallets: wallets, categories: categories)!;
      expect(e.amount, 8500000);
      expect(e.isIncome, isTrue);
      expect(e.categoryId, isNull);
    });

    test('memakai dompet utama kalau dompet tidak disebut', () {
      final e = parse('token listrik 203000', wallets: wallets, categories: categories)!;
      expect(e.amount, 203000);
      expect(e.walletId, 'w_bca');
      expect(e.categoryId, 'c_rumah');
    });

    test('mengembalikan null kalau tidak ada nominal', () {
      expect(parse('beli sayur', wallets: wallets, categories: categories), isNull);
    });
  });

  group('format', () {
    test('formatRupiah memakai titik ribuan', () {
      expect(formatRupiah(182000), 'Rp182.000');
      expect(formatRupiah(8500000, withSign: true), '+Rp8.500.000');
    });

    test('formatRupiahShort meringkas ke rb dan jt', () {
      expect(formatRupiahShort(640000), 'Rp640rb');
      expect(formatRupiahShort(2180000), 'Rp2,18 jt');
      expect(formatRupiahShort(4000000), 'Rp4 jt');
    });

    test('relativeDayLabel', () {
      final now = DateTime(2026, 9, 29);
      expect(relativeDayLabel(DateTime(2026, 9, 29), now: now), 'Hari ini');
      expect(relativeDayLabel(DateTime(2026, 9, 30), now: now), 'Besok');
      expect(relativeDayLabel(DateTime(2026, 10, 3), now: now), 'Sabtu');
    });
  });
}
