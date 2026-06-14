export type UserRole = 'petugas' | 'pengawas' | 'admin';

export interface Profile {
  id: string;
  full_name: string;
  role: UserRole;
  phone?: string;
  avatar_url?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type KeluargaStatus = 'draft' | 'pending' | 'verified' | 'rejected';

export interface Keluarga {
  id: string;
  no_kk: string;
  nama_kepala_keluarga: string;
  nik_kepala_keluarga: string;
  alamat: string;
  lingkungan: string;
  kelurahan: string;
  kecamatan: string;
  kota: string;
  kode_pos?: string;
  latitude?: number;
  longitude?: number;
  foto_rumah_url?: string;
  scan_kk_url?: string;
  petugas_id?: string;
  status: KeluargaStatus;
  created_at: string;
  updated_at: string;
}

export interface Individu {
  id: string;
  keluarga_id: string;
  no_kk: string;
  nik: string;
  nama_lengkap: string;
  nama_panggilan?: string;
  alamat: string;
  lingkungan: string;
  kelurahan: string;
  kecamatan: string;
  kota: string;
  pekerjaan?: string;
  tempat_lahir?: string;
  tanggal_lahir: string;
  usia?: number; // Calculated dynamically from view or client side
  agama?: string;
  status_perkawinan?: string;
  status_hubungan_keluarga?: string;
  jenis_kelamin?: 'Laki-laki' | 'Perempuan';
  suku: string;
  anggota_pujakesuma: boolean;
  foto_ktp_url?: string;
  petugas_id?: string;
  created_at: string;
  updated_at: string;
}

export interface ChatRoom {
  id: string;
  name?: string;
  is_group: boolean;
  created_at: string;
}

export interface ChatMessage {
  id: string;
  room_id: string;
  sender_id: string;
  content: string;
  attachment_url?: string;
  is_read: boolean;
  created_at: string;
}

export interface DashboardStats {
  totalKeluarga: number;
  totalIndividu: number;
  totalVerified: number;
  totalPending: number;
  kecamatanDistribution: Record<string, number>;
  sukuDistribution: Record<string, number>;
  agamaDistribution: Record<string, number>;
  usiaDistribution: Record<string, number>;
}
