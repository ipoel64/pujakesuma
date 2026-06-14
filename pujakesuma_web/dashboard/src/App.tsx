import { useState, useEffect } from 'react'
import { supabase } from './lib/supabase'
import LandingPage from './components/LandingPage'
import { 
  Users, 
  Home, 
  MessageSquare, 
  FileText, 
  Settings, 
  LogOut, 
  Bell, 
  Search, 
  Filter, 
  CheckCircle, 
  Clock, 
  AlertTriangle, 
  Download, 
  UserCheck, 
  Printer
} from 'lucide-react'

// Dummy profile representing the logged-in administrator
const dummyAdminProfile = {
  full_name: 'Drs. Raden H. Hermawan, M.Si',
  role: 'admin',
  avatar_url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&width=200&auto=format&fit=crop'
}

// Dummy data for dashboard summary cards
const initialStats = {
  totalKeluarga: 382,
  totalIndividu: 1528,
  totalVerified: 320,
  totalPending: 48,
}

// Dummy families data
const dummyFamiliesData = [
  { id: '1', no_kk: '1275010203040001', nama_kepala_keluarga: 'Suwarno', nik_kepala_keluarga: '1275010203040101', alamat: 'Jl. Jend. Sudirman Gg. Rukun', lingkungan: 'Lingkungan III', kelurahan: 'Berngam', kecamatan: 'Binjai Kota', status: 'verified', created_at: '2026-06-12' },
  { id: '2', no_kk: '1275010203040002', nama_kepala_keluarga: 'Joko Widodo', nik_kepala_keluarga: '1275010203040102', alamat: 'Jl. Gatot Subroto Gg. Ikhlas No. 4', lingkungan: 'Lingkungan I', kelurahan: 'Kebun Lada', kecamatan: 'Binjai Utara', status: 'pending', created_at: '2026-06-12' },
  { id: '3', no_kk: '1275010203040003', nama_kepala_keluarga: 'Sri Mulyani', nik_kepala_keluarga: '1275010203040103', alamat: 'Jl. Samanhudi No. 12', lingkungan: 'Lingkungan V', kelurahan: 'Suka Maju', kecamatan: 'Binjai Barat', status: 'verified', created_at: '2026-06-11' },
  { id: '4', no_kk: '1275010203040004', nama_kepala_keluarga: 'Bambang Pamungkas', nik_kepala_keluarga: '1275010203040104', alamat: 'Jl. Binjai Estate Gg. Jawa', lingkungan: 'Lingkungan II', kelurahan: 'Binjai Estate', kecamatan: 'Binjai Selatan', status: 'draft', created_at: '2026-06-11' },
  { id: '5', no_kk: '1275010203040005', nama_kepala_keluarga: 'Adi Haryadi', nik_kepala_keluarga: '1275010203040105', alamat: 'Jl. Mencirim No. 8B', lingkungan: 'Lingkungan IV', kelurahan: 'Sumber Karya', kecamatan: 'Binjai Timur', status: 'verified', created_at: '2026-06-10' },
  { id: '6', no_kk: '1275010203040006', nama_kepala_keluarga: 'Eko Prasetyo', nik_kepala_keluarga: '1275010203040106', alamat: 'Jl. T. Amir Hamzah No. 45', lingkungan: 'Lingkungan VI', kelurahan: 'Jati Karya', kecamatan: 'Binjai Utara', status: 'pending', created_at: '2026-06-10' }
]

