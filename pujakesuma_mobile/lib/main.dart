import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/supabase_service.dart';
import 'core/widgets/internet_guard.dart';
import 'features/auth/login_screen.dart';
import 'features/individu/individu_form_screen.dart';
import 'features/scan/scan_kk_screen.dart';
import 'features/scan/keluarga_review_screen.dart';
import 'features/chat/chat_room_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client
  await Supabase.initialize(
    url: 'https://mqudxbrcqzdwkicyrwwc.supabase.co',
    anonKey: 'sb_publishable_KpA-RA9hsEvvo3zVkLeH2w_2IuonCDR',
  );

  // Initialize Local Hive Database
  await Hive.initFlutter();
  await Hive.openBox('settings');

  runApp(
    const ProviderScope(
      child: PujakesumaApp(),
    ),
  );
}

class PujakesumaApp extends StatelessWidget {
  const PujakesumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF800020),
        primary: const Color(0xFF800020),
        secondary: const Color(0xFFD4AF37),
        background: const Color(0xFF131324),
        surface: const Color(0xFF1A1A2E),
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
      ),
    ) == null ? const SizedBox() : MaterialApp(
      title: 'PUJAKESUMA Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Cultural Maroon and Gold theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF800020),
          primary: const Color(0xFF800020),
          secondary: const Color(0xFFD4AF37),
          background: const Color(0xFF131324),
          surface: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        ),
      ),
      home: const InternetGuard(
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = SupabaseService.isAuthenticated;

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    }
    return MainDashboardScreen(
      onLogout: () {
        setState(() {
          _isLoggedIn = false;
        });
      },
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainDashboardScreen({super.key, required this.onLogout});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;
  String? _groupChatRoomId;
  bool _isLoadingChat = true;
  final GlobalKey<_HomeDashboardWidgetState> _homeKey = GlobalKey<_HomeDashboardWidgetState>();

  @override
  void initState() {
    super.initState();
    _loadOrCreateGroupChat();
  }

  Future<void> _loadOrCreateGroupChat() async {
    try {
      // Find or create default group room
      final response = await SupabaseService.client
          .from('chat_rooms')
          .select('id')
          .eq('is_group', true)
          .limit(1);

      if (response.isNotEmpty) {
        if (mounted) {
          setState(() {
            _groupChatRoomId = response[0]['id'];
            _isLoadingChat = false;
          });
        }
      } else {
        // Create new group room if none exists
        final newRoom = await SupabaseService.client
            .from('chat_rooms')
            .insert({'name': 'Grup Pujakesuma', 'is_group': true})
            .select()
            .single();

        if (mounted) {
          setState(() {
            _groupChatRoomId = newRoom['id'];
            _isLoadingChat = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChat = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeDashboardWidget(key: _homeKey),
      const SizedBox.shrink(), // Placeholder since ScanKkScreen is pushed full screen on tap
      _isLoadingChat
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _groupChatRoomId != null
              ? ChatRoomScreen(
                  roomId: _groupChatRoomId!,
                  roomName: 'Grup Pujakesuma',
                )
              : const Center(
                  child: Text('Gagal memuat ruang obrolan.', style: TextStyle(color: Colors.grey)),
                ),
      ProfileScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if (index == 1) {
            // Launch scanner screen as full-screen modal page
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanKkScreen(),
              ),
            );
            
            if (result != null && mounted) {
              // Push review screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KeluargaReviewScreen(
                    initialKeluargaData: result['keluarga'],
                    initialAnggotaList: List<Map<String, dynamic>>.from(result['anggotaList']),
                  ),
                ),
              ).then((_) {
                // Reload dashboard stats
                _homeKey.currentState?._loadStats();
              });
            }
            return;
          }
          
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            _homeKey.currentState?._loadStats();
          }
        },
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A2E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Pindai KK'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomeDashboardWidget extends StatefulWidget {
  const HomeDashboardWidget({super.key});

  @override
  State<HomeDashboardWidget> createState() => _HomeDashboardWidgetState();
}

class _HomeDashboardWidgetState extends State<HomeDashboardWidget> {
  int _totalTerdata = 0;
  String _petugasName = 'Budi Hartanto';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _petugasName = profile['full_name'] ?? 'Petugas Lapangan';
          });
        }

        // Query real count of keluarga submitted by this officer from Supabase
        final response = await SupabaseService.client
            .from('keluarga')
            .select()
            .eq('petugas_id', user.id);

        if (mounted) {
          setState(() {
            _totalTerdata = response.length;
          });
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PUJAKESUMA Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1A1A2E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF800020), Color(0xFF4A0012)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $_petugasName',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Petugas Lapangan DPD Pujakesuma Binjai',
                      style: TextStyle(fontSize: 12, color: Color(0xFFFFE07D)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TERDATA ONLINE', style: TextStyle(fontSize: 10, color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text('$_totalTerdata Keluarga', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: const Icon(Icons.cloud_done, color: Colors.green, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Aksi Cepat Pendataan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif'),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Pindai KK',
                    subtitle: 'OCR Scanner KK (Landscape)',
                    icon: Icons.camera_alt,
                    color: const Color(0xFFD4AF37),
                    onTap: () {
                      // Navigate to ScanKkScreen (which is tab index 1)
                      final parentState = context.findAncestorStateOfType<_MainDashboardScreenState>();
                      parentState?.setState(() {
                        parentState._selectedIndex = 1;
                      });
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Input Manual',
                    subtitle: 'Isi Form Manual',
                    icon: Icons.edit_document,
                    color: const Color(0xFF800020),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KeluargaReviewScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
