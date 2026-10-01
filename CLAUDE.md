# CLAUDE.md, Ruma (aplikasi rumah tangga)

Panduan konteks untuk Claude Code saat bekerja di repo ini. Baca file ini di awal setiap sesi sebelum mulai coding.

## Ringkasan Proyek

Aplikasi rumah tangga untuk pasangan Gen Z dengan tiga pilar: **Urusan** (siapa ingat, siapa kerjakan, saling bantu), **Uang** (uang rumah digabung, amplop, cicilan), dan **Kita** (check-in harian, obrolan, perjalanan). Target rilis Play Store dengan langganan Plus "satu langganan untuk berdua", Indonesia dulu lalu global.

Proyek ini awalnya rekonstruksi seruma.app untuk pitch kerja sama, tapi sekarang berdiri sendiri. **Jangan bawa nama, logo, teks, warna khas, atau data dummy seruma.app** ke fitur baru. Nama brand diatur di satu tempat: `lib/core/constants/app_brand.dart`.

Prinsip produk yang wajib dijaga:
- Tanpa hitung-hitungan antarpasangan: tidak ada skor, persentase "kamu vs dia", atau label "punyaku/punyamu". Framing selalu saling bantu dan terima kasih.
- Uang rumah digabung (riset JCR 2023 Common Cents), dompet dikelompokkan per jenis, bukan per orang.
- Mulai dari Firebase gratis (Spark): tanpa Cloud Functions, tanpa Storage. Foto disimpan sebagai thumbnail base64 di Firestore, notifikasi dibuat dari aplikasi.

## Tech Stack

- Flutter (Android prioritas, iOS menyusul)
- State management: **Provider** (`ChangeNotifier` + `ChangeNotifierProvider`/`Consumer`), bukan BLoC/Cubit
- Arsitektur: **Clean Architecture** per feature (data / domain / presentation), pola **MVVM**
- Backend: **Firebase** Authentication dan Cloud Firestore
- Paket UI: `google_fonts` (Bricolage Grotesque untuk judul, Figtree untuk teks), `material_symbols_icons` (Material Symbols Rounded, dipetakan di `lib/core/theme/app_icons.dart`, pakai `AppIcons.xxx`, jangan panggil `Symbols` langsung)
- Paket lain: `home_widget` (widget layar utama Android), `image_picker`, `http` (cuaca Open-Meteo), `share_plus`, `local_auth`
- Android config: Kotlin DSL (`build.gradle.kts`, `settings.gradle.kts`), Gradle Wrapper 8.14, AGP 8.11.1, Kotlin 2.2.20, Java 11 compatibility, compileSdk 36, minSdk 24, NDK 29.0.13113456. **Jangan pakai Groovy DSL (`.gradle`).** `MainActivity` memakai `FlutterFragmentActivity` karena `local_auth`.

## Referensi Desain

Sumber kebenaran UI sekarang **`seruma.pen`** (pen.dev), gaya Apple Liquid Glass yang sederhana. Buka file itu di editor pen.dev supaya tool MCP pencil bisa membacanya. Baris frame di canvas:
- Baris atas: 00 Onboarding, 01 Hari ini, 02 Urusan, 03 Uang, 04 Kita, 05 Paywall
- B (Uang): Amplop, Detail Amplop, Catat Transaksi, Dompet, Pindah Saldo, Rekap, Cicilan & Paylater, Tabungan & Target, Utang & Aset
- C (Rumah): Kalender, Rumah Sehat, menu Rumah, Brankas terkunci/terbuka, Profil, Pengaturan
- D (Kita): Perjalanan Kita, Obrolan, Ngobrol Akhir Bulan, Riwayat, Jurnal Keluarga
- A (Akun): Masuk, Daftar, Undang Pasangan, Gabung Pakai Kode, Notifikasi, Cari & Catat Cepat
- E (Dialog): Ubah Anggaran, Pilih Dompet, Tulis Cerita, Konfirmasi Keluar, Setel PIN
- F (Fitur baru): Siap Nikah, Menyambut Bayi, Widget Layar Utama, Lebaran & THR, Belanja

`design-reference/Seruma Mobile Spec.dc.html` hanya arsip desain lama, jangan dipakai untuk UI baru.

## Color System dan Komponen

Token di `lib/core/constants/app_colors.dart`, jangan hardcode hex baru tanpa alasan:
- Teks: ink `#15201D`, muted `#5B6864`, faint `#8A9793`
- Aksen: jade `#2C6B5A` (urusan dan uang), amber `#C9772F` (peringatan), rose `#B9536B` (Kita)
- Pastel latar ikon (solid): jadeSoft `#DDF0E6`, amberSoft `#FCE6D2`, roseSoft `#FADFE6`, lilac `#6E58B5`/`#E8E2F8`, sky `#3A72A8`/`#DCEBFA`, butter `#9A7414`/`#FBEFC8`. Warna per amplop dan dompet lewat `toneForCategory` dan `toneForWalletType` di `lib/core/utils/icon_map.dart`. Ikon di dalam `IconBox` dan tab aktif memakai gaya filled.
- Kaca: glass `#FFFFFFA8`, glassStrong `#FFFFFFD9`, tepi `#FFFFFFE6`
- Latar `#F1F2EC` dengan gradasi radial mint, peach, lilac (`AppBackground`)

