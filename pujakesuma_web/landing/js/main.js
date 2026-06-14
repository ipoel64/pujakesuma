document.addEventListener("DOMContentLoaded", () => {
    // 1. Remove Loader Screen
    const loader = document.getElementById("loader-wrapper");
    setTimeout(() => {
        loader.style.opacity = "0";
        setTimeout(() => {
            loader.style.display = "none";
        }, 500);
    }, 1200);

    // 2. Mobile Nav Toggle
    const hamburgerBtn = document.getElementById("hamburgerBtn");
    const navMenu = document.getElementById("navMenu");

    hamburgerBtn.addEventListener("click", () => {
        navMenu.classList.toggle("active");
        const icon = hamburgerBtn.querySelector("i");
        if (navMenu.classList.contains("active")) {
            icon.className = "fa-solid fa-xmark";
        } else {
            icon.className = "fa-solid fa-bars";
        }
    });

    // Close mobile nav on click
    navMenu.querySelectorAll(".nav-link").forEach(link => {
        link.addEventListener("click", () => {
            navMenu.classList.remove("active");
            hamburgerBtn.querySelector("i").className = "fa-solid fa-bars";
        });
    });

    // 3. GSAP Animations
    if (typeof gsap !== "undefined") {
        gsap.registerPlugin(ScrollTrigger);

        // Hero Content Entry
        gsap.from(".hero-content > *", {
            y: 40,
            opacity: 0,
            duration: 1,
            stagger: 0.15,
            ease: "power3.out",
            delay: 1.5
        });

        // Gunungan silhouette animation on load
        gsap.from(".gunungan-svg", {
            scale: 0.8,
            opacity: 0,
            duration: 1.5,
            ease: "back.out(1.7)",
            delay: 1.3
        });

        // Gunungan breathing animation
        gsap.to(".gunungan-svg", {
            y: -10,
            duration: 3,
            repeat: -1,
            yoyo: true,
            ease: "power1.inOut"
        });

        // Profile Cards entry on scroll
        gsap.from(".profile-card", {
            scrollTrigger: {
                trigger: ".profile-grid",
                start: "top 80%"
            },
            y: 50,
            opacity: 0,
            duration: 0.8,
            stagger: 0.2,
            ease: "power2.out"
        });

        // About section scroll trigger
        gsap.from(".about-img-frame", {
            scrollTrigger: {
                trigger: ".about-pujakesuma-detailed",
                start: "top 85%"
            },
            x: -50,
            opacity: 0,
            duration: 1,
            ease: "power2.out"
        });

        gsap.from(".about-text-content > *", {
            scrollTrigger: {
                trigger: ".about-pujakesuma-detailed",
                start: "top 85%"
            },
            x: 50,
            opacity: 0,
            duration: 1,
            stagger: 0.15,
            ease: "power2.out"
        });
    }

    // 4. Map Setup (Leaflet.js)
    // Center of Kota Binjai, Sumatera Utara
    const binjaiCenter = [3.6063, 98.4897];
    const map = L.map("leafletMap", {
        center: binjaiCenter,
        zoom: 13,
        zoomControl: true
    });

    // Add Dark Matter/CartoDB tiles (dark theme map tiles look amazing)
    L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 20
    }).addTo(map);

    // Dummy coordinate data representing families around Binjai for landing page demo
    const dummyFamilies = [
        { id: 1, kepala: "Suwarno", nik: "1275010203040001", kecamatan: "Binjai Kota", kelurahan: "Berngam", coords: [3.6010, 98.4850], anggota: 4, suku: "Jawa" },
        { id: 2, kepala: "Joko Widodo", nik: "1275010203040002", kecamatan: "Binjai Utara", kelurahan: "Kebun Lada", coords: [3.6280, 98.4950], anggota: 5, suku: "Jawa" },
        { id: 3, kepala: "Sri Mulyani", nik: "1275010203040003", kecamatan: "Binjai Barat", kelurahan: "Suka Maju", coords: [3.6120, 98.4650], anggota: 3, suku: "Jawa" },
        { id: 4, kepala: "Bambang Pamungkas", nik: "1275010203040004", kecamatan: "Binjai Selatan", kelurahan: "Binjai Estate", coords: [3.5850, 98.4820], anggota: 6, suku: "Jawa" },
        { id: 5, kepala: "Adi Haryadi", nik: "1275010203040005", kecamatan: "Binjai Timur", kelurahan: "Sumber Karya", coords: [3.6050, 98.5150], anggota: 4, suku: "Jawa" },
        { id: 6, kepala: "Eko Prasetyo", nik: "1275010203040006", kecamatan: "Binjai Utara", kelurahan: "Jati Karya", coords: [3.6350, 98.5080], anggota: 4, suku: "Jawa" },
        { id: 7, kepala: "Herianto", nik: "1275010203040007", kecamatan: "Binjai Selatan", kelurahan: "Tanah Merah", coords: [3.5710, 98.4710], anggota: 5, suku: "Jawa" },
        { id: 8, kepala: "Rudi Hartono", nik: "1275010203040008", kecamatan: "Binjai Kota", kelurahan: "Satria", coords: [3.6080, 98.4920], anggota: 2, suku: "Jawa" }
    ];

    // Marker styling: Golden custom circle markers
    const markerOptions = {
        radius: 8,
        fillColor: "#D4AF37",
        color: "#800020",
        weight: 2,
        opacity: 1,
        fillOpacity: 0.8
    };

    let markerLayerGroup = L.layerGroup().addTo(map);

    function renderMarkers(filterKec = "all") {
        markerLayerGroup.clearLayers();
        let totalF = 0;
        let totalI = 0;

        dummyFamilies.forEach(family => {
            if (filterKec === "all" || family.kecamatan === filterKec) {
                totalF++;
                totalI += family.anggota;

                // Create popup info
                const popupContent = `
                    <div style="font-family: 'Plus Jakarta Sans', sans-serif;">
                        <h4 style="color: #D4AF37; margin: 0 0 6px 0; font-size: 14px; font-family: 'Playfair Display', serif;">
                            Keluarga Bp. ${family.kepala}
                        </h4>
                        <p style="margin: 0 0 4px 0; font-size: 11px; color: #ccc;">
                            <strong>Kecamatan:</strong> ${family.kecamatan}
                        </p>
                        <p style="margin: 0 0 4px 0; font-size: 11px; color: #ccc;">
                            <strong>Kelurahan:</strong> ${family.kelurahan}
                        </p>
                        <p style="margin: 0 0 4px 0; font-size: 11px; color: #ccc;">
                            <strong>Jumlah Anggota:</strong> ${family.anggota} Jiwa
                        </p>
                        <span style="display: inline-block; background-color: rgba(128, 0, 32, 0.2); border: 1px solid rgba(128, 0, 32, 0.5); padding: 2px 6px; border-radius: 4px; font-size: 9px; color: #FFE07D; font-weight: bold;">
                            Suku ${family.suku}
                        </span>
                    </div>
                `;

                // Add marker
                L.circleMarker(family.coords, markerOptions)
                    .bindPopup(popupContent)
                    .addTo(markerLayerGroup);
            }
        });

        // Update statistics counters on sidebar
        document.getElementById("mappedFamiliesCount").textContent = totalF;
        document.getElementById("mappedIndividualsCount").textContent = totalI;
    }

    // Initialize markers
    renderMarkers();

    // 5. Filter Dropdown Event Listener
    const filterKecSelect = document.getElementById("filterKecamatan");
    filterKecSelect.addEventListener("change", (e) => {
        const selectedVal = e.target.value;
        renderMarkers(selectedVal);

        // Adjust map view based on selected kecamatan
        if (selectedVal !== "all") {
            const matched = dummyFamilies.find(f => f.kecamatan === selectedVal);
            if (matched) {
                map.setView(matched.coords, 14);
            }
        } else {
            map.setView(binjaiCenter, 13);
        }
    });

    // 6. Contact Form submission helper
    const contactForm = document.getElementById("contactForm");
    contactForm.addEventListener("submit", (e) => {
        e.preventDefault();
        alert("Terima kasih! Pesan Anda telah terkirim. Hubungan masyarakat DPD Pujakesuma Kota Binjai akan segera menghubungi Anda.");
        contactForm.reset();
    });
});