// Dummy individuals data
const dummyIndividualsData = [
  { id: '101', no_kk: '1275010203040001', nik: '1275010203040101', nama_lengkap: 'Suwarno', pekerjaan: 'Pegawai Negeri', tempat_lahir: 'Binjai', tanggal_lahir: '1975-04-12', usia: 51, agama: 'Islam', status_perkawinan: 'Kawin', jenis_kelamin: 'Laki-laki', suku: 'Jawa', anggota_pujakesuma: true },
  { id: '102', no_kk: '1275010203040001', nik: '1275010203040102', nama_lengkap: 'Siti Aminah', pekerjaan: 'Ibu Rumah Tangga', tempat_lahir: 'Langkat', tanggal_lahir: '1979-08-20', usia: 46, agama: 'Islam', status_perkawinan: 'Kawin', jenis_kelamin: 'Perempuan', suku: 'Jawa', anggota_pujakesuma: true },
  { id: '103', no_kk: '1275010203040001', nik: '1275010203040103', nama_lengkap: 'Rian Hidayat', pekerjaan: 'Pelajar', tempat_lahir: 'Binjai', tanggal_lahir: '2005-02-15', usia: 21, agama: 'Islam', status_perkawinan: 'Belum Kawin', jenis_kelamin: 'Laki-laki', suku: 'Jawa', anggota_pujakesuma: true },
  { id: '104', no_kk: '1275010203040002', nik: '1275010203040102', nama_lengkap: 'Joko Widodo', pekerjaan: 'Wiraswasta', tempat_lahir: 'Solo', tanggal_lahir: '1980-06-21', usia: 46, agama: 'Islam', status_perkawinan: 'Kawin', jenis_kelamin: 'Laki-laki', suku: 'Jawa', anggota_pujakesuma: true },
  { id: '105', no_kk: '1275010203040003', nik: '1275010203040103', nama_lengkap: 'Sri Mulyani', pekerjaan: 'Karyawan Swasta', tempat_lahir: 'Medan', tanggal_lahir: '1982-10-10', usia: 43, agama: 'Kristen', status_perkawinan: 'Kawin', jenis_kelamin: 'Perempuan', suku: 'Jawa', anggota_pujakesuma: false }
]

// Dummy chat conversations
const dummyChats = [
  { id: 'chat1', sender: 'Budi (Petugas Lapangan)', message: 'Izin pak, KK di Berngam koordinatnya agak bergeser karena mendung. Sudah saya revisi.', time: '10:05' },
  { id: 'chat2', sender: 'Santi (Pengawas)', message: 'Untuk data Joko Widodo mohon dicek kembali lampiran KTP-nya, fotonya buram.', time: '09:40' },
  { id: 'chat3', sender: 'Raden Hermawan (Anda)', message: 'Siap, tolong semua petugas pastikan foto rumah tampak jelas dan pencahayaan cukup.', time: 'Kemarin' }
]

