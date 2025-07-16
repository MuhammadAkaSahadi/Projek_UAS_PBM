// main.dart - Revised dengan LahanProvider Token Integration
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:projek_uas/helper/auth_helper.dart';
import 'package:projek_uas/providers/tips_provider.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:projek_uas/providers/lahan_provider.dart';
import 'package:projek_uas/providers/laporan_provider.dart';
import 'package:projek_uas/providers/loading_provider.dart';
import 'package:projek_uas/screen/admin/admin.dart';
import 'package:projek_uas/screen/beranda.dart';
import 'package:projek_uas/screen/KebunSaya/kebunSaya.dart';
import 'package:projek_uas/screen/Tips/tips.dart';
import 'package:projek_uas/screen/Akun/akun.dart';
import 'package:projek_uas/screen/splash_screen1.dart';
import 'package:projek_uas/screen/splash_screen2.dart';
import 'package:projek_uas/screen/LoginRegister/login_screen.dart';
import 'package:projek_uas/screen/LoginRegister/register_screen.dart';
import 'package:projek_uas/services/token_storage_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize token storage
  await TokenStorage.init();
  
  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LahanProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => TipsProvider()),
      ],
      // Setup provider dependencies setelah semua provider dibuat
      child: Consumer2<AuthProvider, LahanProvider>(
        builder: (context, authProvider, lahanProvider, child) {
          // Set AuthProvider reference ke LahanProvider
          lahanProvider.setAuthProvider(authProvider);
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pocket Farm',
            theme: ThemeData(
              fontFamily: 'Roboto',
              scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            ),
            home: const AppInitializer(),
            routes: {
              '/splash1': (context) => const SplashScreen1(),
              '/splash2': (context) => SplashScreen2(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/home': (context) => const MyHomePage(title: 'Pocket Farm'),
              '/Akun': (context) => const Akun(),
              '/admin': (context) => const AdminPage(),
            },
            // Global loading overlay
            builder: (context, child) {
              return Consumer<LoadingProvider>(
                builder: (context, loadingProvider, _) {
                  return Stack(
                    children: [
                      child!,
                      if (loadingProvider.isGlobalLoading)
                        Container(
                          color: Colors.black26,
                          child: Center(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    if (loadingProvider.globalMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        loadingProvider.globalMessage!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget untuk menginisialisasi aplikasi dan menentukan route awal
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      print('=== APP INITIALIZATION ===');
      
      // Check authentication status menggunakan AuthHelper
      final isAuthenticated = await AuthHelper.isAuthenticated();
      print('Authentication Status: $isAuthenticated');
      
      if (!mounted) return;
      
      if (isAuthenticated) {
        print('User authenticated, navigating to home');
        // User sudah terauthentikasi, langsung ke home
        // Provider initialization akan dilakukan di MyHomePage
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print('User not authenticated, navigating to splash');
        // User belum terauthentikasi, mulai dari splash screen
        Navigator.of(context).pushReplacementNamed('/splash1');
      }
    } catch (e) {
      print('Error initializing app: $e');
      // Pada error, navigasi ke splash screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/splash1');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Menginisialisasi aplikasi...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    // Tidak seharusnya sampai di sini karena navigasi sudah dilakukan di initState
    return const SplashScreen1();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isInitialized = false;

  final List<Widget> _pages = [
    Beranda(),
    const MappingPage(idLahan: null),
    TipsPage(),
    Akun(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeHomePage();
  }

  Future<void> _initializeHomePage() async {
    if (_isInitialized) return; // Prevent double initialization
    
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    await loadingProvider.withLoading(
      'initialize_home',
      _initializeProviders(),
      message: 'Memuat data aplikasi...',
    );
  }

  Future<void> _initializeProviders() async {
    try {
      print('=== HOME PAGE INITIALIZATION ===');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final lahanProvider = Provider.of<LahanProvider>(context, listen: false);

      // Step 1: Validasi autentikasi menggunakan AuthHelper
      final isAuthenticated = await AuthHelper.isAuthenticated();
      print('Authentication Status: $isAuthenticated');
      
      if (!isAuthenticated) {
        print('❌ Not authenticated, redirecting to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Step 2: Dapatkan data user dari AuthHelper
      final token = await AuthHelper.getToken();
      final userId = await AuthHelper.getCurrentUserId();
      final username = await AuthHelper.getCurrentUsername();
      final userRole = await AuthHelper.getCurrentUserRole();
      final isAdmin = await AuthHelper.isAdmin();

      print('User Data Retrieved:');
      print('- Token: ${token != null ? 'Available' : 'Not Available'}');
      print('- User ID: $userId');
      print('- Username: $username');
      print('- User Role: $userRole');
      print('- Is Admin: $isAdmin');

      // Step 3: Update AuthProvider dengan data terbaru
      if (token != null) {
        authProvider.setAuthData(
          token: token,
          userId: userId,
          username: username,
          userRole: userRole,
        );
        print('✅ AuthProvider updated');
      } else {
        throw Exception('Token not available');
      }

      // Step 4: Set AuthProvider reference ke LahanProvider
      lahanProvider.setAuthProvider(authProvider);
      print('✅ LahanProvider AuthProvider reference set');

      // Step 5: Fetch data lahan menggunakan LahanProvider
      print('Fetching lahan data...');
      await lahanProvider.fetchLahan();
      
      if (lahanProvider.error != null) {
        print('⚠️ LahanProvider Error: ${lahanProvider.error}');
        // Jika error karena auth, redirect ke login
        if (lahanProvider.error!.contains('login') || 
            lahanProvider.error!.contains('Token')) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
          return;
        }
      } else {
        print('✅ Lahan data loaded: ${lahanProvider.lahanCount} items');
      }

      // Step 6: Set admin status
      setState(() {
        _isAdmin = isAdmin;
        _isInitialized = true;
      });

      // Step 7: Check token expiration
      final needsRefresh = await AuthHelper.needsRefresh();
      if (needsRefresh) {
        print('⚠️ Token will expire soon, consider refreshing');
        // TODO: Implement token refresh logic jika ada refresh token
      }

      print('✅ Home page initialization completed');

    } catch (e) {
      print('❌ Error initializing providers: $e');
      
      // Pada error, cek kembali autentikasi
      final isAuthenticated = await AuthHelper.isAuthenticated();
      if (!isAuthenticated && mounted) {
        print('Authentication lost, redirecting to login');
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        // Show error message tapi tetap lanjut
        print('Non-auth error, continuing with limited functionality');
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Handle logout dengan integrasi LahanProvider
  Future<void> _handleLogout() async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    await loadingProvider.withLoading(
      'logout',
      _performLogout(),
      message: 'Keluar dari aplikasi...',
    );
  }

  Future<void> _performLogout() async {
    try {
      print('=== LOGOUT PROCESS ===');
      
      // Step 1: Clear token storage menggunakan AuthHelper
      final success = await AuthHelper.logout();
      print('AuthHelper logout result: $success');
      
      if (success) {
        // Step 2: Clear semua providers
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final lahanProvider = Provider.of<LahanProvider>(context, listen: false);
        
        // Clear AuthProvider
        authProvider.clearAuth();
        print('✅ AuthProvider cleared');
        
        // Clear LahanProvider
        lahanProvider.clearData();
        print('✅ LahanProvider cleared');
        
        // Step 3: Reset initialization flag
        setState(() {
          _isInitialized = false;
          _isAdmin = false;
        });
        
        // Step 4: Navigate to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        
        print('✅ Logout completed successfully');
      } else {
        throw Exception('Failed to logout from AuthHelper');
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      // Bahkan jika ada error, tetap coba navigasi ke login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  /// Handle refresh data
  Future<void> _handleRefresh() async {
    if (!_isInitialized) return;
    
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    await loadingProvider.withLoading(
      'refresh_data',
      _refreshData(),
      message: 'Memperbarui data...',
    );
  }

  Future<void> _refreshData() async {
    try {
      print('=== REFRESH DATA ===');
      
      // Validasi autentikasi
      final isAuthenticated = await AuthHelper.isAuthenticated();
      if (!isAuthenticated) {
        print('❌ Not authenticated during refresh');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Refresh lahan data
      final lahanProvider = Provider.of<LahanProvider>(context, listen: false);
      await lahanProvider.refresh();
      
      if (lahanProvider.error != null) {
        print('⚠️ Error refreshing lahan: ${lahanProvider.error}');
        if (lahanProvider.error!.contains('login') || 
            lahanProvider.error!.contains('Token')) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
          return;
        }
      }
      
      print('✅ Data refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar Aplikasi'),
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ?? false;
      },
      child: Scaffold(
        appBar: _selectedIndex == 3 ? AppBar(
          title: const Text('Akun'),
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          actions: [
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
              tooltip: 'Refresh Data',
            ),
            // Admin panel button
            if (_isAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin');
                },
                tooltip: 'Panel Admin',
              ),
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Keluar',
            ),
          ],
        ) : null,
        body: !_isInitialized 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Memuat halaman...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFFF9F9F9),
          selectedItemColor: const Color(0xFF4CAF50),
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 0
                    ? 'assets/Beranda_hijau.png'
                    : 'assets/Beranda.png',
                width: 20,
                height: 20,
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 1
                    ? 'assets/Kebun Saya_hijau.png'
                    : 'assets/Kebun Saya.png',
                width: 20,
                height: 20,
              ),
              label: 'Kebun Saya',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 2
                    ? 'assets/Hasil Laporan_hijau.png'
                    : 'assets/Hasil Laporan.png',
                width: 20,
                height: 20,
              ),
              label: 'Tips',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                _selectedIndex == 3 ? 'assets/Akun_hijau.png' : 'assets/Akun.png',
                width: 20,
                height: 20,
              ),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}