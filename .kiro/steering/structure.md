# Project Structure

```
lib/
├── main.dart               # App entry, Supabase init, Provider setup, role-based routing
├── core/
│   ├── app_colors.dart     # AppColors — all color tokens (light + dark variants)
│   ├── app_theme.dart      # AppTheme.lightTheme — Material 3 theme using Inter font
│   ├── chronos_service.dart # Singleton time simulator for schedule/attendance testing
│   └── school_schedule_utils.dart # Time slot parsing, day/range helpers
├── data/
│   └── mock_data.dart      # Fallback/seed data (used when Supabase is unavailable)
├── models/                 # Plain Dart data classes (immutable, no logic)
│   ├── user.dart           # UserProfile, UserRole enum (admin, guru, siswa)
│   ├── student.dart        # Student (id, nis, nisn, name, gender, kelas, position)
│   ├── teacher.dart        # Teacher
│   ├── school_class.dart   # SchoolClass
│   ├── subject.dart        # Subject
│   ├── room.dart           # Room
│   ├── schedule.dart       # ScheduleEntry
│   ├── attendance.dart     # Attendance, AttendanceStatus enum
│   ├── sort_option.dart    # SortOption
│   ├── import_student_row.dart     # Row model for Excel import
│   └── attendance_export_row.dart  # Row model for Excel/PDF export
├── providers/
│   └── app_provider.dart   # Single AppProvider — all state, Supabase fetches, business logic
├── services/
│   ├── supabase_sync_service.dart  # Supabase read/write helpers
│   ├── student_import_service.dart # Excel parsing → ImportStudentRow list
│   └── attendance_export_service.dart # Build Excel/PDF export from attendance data
├── views/
│   ├── splash_screen.dart  # Role selection screen shown on first load
│   ├── login_view.dart     # Login form (per role)
│   ├── main_layout.dart    # Shell: sidebar + header + active module
│   ├── profile_view.dart   # User profile page
│   ├── admin/              # Admin-only modules
│   │   ├── dashboard_admin.dart
│   │   ├── modul_data_siswa.dart
│   │   ├── modul_data_guru.dart
│   │   ├── modul_manajemen_kelas.dart
│   │   ├── modul_jadwal_pelajaran.dart
│   │   ├── modul_laporan_absensi.dart
│   │   ├── modul_mata_pelajaran.dart
│   │   ├── modul_data_ruangan.dart
│   │   ├── modul_manajemen_akun.dart
│   │   └── modul_chronos.dart
│   ├── guru/               # Teacher-only modules
│   │   ├── dashboard_guru.dart
│   │   ├── halaman_absensi.dart
│   │   └── modul_rekap_absensi.dart
│   └── siswa/              # Student/Secretary modules
│       └── dashboard_siswa.dart
└── widgets/                # Shared reusable UI components
    ├── custom_card.dart     # CustomCard — standard card with hover, dark mode, shadow
    ├── custom_button.dart   # CustomButton
    ├── custom_badge.dart    # CustomBadge — status/category labels
    ├── app_avatar.dart      # AppAvatar
    ├── digital_clock.dart   # Live clock widget
    ├── header.dart          # Top header bar
    ├── sidebar.dart         # Navigation sidebar
    └── export_attendance_dialog.dart
```

## Architecture Conventions

- **Models** are plain immutable Dart classes — no methods beyond simple helpers
- **AppProvider** is the single source of truth; views read state via `context.watch<AppProvider>()` and call methods on it directly
- **Views** are stateful only when local UI state is needed (hover, form fields, dialogs); business logic stays in `AppProvider`
- **Services** handle I/O (Supabase, file parsing, export) and are called from `AppProvider`
- Navigation is menu-driven: `AppProvider._activeMenu` string controls which module renders inside `MainLayout`

## UI Conventions

- Always use `AppColors.*` tokens — never hardcode color values
- Always use `LucideIcons.*` — never use Material icons
- Use `CustomCard` for all card surfaces (handles dark mode, hover, shadow automatically)
- Use `CustomBadge` for status chips and category labels
- Table headers: background `#F8FAFC`, text `AppColors.textSecondary` bold, sticky header required
- Card border radius: `16px` (standard) or `24px` (large)
- All dropdowns with many options must be searchable (autocomplete-style, not standard `DropdownButton`)
- Pagination required on all large data tables (students, teachers, etc.)

## Data Validation Rules

- No duplicate class names
- One homeroom teacher per class
- Student identity uniqueness enforced by NIS/NISN
- Class org positions (e.g., Ketua Murid) can only be held by one student per class
- Schedule slots validated for teacher/room conflicts before saving
