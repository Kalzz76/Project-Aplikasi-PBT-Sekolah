# Planning Sistem Absensi Baru — Classio
> Dokumen ini berisi rencana perubahan sistem absensi berdasarkan saran dari guru pembimbing.
> Dibuat: 26 Mei 2026

---

## Latar Belakang

Setelah presentasi aplikasi, guru pembimbing memberikan beberapa saran perbaikan pada sistem absensi:

1. Guru tidak lagi mengisi absensi siswa — cukup memvalidasi
2. Sekretaris kelas yang mengisi absensi, per jam pelajaran
3. Sekretaris juga melaporkan kehadiran guru tiap sesi
4. Kehadiran guru dihitung per jam (bukan per hari)

---

## Ringkasan Perubahan

| Aspek | Sebelum | Sesudah |
|-------|---------|---------|
| Siapa yang absen siswa | Guru atau Sekretaris | **Sekretaris saja** |
| Satuan absensi | Per mapel per hari | **Per slot jadwal (per jam)** |
| Peran guru | Bisa isi absensi | **Hanya validasi** |
| Laporan kehadiran guru | Tidak ada | **Sekretaris isi per slot, dihitung per jam** |
| Window pengisian | Hanya saat jam berlangsung | **Selama mapel yang sama masih ada di hari itu** |
| Kunci otomatis | Manual | **Otomatis saat slot terakhir mapel selesai** |

---

## Konsep Window Pengisian & Kunci Otomatis

Sekretaris boleh mengisi/mengedit absensi slot manapun dari satu mapel,
selama **slot terakhir mapel tersebut di hari itu belum selesai**.

**Contoh:**
```
Matematika hari Senin → Jam 1, 2, 3, 4 (selesai pukul 10.00)

├── Jam 1 → bisa diisi/diedit sampai pukul 10.00
├── Jam 2 → bisa diisi/diedit sampai pukul 10.00
├── Jam 3 → bisa diisi/diedit sampai pukul 10.00
└── Jam 4 → bisa diisi/diedit sampai pukul 10.00
              ↓
         Pukul 10.00 → SEMUA slot Matematika hari ini TERKUNCI OTOMATIS
```

Jika sekretaris lupa mengisi Jam 2, masih bisa diisi selama Jam 3 atau 4 masih berlangsung.
Setelah Jam 4 selesai, tidak ada yang bisa mengisi atau mengedit lagi.

---

## Konsep Rekap Kehadiran Guru Per Jam

Guru yang hadir sebagian jam tetap tercatat dengan benar.

**Contoh:**
```
Pak Budi — Matematika — Senin 26 Mei 2026
├── Jam 1 (07.00–07.45) → ✅ Hadir
├── Jam 2 (07.45–08.30) → ✅ Hadir
├── Jam 3 (08.30–09.15) → ❌ Tidak Hadir (Kendala mendadak)
└── Jam 4 (09.15–10.00) → ✅ Hadir
```

**Rekap bulanan:**
| Bulan | Total Jam Mengajar | Hadir | Tidak Hadir | % Kehadiran |
|-------|--------------------|-------|-------------|-------------|
| Mei   | 40 jam             | 38    | 2           | 95%         |

---

## Detail Perubahan Per Fitur

### Perubahan 1 — Model Attendance (Update)
**File:** `lib/models/attendance.dart`

Tambah field baru:
- `slotLabel` — jam ke berapa slot ini (contoh: `"Jam 1"`)
- `validationStatus` — status validasi: `pending` / `validated` / `rejected`
- `validatedBy` — ID guru yang memvalidasi
- `validatedAt` — waktu validasi dilakukan

---

### Perubahan 2 — Model TeacherAttendance (Baru)
**File baru:** `lib/models/teacher_attendance.dart`

Model untuk mencatat kehadiran guru per slot, diisi oleh sekretaris:

| Field | Tipe | Keterangan |
|-------|------|------------|
| `teacherId` | String | ID guru |
| `classId` | String | ID kelas |
| `subjectId` | String | ID mata pelajaran |
| `slotLabel` | String | Jam ke berapa (contoh: `"Jam 3"`) |
| `date` | DateTime | Tanggal |
| `status` | Enum | `hadir` / `tidak_hadir` |
| `reason` | String? | Alasan jika tidak hadir: Terlambat / Rapat / Sakit / Lainnya |
| `notes` | String? | Keterangan bebas (opsional) |
| `reportedBy` | String | ID sekretaris yang mengisi |

---

### Perubahan 3 — Database Supabase

**Tabel `attendance` — tambah kolom:**
```sql
alter table attendance add column slot_label text;
alter table attendance add column validation_status text default 'pending';
alter table attendance add column validated_by uuid;
alter table attendance add column validated_at timestamptz;
```

**Tabel baru `teacher_attendance`:**
```sql
create table teacher_attendance (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references teachers(id),
  class_id uuid references classes(id),
  subject_id uuid references subjects(id),
  slot_label text not null,
  date date not null,
  status text check (status in ('hadir', 'tidak_hadir')),
  reason text,
  notes text,
  reported_by uuid
);
```

---

