# Catatan Development — Muslim App
**Tanggal:** 19 Maret 2026

---

## Bug Fix

### 1. Compile error `mushaf_screen.dart`
- **Masalah:** `await` dipakai di dalam `builder` FutureBuilder yang bukan `async`
- **Fix:** Hapus baris `await getSurahById()` yang unused, ganti header surah dengan nested `FutureBuilder`

### 2. Inkonsistensi `PageController`
- **Masalah:** `PageController(initialPage: 603)` tapi `currentPage = 1`, tidak sinkron
- **Fix:** Ganti ke `initialPage: widget.initialPage - 1`, hapus dead code (`loadPage`, `ayahs`, `buildMushafText`)

### 3. Error koneksi fetch data Quran
- **Masalah:** `ClientException: Connection closed while receiving data` — endpoint `/v1/quran/quran-uthmani` mengembalikan seluruh Quran (~30MB) sekaligus, koneksi putus
- **Fix:** Fetch per surah (114 request kecil), tiap surah ambil Arabic + terjemahan Indonesia secara `Future.wait`
- **Tambahan:** Retry otomatis max 3x dengan delay bertahap (1s, 2s, 3s) + timeout 30 detik per request

### 4. Tabel `surah` kurang kolom `revelation_type`
- **Masalah:** Schema DB tidak punya kolom `revelation_type`, tapi `SurahModel.toMap()` menulis ke kolom tersebut
- **Fix:** Bump DB version `1 → 2`, tambah migration `ALTER TABLE surah ADD COLUMN revelation_type TEXT`

### 5. Data surah tidak pernah disimpan ke DB
- **Masalah:** `surahList` di `QuranRemoteDataSource` dibuat tapi tidak pernah di-return atau disimpan
- **Fix:** `fetchAllQuranData()` sekarang return `({List<SurahModel> surahs, List<AyahModel> ayahs})`, keduanya disimpan ke DB

### 6. Duplikasi Bismillah di Mushaf
- **Masalah:** API menyertakan teks Bismillah di dalam `textUthmani` ayah 1, sedangkan kita juga menampilkan header Bismillah tersendiri
- **Fix:** Fungsi `_stripBismillah()` — strip prefix Bismillah dari teks ayah 1 saat header sudah ditampilkan

---

## Improvement

### 7. Aktifkan notifikasi adzan
- Un-comment `SwitchListTile` notifikasi adzan
- Hapus field `notif` dan tombol debug yang di-comment

### 8. Loading indicator fetch data Quran
- App tidak lagi blocking di `main()` saat fetch Quran
- `AppInitializer` hanya handle init cepat (timezone, notifikasi, DB)
- Download Quran berjalan **di background** via `QuranDownloadProvider` (Riverpod)
- Grid item "Al-Qur'an" menampilkan progress download secara real-time

### 9. Timezone otomatis
- Ganti `tz.getLocation('Asia/Jakarta')` (hardcoded) → `FlutterTimezone.getLocalTimezone()` (mengikuti setting perangkat)

### 10. Konsolidasi navigasi ke GoRouter
- Tambah route `/quran`, `/quran/mushaf`, `/qibla` ke `router.dart`
- Semua navigasi pakai `context.push()` agar back button muncul otomatis
- Hapus `Navigator.push` langsung dari `prayer_screen.dart`

### 11. Perbaikan `prayer_screen.dart`
- Timer rebuild screen dari tiap **1 detik** → tiap **1 menit** (prayer time tidak butuh update per detik)
- Hapus dead code: `debugNotification60Seconds()`, `_formatDuration()`, variabel `date`
- Fix deprecation: `withOpacity()` → `withValues(alpha: ...)`
- Hapus redundant `.sort()` di `getCurrentPrayer` (map sudah urut chronologis)
- Ganti `Colors.green` hardcoded → `Theme.of(context).colorScheme.primary`

### 12. Fitur daftar surah (SurahListScreen)
- Sebelum buka mushaf, user memilih surah dari daftar 114 surah
- Tap surah → ambil halaman pertama surah dari DB → buka `MushafScreen` di halaman yang tepat
- Tampil: nomor surah, nama Arab, nama Inggris, jenis wahyu, jumlah ayat

### 13. Bismillah di awal surah (Mushaf)
- Bismillah ditampilkan sebagai header tersendiri sebelum ayah 1 tiap surah
- **Pengecualian:**
  - Surah 1 (Al-Fatihah): Bismillah adalah ayah 1, tidak perlu header terpisah
  - Surah 9 (At-Tawbah): tidak ada Bismillah

---

## ⚠️ Perlu Dicek / Diverifikasi

### Bismillah di awal surah
Status: **Belum diverifikasi sepenuhnya**

Yang perlu dicek:
- [ ] Apakah strip Bismillah dari `textUthmani` ayah 1 sudah tepat untuk semua surah? (format teks dari API bisa berbeda antar surah)
- [ ] Apakah surah 1 (Al-Fatihah) tampil benar tanpa header Bismillah?
- [ ] Apakah surah 9 (At-Tawbah) tampil benar tanpa header Bismillah?
- [ ] Apakah ada surah lain yang teksnya tidak diawali Bismillah tapi logic kita tetap menampilkan header? (misal: surah yang dimulai di tengah halaman mushaf)
- [ ] Apakah terjemahan ayah 1 masih sesuai setelah teks Arab di-strip? (terjemahan tidak diubah, tapi perlu konfirmasi visual)

---

## File yang Diubah

| File | Perubahan |
|---|---|
| `lib/main.dart` | AppInitializer ringan, timezone otomatis |
| `lib/app/router.dart` | Tambah route /quran, /quran/mushaf, /qibla |
| `lib/core/database/database_helper.dart` | Tambah kolom `revelation_type`, versi DB → 2 |
| `lib/core/services/notification_service.dart` | Tidak diubah |
| `lib/features/prayer/presentation/screens/prayer_screen.dart` | Timer, dead code, deprecation, warna, notifikasi, navigasi |
| `lib/features/quran/data/datasources/quran_remote_datasource.dart` | Fetch per surah, retry, terjemahan Indonesia |
| `lib/features/quran/data/datasources/quran_local_datasource.dart` | Tambah `getAllSurahs()`, `getFirstPageBySurahId()`, fix null safety |
| `lib/features/quran/presentation/providers/quran_download_provider.dart` | **Baru** — background download provider |
| `lib/features/quran/presentation/screens/surah_list_screen.dart` | **Baru** — daftar 114 surah |
| `lib/features/quran/presentation/screens/mushaf_screen.dart` | initialPage param, Bismillah header, strip duplikasi |
