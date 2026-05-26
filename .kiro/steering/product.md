# Classio — School Administration & Attendance Portal

Classio is a Flutter-based web application for managing school administration and attendance. It targets Indonesian schools and supports three user roles: **Admin**, **Guru (Teacher)**, and **Siswa/Sekretaris (Student/Secretary)**.

## Core Features

- **Multi-role portal** — each role has its own dashboard and access scope
- **Attendance management** — mark and recap attendance (Hadir, Izin, Sakit, Alpa, Pulang) with daily/monthly charts
- **Class management** — organizational structure with 10 positions (Ketua Murid, Wakil Ketua, Bendahara, Sekretaris, etc.)
- **Schedule management** — per-day, per-slot scheduling with conflict detection
- **Student import** — bulk import via Excel with auto class detection from filename
- **Attendance export** — export to Excel/PDF
- **Chronos** — admin-controlled time simulation for testing schedule/attendance logic
- **Real-time sync** — Supabase backend with UUID-based schema

## Language

UI labels, variable names, and domain terms are in **Indonesian** (e.g., `kelas`, `guru`, `siswa`, `jadwal`, `absensi`). Code identifiers follow this convention.
