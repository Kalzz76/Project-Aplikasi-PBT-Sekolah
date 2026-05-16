# Aturan & Persyaratan Proyek Edusync Admin Dashboard

Dokumen ini berisi standar desain dan logika yang **WAJIB** diikuti di seluruh pengembangan aplikasi Administrasi Sekolah.

## 1. Konsistensi & UI Tabel
*   **Sticky Header**: Seluruh tabel harus memiliki header yang tetap di atas (*sticky*) saat di-scroll.
*   **Pewarnaan Seragam**: Gunakan token warna dari `AppColors`. Header tabel menggunakan background `#F8FAFC` dan teks `AppColors.textSecondary` (bold).
*   **Pagination**: Setiap tabel yang mengelola data besar (Siswa, Guru, dll) wajib mengimplementasikan pagination.

## 2. Fitur Input & Dropdown (Searchable)
*   **Searchable Dropdown**: Dilarang menggunakan dropdown standar jika data yang dipilih berjumlah banyak. 
*   **Mekanisme**: Ketika field diklik, user bisa mengetik untuk memfilter data (autocomplete). Setelah data terpilih muncul, baru bisa diklik untuk mengonfirmasi pilihan.

## 3. Validasi Data (Anti-Duplikasi)
Setiap form (Tambah/Edit) harus memiliki validasi ketat untuk mencegah data ganda:
*   **Kelas**: Tidak boleh ada nama kelas yang sama.
*   **Wali Kelas**: Satu guru hanya boleh menjadi wali kelas di satu kelas (kecuali ada aturan khusus).
*   **Nama Siswa/Guru**: Validasi berdasarkan NIS/NIP/NIK untuk mencegah duplikasi identitas.
*   **Jabatan**: Dalam struktur organisasi kelas, jabatan seperti "Ketua Murid" tidak boleh diisi oleh lebih dari satu orang.

## 4. Desain Premium
*   Gunakan `CustomBadge` untuk status atau kategori.
*   Terapkan `CustomCard` dengan shadow halus dan border radius `24px` atau `16px`.
*   Selalu gunakan icon dari `LucideIcons` untuk tampilan yang modern.

---
*Terakhir diperbarui: 14 Mei 2026*