export default function App() {
  const [session, setSession] = useState<any>(null)
  const [view, setView] = useState<'landing' | 'login' | 'dashboard'>('landing')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [appLoading, setAppLoading] = useState(true)

  const [activeTab, setActiveTab] = useState<'ringkasan' | 'keluarga' | 'individu' | 'chat' | 'laporan'>('ringkasan')
  const [searchQuery, setSearchQuery] = useState('')
  const [families, setFamilies] = useState<any[]>([])
  const [individuals, setIndividuals] = useState<any[]>([])
  const [stats, setStats] = useState<any>({
    totalKeluarga: 0,
    totalIndividu: 0,
    totalVerified: 0,
    totalPending: 0,
    kecamatanDistribution: {},
    sukuDistribution: {},
    usiaDistribution: {}
  })
  
  const [chatText, setChatText] = useState('')
  const [activeChats, setActiveChats] = useState<any[]>([])
  const [currentRoomId, setCurrentRoomId] = useState<string>('')

  // 1. Check Auth state on Mount & Listen to updates
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      if (session) {
        setView('dashboard')
      }
      setAppLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      if (session) {
        setView('dashboard')
      } else {
        setView('landing')
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  // 2. Fetch all real data from live Supabase DB when authenticated
  const fetchDashboardData = async () => {
    try {
      // A. Fetch stats via stored function RPC
      const { data: statsJson, error: statsErr } = await supabase.rpc('get_dashboard_stats')
      if (!statsErr && statsJson) {
        setStats(statsJson)
      } else {
        // Fallback to empty stats if DB function has error
        setStats({
          totalKeluarga: 0,
          totalIndividu: 0,
          totalVerified: 0,
          totalPending: 0,
          kecamatanDistribution: {},
          sukuDistribution: {},
          usiaDistribution: {}
        })
      }

      // B. Fetch keluarga list
      const { data: familyList, error: famErr } = await supabase
        .from('keluarga')
        .select('*')
        .order('created_at', { ascending: false })
      
      if (!famErr && familyList) {
        setFamilies(familyList)
      } else {
        setFamilies([])
      }

      // C. Fetch individu list from view (contains usia)
      const { data: indList, error: indErr } = await supabase
        .from('v_individu')
        .select('*')
        .order('created_at', { ascending: false })
      
      if (!indErr && indList) {
        setIndividuals(indList)
      } else {
        setIndividuals([])
      }
    } catch (err) {
      console.error("Failed to load real data:", err)
    }
  }

  // Reload data when session changes
  useEffect(() => {
    if (session) {
      fetchDashboardData()
      ensureRoomAndChat()
    }
  }, [session])

  // 3. Ensure a chat room exists and subscribe to realtime messages
  const ensureRoomAndChat = async () => {
    try {
      // Find or create default group room
      let { data: rooms } = await supabase.from('chat_rooms').select('id').eq('is_group', true).limit(1)
      let roomId = ''
      if (rooms && rooms.length > 0) {
        roomId = rooms[0].id
      } else {
        const { data: newRoom } = await supabase.from('chat_rooms').insert({ name: 'Grup Pujakesuma', is_group: true }).select().single()
        if (newRoom) roomId = newRoom.id
      }
      setCurrentRoomId(roomId)

      if (roomId) {
        // Fetch existing messages
        const { data: messages } = await supabase
          .from('chat_messages')
          .select('id, content, created_at, sender_id')
          .eq('room_id', roomId)
          .order('created_at', { ascending: true })

        // Load profiles to show names
        const { data: profiles } = await supabase.from('profiles').select('id, full_name')
        const nameMap = new Map(profiles?.map(p => [p.id, p.full_name]) || [])

        if (messages) {
          const formatted = messages.map(m => ({
            id: m.id,
            sender: nameMap.get(m.sender_id) || 'Petugas Lapangan',
            message: m.content,
            time: new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
          }))
          setActiveChats(formatted)
        } else {
          setActiveChats([])
        }

        // Subscribe to realtime database changes for new messages
        const channel = supabase.channel('chat_room_changes')
          .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'chat_messages', filter: `room_id=eq.${roomId}` }, async (payload) => {
            const senderId = payload.new.sender_id
            const { data: profile } = await supabase.from('profiles').select('full_name').eq('id', senderId).single()
            const senderName = profile?.full_name || 'Petugas Lapangan'
            
            const newMsg = {
              id: payload.new.id,
              sender: senderName,
              message: payload.new.content,
              time: new Date(payload.new.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            }
            setActiveChats(prev => [...prev, newMsg])
          })
          .subscribe()

        return () => {
          channel.unsubscribe()
        }
      }
    } catch (err) {
      console.error("Chat setup failed:", err)
      setActiveChats([])
    }
  }

  // 4. Handle login
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setErrorMessage('')
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })
      if (error) throw error
    } catch (error: any) {
      setErrorMessage(error.message || 'Gagal masuk. Silakan periksa kembali email dan password Anda.')
    } finally {
      setLoading(false)
    }
  }

  // 5. Handle logout
  const handleLogout = async () => {
    await supabase.auth.signOut()
    setView('landing')
  }

  // 6. Update keluarga status on Supabase
  const handleUpdateStatus = async (id: string, newStatus: 'draft' | 'pending' | 'verified' | 'rejected') => {
    try {
      const { error } = await supabase
        .from('keluarga')
        .update({ status: newStatus })
        .eq('id', id)
      
      if (error) throw error
      fetchDashboardData() // Reload table and counters
    } catch (err: any) {
      alert("Gagal mengupdate status: " + err.message)
    }
  }

  // 7. Send chat message to Supabase
  const handleSendChat = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!chatText.trim() || !currentRoomId || !session) return
    try {
      const { error } = await supabase
        .from('chat_messages')
        .insert({
          room_id: currentRoomId,
          sender_id: session.user.id,
          content: chatText
        })
      if (error) throw error
      setChatText('')
    } catch (err: any) {
      alert("Gagal mengirim pesan: " + err.message)
    }
  }

  // Filtered lists based on search
  const filteredFamilies = families.filter(f => 
    f.nama_kepala_keluarga.toLowerCase().includes(searchQuery.toLowerCase()) ||
    f.no_kk.includes(searchQuery) ||
    f.kelurahan.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const filteredIndividu = individuals.filter(i => 
    i.nama_lengkap.toLowerCase().includes(searchQuery.toLowerCase()) ||
    i.nik.includes(searchQuery) ||
    i.suku.toLowerCase().includes(searchQuery.toLowerCase())
  )

  // Render Loader if reading session
  if (appLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', backgroundColor: 'var(--bg-deep)' }}>
        <div style={{ color: 'var(--accent-gold)', fontFamily: 'var(--font-heading)', fontSize: '1.2rem' }}>Memuat Sistem...</div>
      </div>
    )
  }

  // Render Landing Page
  if (view === 'landing') {
    return <LandingPage onEnterAdmin={() => setView('login')} />
  }

  // Render Login Page if not authenticated but trying to access dashboard
  if (view === 'login' && !session) {
    return (
      <div className="login-container">
        <div className="login-card">
          <div className="login-logo">
            <Users size={28} />
          </div>
          <h2>Masuk PUJAKESUMA</h2>
          <p>Panel Admin & Pengawas Kota Binjai</p>
          
          <form onSubmit={handleLogin} className="login-form">
            {errorMessage && (
              <div style={{ 
                backgroundColor: 'rgba(239, 68, 68, 0.1)', 
                border: '1px solid var(--danger)', 
                color: 'var(--danger)', 
                padding: '10px 14px', 
                borderRadius: '8px', 
                fontSize: '0.85rem',
                marginBottom: '10px'
              }}>
                {errorMessage}
              </div>
            )}
            
            <div className="form-group">
              <label>Email Address</label>
              <input 
                type="email" 
                placeholder="nama@pujakesuma.id" 
                className="search-input" 
                style={{ paddingLeft: '16px' }}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            
            <div className="form-group">
              <label>Kata Sandi</label>
              <input 
                type="password" 
                placeholder="â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢" 
                className="search-input" 
                style={{ paddingLeft: '16px' }}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            
            <button type="submit" className="btn btn-gold w-full" style={{ justifyContent: 'center', marginTop: '10px' }} disabled={loading}>
              {loading ? 'Menghubungkan...' : 'Masuk Panel'}
            </button>

            <button 
              type="button" 
              onClick={() => setView('landing')} 
              className="btn btn-outline w-full" 
              style={{ justifyContent: 'center', marginTop: '10px' }}
            >
              Kembali ke Beranda
            </button>
          </form>
        </div>
      </div>
    )
  }

  const userEmail = session ? session.user.email : '';

  return (
    <div className="admin-layout">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="sidebar-logo-circle">
            <Users size={20} className="sidebar-logo-icon" />
          </div>
          <div>
            <h1 className="sidebar-title-text">PUJAKESUMA</h1>
            <span className="sidebar-subtitle">Kota Binjai</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          <a 
            href="#" 
            className={`sidebar-link ${activeTab === 'ringkasan' ? 'active' : ''}`}
            onClick={() => { setActiveTab('ringkasan'); setSearchQuery(''); }}
          >
            <Home size={18} /> Ringkasan
          </a>
          <a 
            href="#" 
            className={`sidebar-link ${activeTab === 'keluarga' ? 'active' : ''}`}
            onClick={() => { setActiveTab('keluarga'); setSearchQuery(''); }}
          >
            <Users size={18} /> Data Keluarga
          </a>
          <a 
            href="#" 
            className={`sidebar-link ${activeTab === 'individu' ? 'active' : ''}`}
            onClick={() => { setActiveTab('individu'); setSearchQuery(''); }}
          >
            <UserCheck size={18} /> Data Individu
          </a>
          <a 
            href="#" 
            className={`sidebar-link ${activeTab === 'chat' ? 'active' : ''}`}
            onClick={() => { setActiveTab('chat'); setSearchQuery(''); }}
          >
            <MessageSquare size={18} /> Chat Realtime
          </a>
          <a 
            href="#" 
            className={`sidebar-link ${activeTab === 'laporan' ? 'active' : ''}`}
            onClick={() => { setActiveTab('laporan'); setSearchQuery(''); }}
          >
            <FileText size={18} /> Cetak Laporan
          </a>
        </nav>

        <div className="sidebar-footer">
          <div className="user-profile-widget">
            <img 
              src={dummyAdminProfile.avatar_url} 
              alt={userEmail} 
              className="user-avatar"
            />
            <div className="user-info-text">
              <span className="user-name" title={userEmail}>{userEmail}</span>
              <span className="user-role-badge">ADMIN</span>
            </div>
          </div>
        </div>
      </aside>

      {/* Main content pane */}
      <main className="main-content">
        <header className="topbar">
          <h2 className="topbar-title">
            {activeTab === 'ringkasan' && 'Dashboard Overview'}
            {activeTab === 'keluarga' && 'Pengelolaan Data Keluarga'}
            {activeTab === 'individu' && 'Daftar Anggota Keluarga / Individu'}
            {activeTab === 'chat' && 'Ruang Komunikasi Realtime'}
            {activeTab === 'laporan' && 'Pusat Dokumen & Ekspor Laporan'}
          </h2>
          <div className="topbar-actions">
            <div className="notifications-bell">
              <Bell size={20} />
              <span className="bell-badge"></span>
            </div>
            <button className="btn btn-outline" style={{ padding: '8px 12px' }} onClick={handleLogout}>
              <LogOut size={16} /> Keluar
            </button>
          </div>
        </header>

        <div className="content-pane">
          {/* TAB 1: SUMMARY OVERVIEW */}
          {activeTab === 'ringkasan' && (
            <div>
              {/* Summary Cards */}
              <div className="stats-grid">
                <div className="stat-card">
                  <div className="stat-info">
                    <h5>Total Keluarga</h5>
                    <span className="stat-value">{initialStats.totalKeluarga}</span>
                  </div>
                  <div className="stat-icon-box"><Home size={22} /></div>
                </div>
                <div className="stat-card">
                  <div className="stat-info">
                    <h5>Total Individu</h5>
                    <span className="stat-value">{initialStats.totalIndividu}</span>
                  </div>
                  <div className="stat-icon-box"><Users size={22} /></div>
                </div>
                <div className="stat-card">
                  <div className="stat-info">
                    <h5>Terverifikasi</h5>
                    <span className="stat-value" style={{ color: 'var(--success)' }}>{initialStats.totalVerified}</span>
                  </div>
                  <div className="stat-icon-box" style={{ color: 'var(--success)', backgroundColor: 'rgba(16,185,129,0.1)' }}><CheckCircle size={22} /></div>
                </div>
                <div className="stat-card">
                  <div className="stat-info">
                    <h5>Menunggu Review</h5>
                    <span className="stat-value" style={{ color: 'var(--warning)' }}>{initialStats.totalPending}</span>
                  </div>
                  <div className="stat-icon-box" style={{ color: 'var(--warning)', backgroundColor: 'rgba(245,158,11,0.1)' }}><Clock size={22} /></div>
                </div>
              </div>

              {/* Visuals Panels */}
              <div className="visuals-grid">
                <div className="dashboard-panel">
                  <div className="panel-header">
                    <h3 className="panel-title">Sebaran Data per Kecamatan</h3>
                  </div>
                  <div className="panel-chart">
                    {/* SVG Visualization */}
                    <svg viewBox="0 0 400 220" style={{ width: '100%' }}>
                      <line x1="40" y1="10" x2="40" y2="180" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
                      <line x1="40" y1="180" x2="380" y2="180" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
                      
                      {/* Bars */}
                      <rect x="60" y="50" width="30" height="130" fill="var(--accent-gold)" rx="2" />
                      <text x="75" y="198" fill="var(--text-gray)" font-size="10" text-anchor="middle">Binjai Utara</text>
                      <text x="75" y="42" fill="#fff" font-size="10" text-anchor="middle">130 KK</text>

                      <rect x="120" y="90" width="30" height="90" fill="var(--primary-maroon)" rx="2" />
                      <text x="135" y="198" fill="var(--text-gray)" font-size="10" text-anchor="middle">Binjai Barat</text>
                      <text x="135" y="82" fill="#fff" font-size="10" text-anchor="middle">90 KK</text>

                      <rect x="180" y="70" width="30" height="110" fill="var(--accent-gold)" rx="2" />
                      <text x="195" y="198" fill="var(--text-gray)" font-size="10" text-anchor="middle">Binjai Timur</text>
                      <text x="195" y="62" fill="#fff" font-size="10" text-anchor="middle">110 KK</text>

                      <rect x="240" y="110" width="30" height="70" fill="var(--primary-maroon)" rx="2" />
                      <text x="255" y="198" fill="var(--text-gray)" font-size="10" text-anchor="middle">Binjai Selatan</text>
                      <text x="255" y="102" fill="#fff" font-size="10" text-anchor="middle">70 KK</text>

                      <rect x="300" y="130" width="30" height="50" fill="var(--accent-gold)" rx="2" />
                      <text x="315" y="198" fill="var(--text-gray)" font-size="10" text-anchor="middle">Binjai Kota</text>
                      <text x="315" y="122" fill="#fff" font-size="10" text-anchor="middle">50 KK</text>
                    </svg>
                  </div>
                </div>

                <div className="dashboard-panel">
                  <div className="panel-header">
                    <h3 className="panel-title">Sebaran Usia Anggota</h3>
                  </div>
                  <div className="panel-chart">
                    {/* SVG Donut Chart */}
                    <svg viewBox="0 0 200 200" style={{ maxHeight: '200px' }}>
                      <circle cx="100" cy="100" r="70" fill="none" stroke="var(--primary-maroon)" stroke-width="16" stroke-dasharray="220 440" stroke-dashoffset="0" />
                      <circle cx="100" cy="100" r="70" fill="none" stroke="var(--accent-gold)" stroke-width="16" stroke-dasharray="132 440" stroke-dashoffset="-220" />
                      <circle cx="100" cy="100" r="70" fill="none" stroke="#3b82f6" stroke-width="16" stroke-dasharray="88 440" stroke-dashoffset="-352" />
                      <circle cx="100" cy="100" r="50" fill="var(--bg-card)" />
                      
                      <text x="100" y="98" fill="#fff" font-size="11" font-weight="bold" text-anchor="middle">Demografi</text>
                      <text x="100" y="115" fill="var(--accent-gold)" font-size="9" text-anchor="middle">Umur Warga</text>
                    </svg>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.8rem', paddingLeft: '16px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ width: '10px', height: '10px', backgroundColor: 'var(--primary-maroon)', borderRadius: '50%' }}></span>
                        <span>Dewasa (50%)</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ width: '10px', height: '10px', backgroundColor: 'var(--accent-gold)', borderRadius: '50%' }}></span>
                        <span>Anak & Remaja (30%)</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ width: '10px', height: '10px', backgroundColor: '#3b82f6', borderRadius: '50%' }}></span>
                        <span>Lansia (20%)</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: DATA KELUARGA */}
          {activeTab === 'keluarga' && (
            <div>
              <div className="table-controls">
                <div className="search-input-wrapper">
                  <Search size={16} className="search-icon" />
                  <input 
                    type="text" 
                    placeholder="Cari kepala keluarga, kelurahan, or KK..." 
                    className="search-input"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                </div>
                <div className="btn-group">
                  <button className="btn btn-outline"><Filter size={16} /> Filter</button>
                  <button className="btn btn-gold" onClick={() => alert('Fungsi tambah data keluarga manual')}><Home size={16} /> Tambah Keluarga</button>
                </div>
              </div>

              <div className="pujakesuma-table-wrapper">
                <table className="pujakesuma-table">
                  <thead>
                    <tr>
                      <th>Nomor KK</th>
                      <th>Nama Kepala Keluarga</th>
                      <th>NIK Kepala</th>
                      <th>Alamat Terdata</th>
                      <th>Kelurahan</th>
                      <th>Kecamatan</th>
                      <th>Status</th>
                      <th>Aksi Approval (Pengawas/Admin)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredFamilies.map((family) => (
                      <tr key={family.id}>
                        <td>{family.no_kk}</td>
                        <td style={{ color: 'var(--text-white)', fontWeight: 600 }}>{family.nama_kepala_keluarga}</td>
                        <td>{family.nik_kepala_keluarga}</td>
                        <td>{family.alamat}</td>
                        <td>{family.kelurahan}</td>
                        <td>{family.kecamatan}</td>
                        <td>
                          <span className={`badge badge-${family.status}`}>
                            {family.status}
                          </span>
                        </td>
                        <td>
                          <div style={{ display: 'flex', gap: '6px' }}>
                            <button 
                              className="btn btn-primary" 
                              style={{ padding: '6px 10px', fontSize: '0.75rem', backgroundColor: 'var(--success)' }}
                              onClick={() => handleUpdateStatus(family.id, 'verified')}
                            >
                              Setuju
                            </button>
                            <button 
                              className="btn btn-outline" 
                              style={{ padding: '6px 10px', fontSize: '0.75rem', borderColor: 'var(--danger)', color: 'var(--danger)' }}
                              onClick={() => handleUpdateStatus(family.id, 'rejected')}
                            >
                              Tolak
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 3: DATA INDIVIDU */}
          {activeTab === 'individu' && (
            <div>
              <div className="table-controls">
                <div className="search-input-wrapper">
                  <Search size={16} className="search-icon" />
                  <input 
                    type="text" 
                    placeholder="Cari NIK, nama lengkap, suku..." 
                    className="search-input"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                </div>
                <div className="btn-group">
                  <button className="btn btn-outline" onClick={() => alert('Membuat laporan individu')}><Download size={16} /> Unduh CSV</button>
                </div>
              </div>

              <div className="pujakesuma-table-wrapper">
                <table className="pujakesuma-table">
                  <thead>
                    <tr>
                      <th>NIK</th>
                      <th>Nama Lengkap</th>
                      <th>Pekerjaan</th>
                      <th>Tempat / Tgl Lahir</th>
                      <th>Usia</th>
                      <th>Agama</th>
                      <th>Hubungan Keluarga</th>
                      <th>Suku</th>
                      <th>Anggota Pujakesuma</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredIndividu.map((ind) => (
                      <tr key={ind.id}>
                        <td>{ind.nik}</td>
                        <td style={{ color: 'var(--text-white)', fontWeight: 600 }}>{ind.nama_lengkap}</td>
                        <td>{ind.pekerjaan}</td>
                        <td>{ind.tempat_lahir}, {ind.tanggal_lahir}</td>
                        <td style={{ fontWeight: 'bold', color: 'var(--accent-gold)' }}>{ind.usia} Tahun</td>
                        <td>{ind.agama}</td>
                        <td>{ind.status_perkawinan}</td>
                        <td>{ind.suku}</td>
                        <td>
                          <span style={{ color: ind.anggota_pujakesuma ? 'var(--success)' : 'var(--text-muted)' }}>
                            {ind.anggota_pujakesuma ? 'Ya' : 'Tidak'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* TAB 4: CHAT REALTIME */}
          {activeTab === 'chat' && (
            <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '24px', height: '480px' }}>
              <div className="dashboard-panel" style={{ display: 'flex', flexDirection: 'column', height: '100%', padding: '20px' }}>
                <div style={{ flexGrow: 1, overflowY: 'auto', marginBottom: '20px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  {activeChats.map(c => (
                    <div key={c.id} style={{ alignSelf: c.sender.includes('Anda') ? 'flex-end' : 'flex-start', maxWidth: '80%' }}>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '4px', textAlign: c.sender.includes('Anda') ? 'right' : 'left' }}>
                        {c.sender} â€¢ {c.time}
                      </div>
                      <div style={{ 
                        padding: '12px 16px', 
                        borderRadius: '12px', 
                        backgroundColor: c.sender.includes('Anda') ? 'var(--primary-maroon)' : 'rgba(255,255,255,0.03)',
                        border: c.sender.includes('Anda') ? '1px solid rgba(255,255,255,0.1)' : '1px solid var(--border-glass)',
                        color: '#fff'
                      }}>
                        {c.message}
                      </div>
                    </div>
                  ))}
                </div>
                <form onSubmit={handleSendChat} style={{ display: 'flex', gap: '12px' }}>
                  <input 
                    type="text" 
                    placeholder="Tulis pesan untuk petugas lapangan..." 
                    className="search-input"
                    style={{ paddingLeft: '16px' }}
                    value={chatText}
                    onChange={(e) => setChatText(e.target.value)}
                  />
                  <button type="submit" className="btn btn-gold"><MessageSquare size={16} /> Kirim</button>
                </form>
              </div>

              <div className="dashboard-panel">
                <h4 style={{ color: 'var(--accent-gold)', marginBottom: '16px' }}>Status Pengguna Online</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span style={{ width: '8px', height: '8px', backgroundColor: 'var(--success)', borderRadius: '50%' }}></span>
                    <span style={{ color: '#fff', fontSize: '0.9rem' }}>Budi Hartanto (Petugas Lapangan)</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span style={{ width: '8px', height: '8px', backgroundColor: 'var(--success)', borderRadius: '50%' }}></span>
                    <span style={{ color: '#fff', fontSize: '0.9rem' }}>Santi Mandasari (Pengawas)</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span style={{ width: '8px', height: '8px', backgroundColor: 'var(--success)', borderRadius: '50%' }}></span>
                    <span style={{ color: '#fff', fontSize: '0.9rem' }}>Raden Hermawan (Admin/Anda)</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: PRINT REPORTS */}
          {activeTab === 'laporan' && (
            <div className="dashboard-panel" style={{ maxWidth: '700px', margin: '0 auto' }}>
              <h3 style={{ color: 'var(--accent-gold)', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Printer /> Konfigurasi Ekspor Laporan
              </h3>
              <p style={{ fontSize: '0.9rem', color: 'var(--text-gray)', marginBottom: '32px' }}>
                Silakan pilih kategori filter untuk membatasi data laporan yang akan diekspor dalam bentuk PDF resmi DPD Pujakesuma Kota Binjai.
              </p>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                <div className="form-group">
                  <label>Jenis Laporan</label>
                  <select className="custom-select" style={{ backgroundColor: 'var(--bg-deep)' }}>
                    <option>Rekapitulasi Keluarga Full (Seluruh Anggota)</option>
                    <option>Hanya Individu (Perseorangan)</option>
                    <option>Laporan Ringkasan Statistik Organisasi</option>
                  </select>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label>Filter Suku</label>
                    <select className="custom-select" style={{ backgroundColor: 'var(--bg-deep)' }}>
                      <option>Suku Jawa (Default Utama)</option>
                      <option>Semua Suku</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Filter Agama</label>
                    <select className="custom-select" style={{ backgroundColor: 'var(--bg-deep)' }}>
                      <option>Semua Agama</option>
                      <option>Islam</option>
                      <option>Kristen</option>
                      <option>Katolik</option>
                      <option>Budha</option>
                      <option>Hindu</option>
                    </select>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div className="form-group">
                    <label>Kecamatan</label>
                    <select className="custom-select" style={{ backgroundColor: 'var(--bg-deep)' }}>
                      <option>Semua Kecamatan</option>
                      <option>Binjai Kota</option>
                      <option>Binjai Utara</option>
                      <option>Binjai Barat</option>
                      <option>Binjai Timur</option>
                      <option>Binjai Selatan</option>
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Anggota Pujakesuma</label>
                    <select className="custom-select" style={{ backgroundColor: 'var(--bg-deep)' }}>
                      <option>Semua Status</option>
                      <option>Ya (Anggota Aktif)</option>
                      <option>Tidak</option>
                    </select>
                  </div>
                </div>

                <div style={{ marginTop: '24px', display: 'flex', gap: '12px' }}>
                  <button className="btn btn-gold" onClick={() => alert('Sedang mencetak laporan PDF Pujakesuma... (Sistem PDF compiler aktif)')}>
                    <Printer size={16} /> Print / Cetak Laporan PDF
                  </button>
                  <button className="btn btn-outline" onClick={() => alert('Mengekspor data ke format Excel/CSV...')}>
                    <Download size={16} /> Ekspor Data Excel
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}

