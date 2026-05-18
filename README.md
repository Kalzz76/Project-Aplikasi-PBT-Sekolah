# 🏫 Classio - School Administration & Attendance Portal

**Classio** adalah aplikasi manajemen administrasi dan rekap absensi sekolah berbasis Flutter modern, responsif, dan premium. Aplikasi ini mendukung sinkronisasi real-time menggunakan **Supabase**, pengelolaan data organisasi kelas dinamis (Struktur Kelas), ekspor-impor Excel cerdas, rekap otomatis, serta multi-role login untuk **Admin, Guru, dan Siswa/Sekretaris**.

---

## 🚀 Fitur Utama
1. **Multi-Role Portal**: Dashboard & hak akses khusus untuk Admin, Guru, dan Siswa.
2. **Interactive Organizational Structure**: Struktur organisasi kelas interaktif (10 jabatan) yang bisa diatur, dihapus, atau dikosongkan secara real-time.
3. **Smart Excel Import**: Mengimpor data siswa secara massal dari Excel dengan pemisah kolom `NIS / NISN` cerdas serta deteksi otomatis nama kelas dari nama file.
4. **Attendance Management**: Rekap & tanda absensi (Hadir, Izin, Sakit, Alpa, Pulang) lengkap dengan grafik persentase kehadiran harian dan bulanan.
5. **Conflict-Free Class Scheduling**: Pengaturan jadwal pelajaran per hari, slot waktu, ruangan, dan guru pengajar dengan validasi bentrok.
6. **Unified Database Engine**: Sinkronisasi Supabase dengan skema UUID yang terstruktur rapi.

---

## 🛠️ Prasyarat Instalasi
Sebelum memulai, pastikan perangkat Anda telah terinstal:
* **Flutter SDK** (versi >= 3.0.0) -> [Unduh di sini](https://docs.flutter.dev/get-started/install)
* **Google Chrome** (untuk menjalankan versi Web)
* **Akun Supabase** -> [Daftar gratis](https://supabase.com/)

---

## 🗄️ Konfigurasi Database Supabase

Untuk menjalankan aplikasi ini dengan lancar, buatlah tabel-tabel berikut di dalam Supabase SQL Editor Anda:

### 1. Tabel `profiles` (Informasi Akun)
```sql
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  role text not null check (role in ('admin', 'guru', 'siswa')),
  username text unique not null,
  avatar_url text
);
```

### 2. Tabel `classes` (Data Kelas)
```sql
create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  homeroom_teacher_id uuid, -- Bisa dihubungkan ke profiles.id
  room_name text default '-'
);
```

### 3. Tabel `students` (Data Siswa)
```sql
create table public.students (
  id uuid primary key default gen_random_uuid(),
  nis text not null unique,
  nisn text,
  gender varchar(2) check (gender in ('L', 'P')),
  class_id uuid references public.classes(id) on delete set null,
  position text default 'Anggota'
);
```

### 4. Tabel `teachers` (Data Guru)
```sql
create table public.teachers (
  id uuid primary key default gen_random_uuid(),
  nip text not null unique,
  position text default 'Guru Mapel',
  subjects text[] default '{}',
  avatar_url text
);
```

### 5. Tabel `rooms` (Data Ruangan Kelas/Lab)
```sql
create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null
);
```

### 6. Tabel `subjects` (Mata Pelajaran)
```sql
create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);
```

### 7. Tabel `schedules` (Jadwal Pelajaran)
```sql
create table public.schedules (
  id uuid primary key default gen_random_uuid(),
  day_name text not null,
  slot_label text not null,
  class_id uuid references public.classes(id) on delete cascade,
  is_event boolean default false,
  custom_title text,
  subject_id uuid references public.subjects(id) on delete set null,
  room_id uuid references public.rooms(id) on delete set null,
  teacher_id uuid references public.teachers(id) on delete set null
);
```

### 8. Tabel `attendance` (Data Absensi)
```sql
create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.students(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  date timestamp with time zone not null,
  status text not null check (status in ('hadir', 'izin', 'sakit', 'alpa', 'pulang')),
  marked_by uuid,
  marked_by_role text default 'admin',
  reason text,
  notes text
);
```

---

## ⚙️ Cara Menjalankan Project

### 1. Clone Project
```bash
git clone https://github.com/Kalzz76/Project-Aplikasi-PBT-Sekolah.git
cd Project-Aplikasi-PBT-Sekolah
```

### 2. Salin dan Setup File Environment
Buat file baru bernama `.env` di folder root project (sejajar dengan `pubspec.yaml`), lalu isi dengan kredensial Supabase Anda:
```env
SUPABASE_URL=https://YOUR_SUPABASE_PROJECT_URL.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_PUBLIC_KEY
```

### 3. Jalankan Instalasi Dependency
```bash
flutter pub get
```

### 4. Jalankan Aplikasi
Jalankan aplikasi pada browser Google Chrome Anda:
```bash
flutter run -d chrome
```

---

## 💡 Panduan Penggunaan & Tips Bebas Error

### 📊 1. Mengimpor Data Siswa via Excel
Jika Anda melakukan import dan menemui pesan *"File Excel tidak kompatibel"*, ini disebabkan oleh variasi struktur XML internal pada pustaka parsing. 
* **Solusi Instan**: Cukup buka file Excel Anda (`.xlsx`) di **Microsoft Excel** atau **Google Sheets**, lalu pilih **Save / Simpan Ulang** atau **Download as .xlsx**. Setelah disimpan ulang oleh aplikasi resmi, file tersebut akan memiliki format XML standar dan dapat langsung di-import 100% sukses ke aplikasi Classio!
* **Deteksi Kelas Otomatis**: Nama kelas akan dideteksi secara otomatis dari nama file Excel Anda (contoh file: `Data_Siswa_X_RPL_1.xlsx` akan otomatis membuat kelas **X RPL 1** jika belum terdaftar).

### 👑 2. Mengatur Struktur Organisasi Kelas
* Secara default, setiap siswa yang baru ditambahkan/di-import akan berstatus sebagai **`'Anggota'`**.
* Untuk mengatur jabatan pengurus (seperti Ketua Murid, Sekretaris, Bendahara):
  1. Masuk ke **Manajemen Kelas** -> klik tab **Struktur Kelas**.
  2. **Klik langsung pada kartu jabatan** yang ingin diatur (misalnya kartu *Ketua Murid*).
  3. Pilih nama siswa dari dropdown untuk mengangkatnya, atau pilih **`"Belum Diatur / Kosongkan"`** (opsi merah) untuk mengosongkan kembali jabatan tersebut.
  4. Klik **Simpan**. Sistem akan otomatis men-sinkronkan peran tersebut ke database Supabase Anda secara aman!