Komponen bersama ada di `lib/core/widgets/`: `AppScaffold` (latar + tab bar kaca), `AppTabBar`, `ui_kit.dart` (GlassCard, AppNavBar, ListRow, ListCard, SegmentedControl, ProgressBar, HeroCard, PrimaryButton, dan lainnya), `app_sheet.dart` (sheet, dialog, picker, field), `pin_pad.dart`, `family_scope.dart` (menyediakan ViewModel untuk keluarga pengguna). Tipografi di `lib/core/theme/app_text.dart`, format angka dan tanggal di `lib/core/utils/format.dart`.

## Struktur Folder

```
lib/
├── core/               # constants, DI, router, theme, services, utils, shared widgets
├── features/
│   ├── auth/           # Onboarding, Masuk, Daftar, Undang pasangan, Gabung pakai kode
│   ├── home/           # Hari ini, Notifikasi, Cari & catat cepat, cuaca
│   ├── tasks/          # Urusan (yang ingat dan yang kerjakan)
│   ├── finance/        # Uang, amplop, dompet, rekap, cicilan, tabungan, aset, wishlist
│   ├── calendar/       # Kalender, Rumah sehat
│   ├── together/       # Kita, check-in, obrolan, akhir bulan, perjalanan, jurnal
│   ├── shopping/       # Belanja bersama
│   ├── life_stage/     # Siap nikah, Menyambut bayi, Lebaran & THR
│   └── settings/       # Rumah, Brankas, Profil, Pengaturan, Paywall, Widget
```

Tiap feature: `data/` (datasources, repositories impl) → `domain/` (entities, abstract repository, usecases) → `presentation/` (viewmodels sebagai `ChangeNotifier`, screens, widgets).

**Aturan wajib:** domain layer tidak boleh import apapun dari Firebase. Semua akses Firestore lewat implementasi konkret repository di data layer, di-inject ke ViewModel lewat abstract interface (`lib/core/di/injection.dart`).

## Data & Firestore

Root `families/{familyId}` dengan subcollection: `wallets`, `categories`, `transactions`, `walletTransfers`, `monthlyReports`, `goals`, `installments`, `assets`, `wishlist`, `calendarEvents`, `maintenanceItems`, `tasks`, `shoppingItems`, `checkIns`, `dailyPhoto`, `loveTimeline`, `conversationCards`, `reflections`, `journalEntries` (field `type`: cerita atau makasih), `notifications`, `vault`, `lifeStages`, `settings`. Collection `users` di top-level, terhubung lewat `familyId`. Dokumen family menyimpan `inviteCode` 6 karakter untuk undang pasangan.

Seed demo ada di `assets/firestore_seed_data.json`, dijalankan oleh `lib/core/dev/seed_runner.dart` saat debug. Seed gagal tanpa login (aturan Firestore), dan kegagalannya tidak memblokir startup.

Untuk melihat semua layar tanpa login saat debug: `flutter run --dart-define=DEV_BYPASS_AUTH=true` (tidak aktif di rilis). Data Firestore tetap kosong di mode ini karena aturan keamanan.

## Konvensi Kode

- Nama file: `snake_case.dart`
- Nama class: `PascalCase`
- ViewModel selalu suffix `ViewModel`, extends `ChangeNotifier`, dispose `StreamSubscription` dengan benar di `dispose()`
- Abstract repository interface di `domain/repositories/`, implementasi konkret di `data/repositories/` dengan suffix `Impl`
- Jangan gunakan em dash atau en dash di komentar/string manapun, pakai koma atau titik
- Semua teks yang tampil ke pengguna dibungkus `tr('teks Indonesia')` dari `lib/core/l10n/app_locale.dart`, nilai sisipan pakai `tr('Sisa {0}', [x])`. Terjemahan Inggris ditambahkan di `lib/core/l10n/strings_en.dart` dengan kunci persis sama. Kata bermakna ganda diberi konteks `tr('Masuk|uang')`. Nilai data (status, filter, key Firestore) jangan dibungkus tr, terjemahkan saat ditampilkan. Bahasa disimpan per perangkat (SharedPreferences), default mengikuti bahasa HP

## Yang Belum Diputuskan / Perlu Konfirmasi Krisna

- Package name dan bundle ID (nama brand sudah final: Ruma, di `AppBrand.name`)
- Pembayaran Plus (Google Play Billing atau RevenueCat) belum tersambung, paywall baru tampilan
- SHA-1 keystore rilis dan Play App Signing belum didaftarkan di Firebase, wajib sebelum rilis supaya Masuk dengan Google jalan
