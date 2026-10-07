# Landing page Ruma

Halaman statis berbahasa Inggris, diturunkan dari frame "Ruma Landing Page" di `ruma_landing_page_design.pen`. Isinya ada di `public/`, dihosting lewat Firebase Hosting (gratis di paket Spark).

## Deploy

```bash
npm install -g firebase-tools
firebase login            # atau FIREBASE_TOKEN / service account di CI
firebase deploy --only hosting
```

Project default diatur di `.firebaserc` (`seruma-recreate-mobile`), jadi alamatnya `https://seruma-recreate-mobile.web.app`.

## Yang perlu diisi

- `PLAY_URL` di bagian bawah `public/index.html`. Selama kosong, tombol menampilkan "Coming soon on Google Play".
- `[contact email]`, `[operator name]`, dan `[address]` di `public/privacy.html`, `public/terms.html`, dan footer `public/index.html`. Cari teks dalam kurung siku lalu ganti.
- Draf privacy dan terms belum ditinjau ahli hukum. URL privacy untuk Play Console: `/privacy`.
- Tangkapan layar di `public/img/shot-*.webp` masih UI berbahasa Indonesia.
