import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/screen/admin/admin_detail/detail_add_tips.dart';
import 'package:projek_uas/providers/tips_provider.dart';
import 'package:projek_uas/providers/auth_provider.dart';

class AddTipsPage extends StatefulWidget {
  const AddTipsPage({super.key});

  @override
  State<AddTipsPage> createState() => _AddTipsPageState();
}

class _AddTipsPageState extends State<AddTipsPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      // Set up the TipsProvider with AuthProvider reference
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      
      // Connect TipsProvider to AuthProvider
      tipsProvider.setAuthProvider(authProvider);
      
      // Check authentication and admin access
      if (!authProvider.isAuthenticated) {
        _handleNotAuthenticated();
        return;
      }

      if (!authProvider.isAdmin) {
        _handleNotAuthorized();
        return;
      }

      // Fetch tips data when page loads
      await tipsProvider.fetchAllTips();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _handleInitializationError(e.toString());
    }
  }

  void _handleNotAuthenticated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login terlebih dahulu'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  void _handleNotAuthorized() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak. Hanya admin yang dapat mengakses halaman ini.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    });
  }

  void _handleInitializationError(String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inisialisasi: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
=======
    // Fetch tips data when page loads and ensure token sync
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      
      // Ensure sync with AuthProvider before fetching data
      await tipsProvider.ensureSyncWithAuthProvider();
      
      // Check if user is logged in before fetching
      final isLoggedIn = await tipsProvider.isLoggedIn();
      if (isLoggedIn) {
        tipsProvider.fetchAllTips();
      } else {
        // Handle case where user is not logged in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi telah berakhir. Silakan login kembali.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TipsProvider>(
      builder: (context, authProvider, tipsProvider, child) {
        // Show loading screen while initializing
        if (!_isInitialized) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
              elevation: 0,
              title: const Text(
                'Memuat...',
                style: TextStyle(color: Colors.black),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          );
        }

        // Check authentication status
        if (!authProvider.isAuthenticated) {
          return _buildErrorScreen(
            icon: Icons.login,
            title: 'Tidak Terautentikasi',
            message: 'Silakan login kembali untuk mengakses halaman ini',
            buttonText: 'Login',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          );
        }

        // Check admin status
        if (!authProvider.isAdmin) {
          return _buildErrorScreen(
            icon: Icons.security,
            title: 'Akses Ditolak',
            message: 'Hanya admin yang dapat mengakses halaman ini',
            buttonText: 'Kembali',
            onPressed: () => Navigator.of(context).pop(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
            elevation: 0,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 32,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pocketfarm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF999999),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () {
                  tipsProvider.refresh();
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutConfirmation(authProvider);
                  } else if (value == 'debug') {
                    tipsProvider.debugAuthState();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                  // Debug option (remove in production)
                ],
              ),
            ],
          ),
          body: _buildBody(tipsProvider),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DetailAddTipsPage(),
                ),
              );
              
              // Refresh data if tip was added successfully
              if (result == true) {
                tipsProvider.refresh();
              }
            },
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
        elevation: 0,
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
<<<<<<< HEAD
=======
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
              
              // Ensure token sync before refresh
              await tipsProvider.ensureSyncWithAuthProvider();
              
              // Check if still logged in
              final isLoggedIn = await tipsProvider.isLoggedIn();
              if (isLoggedIn) {
                tipsProvider.refresh();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesi telah berakhir. Silakan login kembali.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildBody(TipsProvider tipsProvider) {
    if (tipsProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      );
    }
=======
          if (tipsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      tipsProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      tipsProvider.clearError();
                      
                      // Ensure token sync before retry
                      await tipsProvider.ensureSyncWithAuthProvider();
                      
                      final isLoggedIn = await tipsProvider.isLoggedIn();
                      if (isLoggedIn) {
                        tipsProvider.refresh();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sesi telah berakhir. Silakan login kembali.'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1

    if (tipsProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
<<<<<<< HEAD
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                tipsProvider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[400],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                tipsProvider.clearError();
                tipsProvider.refresh();
=======
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Ensure token sync before refresh
              await tipsProvider.ensureSyncWithAuthProvider();
              
              final isLoggedIn = await tipsProvider.isLoggedIn();
              if (isLoggedIn) {
                return tipsProvider.refresh();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesi telah berakhir. Silakan login kembali.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tipsProvider.tips.length,
              itemBuilder: (context, index) {
                final tip = tipsProvider.tips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildTipsCard(
                    context: context,
                    tip: tip,
                    tipsProvider: tipsProvider,
                  ),
                );
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (tipsProvider.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan tips pertama dengan menekan tombol +',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => tipsProvider.refresh(),
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tipsProvider.tips.length,
        itemBuilder: (context, index) {
          final tip = tipsProvider.tips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTipsCard(
              context: context,
              tip: tip,
              tipsProvider: tipsProvider,
            ),
          );
        },
      ),
<<<<<<< HEAD
=======
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () async {
          final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
          
          // Ensure token sync and check login status before navigation
          await tipsProvider.ensureSyncWithAuthProvider();
          
          final isLoggedIn = await tipsProvider.isLoggedIn();
          if (!isLoggedIn) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi telah berakhir. Silakan login kembali.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailAddTipsPage(),
            ),
          );
          
          // Refresh data if tip was added successfully
          if (result == true) {
            // Ensure sync again after returning from add page
            await tipsProvider.ensureSyncWithAuthProvider();
            tipsProvider.refresh();
          }
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
    );
  }

  Widget _buildTipsCard({
    required BuildContext context,
    required Map<String, dynamic> tip,
    required TipsProvider tipsProvider,
  }) {
    final String imageUrl = tip['gambar']?.toString() ?? '';
    final String title = tip['judul']?.toString() ?? 'Judul tidak tersedia';
    final String description = tip['deskripsi']?.toString() ?? 'Deskripsi tidak tersedia';
    final String formattedDate = tipsProvider.formatTanggal(tip['tanggal_tips']?.toString());
    final String author = tip['username']?.toString() ?? 'Admin';
    final int tipId = tip['id_tips'] ?? 0;

    return Card(
      color: const Color(0xFFF9F9F9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gambar tidak dapat dimuat',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada gambar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and author info
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Action buttons
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          // Check login status before allowing edit
                          await tipsProvider.ensureSyncWithAuthProvider();
                          
                          final isLoggedIn = await tipsProvider.isLoggedIn();
                          if (!isLoggedIn) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sesi telah berakhir. Silakan login kembali.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailAddTipsPage(
                                isEdit: true,
                                tipData: tip,
                              ),
                            ),
                          );
                          
                          // Refresh data if tip was updated successfully
                          if (result == true) {
                            await tipsProvider.ensureSyncWithAuthProvider();
                            tipsProvider.refresh();
                          }
                        },
                        tooltip: 'Edit Tips',
                      ),
                      
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Check login status before allowing delete
                          await tipsProvider.ensureSyncWithAuthProvider();
                          
                          final isLoggedIn = await tipsProvider.isLoggedIn();
                          if (!isLoggedIn) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sesi telah berakhir. Silakan login kembali.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }

                          _showDeleteConfirmation(context, tipId, title, tipsProvider);
                        },
                        tooltip: 'Hapus Tips',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    int tipId,
    String title,
    TipsProvider tipsProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apakah Anda yakin ingin menghapus tips ini?'),
              const SizedBox(height: 8),
              Text(
                'Tips: "$title"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTip(context, tipId, tipsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(authProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(AuthProvider authProvider) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );

      // Logout using AuthProvider
      await authProvider.logout();

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Navigate to login page
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat logout: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteTip(
    BuildContext context,
    int tipId,
    TipsProvider tipsProvider,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ),
    );

    try {
<<<<<<< HEAD
      // Use TipsProvider's deleteTip method (no need to pass token manually)
=======
      // Ensure token sync before attempting delete
      await tipsProvider.ensureSyncWithAuthProvider();
      
      // Use the TipsProvider's deleteTip method which handles token management automatically
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
      final success = await tipsProvider.deleteTip(idTips: tipId);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tips berhasil dihapus'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
<<<<<<< HEAD
        // Show error message
=======
        // Show error message - error is already set in the provider
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tipsProvider.error ?? 'Gagal menghapus tips'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}