### Perubahan 4 — Logika Window & Kunci Otomatis
**File:** `lib/providers/app_provider.dart` + `lib/core/school_schedule_utils.dart`

Method baru:
```dart
// Cek apakah sekretaris masih bisa isi/edit absensi mapel ini
bool isSubjectWindowOpen(String classId, String subjectId, String day)
// → true jika slot terakhir mapel tsb di hari itu belum selesai
```

---

### Perubahan 5 — Halaman Absensi Sekretaris (Update)
**File:** `lib/views/guru/halaman_absensi.dart`

Perubahan:
- Header tampilkan info slot: `"Jam 1 • Matematika • X RPL 1"`
- Daftar siswa **pre-filled Hadir semua** — sekretaris hanya ubah yang berbeda
- Tambah section **"Kehadiran Guru"** di bawah daftar siswa:
  - Pilihan status: Hadir / Tidak Hadir
  - Jika Tidak Hadir → wajib pilih alasan (Terlambat / Rapat / Sakit / Lainnya)
  - Field keterangan opsional
- Tombol simpan → menyimpan absensi siswa + kehadiran guru sekaligus
- Setelah simpan → status sesi menjadi `pending` (menunggu validasi guru)
- Jika window sudah tutup → form terkunci, tampil pesan *"Waktu pengisian sudah habis"*

---

### Perubahan 6 — Dashboard Sekretaris: Banner Reminder (Update)
**File:** `lib/views/siswa/dashboard_siswa.dart`

Tambah banner peringatan jika ada sesi yang belum diisi dan window masih terbuka:

```
⚠️  Belum diisi: Jam 3 — B. Indonesia (window tutup pukul 10.00)
⚠️  Belum diisi: Jam 5 — Fisika (window tutup pukul 12.30)
                                              [Isi Sekarang →]
```

Banner hilang otomatis jika semua sesi sudah diisi atau window sudah tutup.

---

### Perubahan 7 — Dashboard Guru: Hapus Isi Absensi, Tambah Validasi (Update)
**File:** `lib/views/guru/dashboard_guru.dart`

- **Dihapus:** tombol "Isi Absensi Sekarang" dan "Ubah Absensi"
- **Ditambah:** badge status validasi di kartu jadwal:

| Badge | Warna | Kondisi |
|-------|-------|---------|
| `BELUM DIISI` | Abu-abu | Sekretaris belum mengisi |
| `MENUNGGU VALIDASI` | Kuning | Sekretaris sudah isi, guru belum validasi |
| `TERVALIDASI` | Hijau | Guru sudah konfirmasi |
| `DITOLAK` | Merah | Guru tolak, sekretaris perlu edit ulang |

- Tombol **"Validasi"** muncul jika status `pending`

---

### Perubahan 8 — Halaman Validasi Guru (Baru)
**File baru:** `lib/views/guru/halaman_validasi_absensi.dart`

Alur:
1. Guru buka halaman validasi → lihat daftar sesi yang statusnya `pending`
2. Klik satu sesi → lihat daftar lengkap siswa + status yang diisi sekretaris (read-only)
3. Guru periksa data, lalu pilih:
   - **Konfirmasi** → status jadi `validated`, data terkunci permanen
   - **Tolak** → status jadi `rejected`, sekretaris bisa edit ulang (selama window masih terbuka)

---

### Perubahan 9 — Rekap Absensi Siswa: Per Jam (Update)
**File:** `lib/views/guru/modul_rekap_absensi.dart`

- Tambah kolom **"Jam"** (slot label) di tabel rekap
- Perhitungan kehadiran berubah dari per-hari ke **per jam pelajaran**
- Rumus: `% Kehadiran = (jumlah slot Hadir / total slot) × 100`

---

### Perubahan 10 — Rekap Kehadiran Guru (Baru)
**File:** `lib/views/guru/modul_rekap_absensi.dart` + `lib/views/admin/modul_laporan_absensi.dart`

Hak akses:
- **Guru** → lihat rekap kehadiran dirinya sendiri (read-only)
- **Admin** → lihat semua guru, bisa filter per guru / bulan / mapel

---

## Urutan Pengerjaan

| # | Pekerjaan | File |
|---|-----------|------|
| 1 | Update model Attendance | `lib/models/attendance.dart` |
| 2 | Buat model TeacherAttendance | `lib/models/teacher_attendance.dart` |
| 3 | Update AppProvider (logika window, method baru) | `lib/providers/app_provider.dart` |
| 4 | Update halaman absensi sekretaris | `lib/views/guru/halaman_absensi.dart` |
| 5 | Buat halaman validasi guru | `lib/views/guru/halaman_validasi_absensi.dart` |
| 6 | Update dashboard guru | `lib/views/guru/dashboard_guru.dart` |
| 7 | Update dashboard sekretaris (banner reminder) | `lib/views/siswa/dashboard_siswa.dart` |
| 8 | Update rekap absensi siswa (per jam) | `lib/views/guru/modul_rekap_absensi.dart` |
| 9 | Update laporan admin (rekap guru) | `lib/views/admin/modul_laporan_absensi.dart` |

---

*Dokumen ini dibuat oleh Kiro AI — Classio Project*
