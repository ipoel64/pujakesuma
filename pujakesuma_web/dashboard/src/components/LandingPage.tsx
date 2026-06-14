import { useEffect, useRef, useState } from 'react'
import { Users } from 'lucide-react'
import L from 'leaflet'
import { supabase } from '../lib/supabase'

interface LandingPageProps {
  onEnterAdmin: () => void
}

export default function LandingPage({ onEnterAdmin }: LandingPageProps) {
  const mapRef = useRef<any>(null)
  const [stats, setStats] = useState({ keluarga: 0, individu: 0 })

  useEffect(() => {
    // Fetch real counts from Supabase dynamically
    const fetchPublicStats = async () => {
      try {
        const { count: keluargaCount } = await supabase
          .from('keluarga')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'verified')

        const { count: individuCount } = await supabase
          .from('individu')
          .select('*', { count: 'exact', head: true })

        setStats({
          keluarga: keluargaCount || 0,
          individu: individuCount || 0
        })
      } catch (err) {
        console.error("Failed to fetch public counts:", err)
      }
    }
    fetchPublicStats()
  }, [])

  useEffect(() => {
    if (!mapRef.current) {
      // Center of Kota Binjai, Sumatera Utara
      const binjaiCenter: [number, number] = [3.6063, 98.4897];
      const map = L.map("landingLeafletMap", {
        center: binjaiCenter,
        zoom: 13,
        zoomControl: true
      });

      // Dark theme map tiles
      L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 20
      }).addTo(map);

      const markerOptions = {
        radius: 8,
        fillColor: "#D4AF37",
        color: "#800020",
        weight: 2,
        opacity: 1,
        fillOpacity: 0.8
      };

      const markerLayer = L.layerGroup().addTo(map);

      // Load verified families from live Supabase DB
      const loadRealMarkers = async () => {
        try {
          const { data: families } = await supabase
            .from('keluarga')
            .select('nama_kepala_keluarga, kecamatan, kelurahan, latitude, longitude, no_kk')
            .eq('status', 'verified')
            .not('latitude', 'is', null)
            .not('longitude', 'is', null)

          const displayList = families || [];

          displayList.forEach((family: any) => {
            const popupContent = `
              <div style="font-family: 'Plus Jakarta Sans', sans-serif; color: #fff; padding: 2px;">
                <h4 style="color: #D4AF37; margin: 0 0 6px 0; font-size: 13px; font-weight: bold;">
                  Keluarga Bp. ${family.nama_kepala_keluarga}
                </h4>
                <p style="margin: 0 0 4px 0; font-size: 11px; color: #ccc;"><strong>Kecamatan:</strong> ${family.kecamatan}</p>
                <p style="margin: 0 0 4px 0; font-size: 11px; color: #ccc;"><strong>Kelurahan:</strong> ${family.kelurahan}</p>
                <span style="display: inline-block; background-color: rgba(128, 0, 32, 0.2); border: 1px solid rgba(128, 0, 32, 0.5); padding: 2px 6px; border-radius: 4px; font-size: 9px; color: #FFE07D; font-weight: bold; margin-top: 4px;">Terverifikasi</span>
              </div>
            `;

            L.circleMarker([family.latitude, family.longitude], markerOptions)
              .bindPopup(popupContent)
              .addTo(markerLayer);
          });
        } catch (err) {
          console.error("Error loading map markers:", err)
        }
      }

      loadRealMarkers();
      mapRef.current = map;
    }

    return () => {
      if (mapRef.current) {
        mapRef.current.remove()
        mapRef.current = null
      }
    }
  }, [])

  return (
    <div style={{ backgroundColor: 'var(--bg-body)', minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      
      {/* Header */}
      <header className="main-header" style={{ position: 'sticky' }}>
        <div className="container header-container">
          <div className="logo-area">
            <div className="logo-gold-circle">
              <Users size={16} style={{ color: 'var(--primary-maroon)' }} />
            </div>
            <div className="logo-text">
              <span className="logo-title">PUJAKESUMA</span>
              <span className="logo-desc">Kota Binjai</span>
            </div>
          </div>
          <nav className="nav-menu">
            <a href="#hero" className="nav-link active">Beranda</a>
            <a href="#profil" className="nav-link">Profil</a>
            <a href="#sebaran" className="nav-link">Peta Sebaran</a>
            <button onClick={onEnterAdmin} className="btn-login-nav" style={{ cursor: 'pointer', border: 'none' }}>
              Masuk Admin
            </button>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <section id="hero" className="hero-section" style={{ minHeight: '75vh', padding: '80px 0', display: 'flex', alignItems: 'center' }}>
        <div className="hero-overlay"></div>
        <div className="container hero-container">
          <div className="hero-grid">
            <div className="hero-content">
              <div className="badge-pujakesuma">
                Putra Jawa Kelahiran Sumatera
              </div>
              <h1 className="hero-title" style={{ fontSize: '3.5rem' }}>Guyub Rukun Mbangun <span className="gold-text">Binjai</span></h1>
              <p className="hero-lead">Menyatukan, mendata, dan memberdayakan segenap putra-putri keturunan Jawa di Kota Binjai untuk berkontribusi aktif dalam pembangunan daerah yang berbudaya.</p>
              <div className="hero-actions">
                <a href="#sebaran" className="btn-primary-gold">Lihat Peta Sebaran</a>
                <button onClick={onEnterAdmin} className="btn-secondary-outline" style={{ cursor: 'pointer' }}>Masuk Panel Admin</button>
              </div>
            </div>
            <div className="hero-visual">
              <svg className="gunungan-svg" viewBox="0 0 500 600" width="100%" height="100%" style={{ maxHeight: '420px' }}>
                <defs>
                  <linearGradient id="goldGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stop-color="#FFE07D" />
                    <stop offset="50%" stop-color="#D4AF37" />
                    <stop offset="100%" stop-color="#8A6605" />
                  </linearGradient>
                </defs>
                <path d="M250 40 L430 380 L330 380 L380 500 L120 500 L170 380 L70 380 Z" fill="none" stroke="url(#goldGrad)" stroke-width="4" />
                <path d="M250 500 L250 200" stroke="url(#goldGrad)" stroke-width="8" />
                <path d="M250 380 Q320 320 380 340 M250 380 Q180 320 120 340" fill="none" stroke="url(#goldGrad)" stroke-width="4" />
                <path d="M250 300 Q330 230 350 180 M250 300 Q170 230 150 180" fill="none" stroke="url(#goldGrad)" stroke-width="4" />
                <rect x="100" y="500" width="300" height="20" rx="10" fill="url(#goldGrad)" />
              </svg>
            </div>
          </div>
        </div>
      </section>

      {/* Profil Section */}
      <section id="profil" className="profile-section" style={{ padding: '60px 0' }}>
        <div className="container">
          <div className="section-title-wrapper text-center">
            <span className="section-tag">NILAI UTAMA</span>
            <h2 className="section-title">Mengenal Pujakesuma</h2>
            <div className="title-underline"></div>
          </div>
          <div className="profile-grid">
            <div className="profile-card">
              <div className="card-batik-bg"></div>
              <h3>Guyub Rukun</h3>
              <p>Membina kerukunan, gotong royong, dan kebersamaan yang erat antar sesama keturunan Jawa di tanah perantauan Sumatera.</p>
            </div>
            <div className="profile-card">
              <div className="card-batik-bg"></div>
              <h3>Migunani</h3>
              <p>Menjadi pribadi dan organisasi yang bermanfaat bagi masyarakat sekitar serta mendukung kemajuan Kota Binjai secara berkesinambungan.</p>
            </div>
            <div className="profile-card">
              <div className="card-batik-bg"></div>
              <h3>Melestarikan Budaya</h3>
              <p>Menjaga nilai-nilai luhur kebudayaan Jawa, seperti sopan santun (unggah-ungguh), kesenian, dan kearifan lokal agar tetap eksis.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Peta Sebaran */}
      <section id="sebaran" className="maps-section" style={{ padding: '60px 0' }}>
        <div className="container">
          <div className="section-title-wrapper text-center">
            <span className="section-tag">INTERAKTIF</span>
            <h2 className="section-title">Peta Sebaran Data Warga</h2>
            <div className="title-underline"></div>
          </div>
          <div className="map-wrapper" style={{ gridTemplateColumns: '1fr', padding: '16px' }}>
            <div className="map-container-inner" style={{ borderRadius: '12px', overflow: 'hidden' }}>
              <div id="landingLeafletMap" style={{ height: '400px', width: '100%' }}></div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="main-footer" style={{ marginTop: 'auto' }}>
        <div className="container footer-bottom" style={{ justifyContent: 'center' }}>
          <p>&copy; 2026 DPD PUJAKESUMA Kota Binjai. Hak Cipta Dilindungi Undang-Undang. {stats.keluarga > 0 && `(Terdata: ${stats.keluarga} Keluarga & ${stats.individu} Individu)`}</p>
        </div>
      </footer>
    </div>
  )
}
