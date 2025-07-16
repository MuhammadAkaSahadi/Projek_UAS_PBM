// screen/admin/tips_management.dart
import 'package:flutter/material.dart';
import 'package:projek_uas/providers/tips_provider.dart';
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class TipsManagementPage extends StatefulWidget {
  const TipsManagementPage({super.key});

  @override
  State<TipsManagementPage> createState() => _TipsManagementPageState();
}

class _TipsManagementPageState extends State<TipsManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;
  bool _hasAdminAccess = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Setup TipsProvider dengan AuthProvider reference
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    
    // Set AuthProvider reference di TipsProvider
    tipsProvider.setAuthProvider(authProvider);
    
    // Validasi admin access
    await _checkAdminAccess();
    
    // Load data
    await tipsProvider.fetchAllTips();
  }

  Future<void> _checkAdminAccess() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    final hasAccess = await tipsProvider.isUserAdmin();
    
    setState(() {
      _hasAdminAccess = hasAccess;
    });

    // Jika bukan admin, tampilkan peringatan dan kembali
    if (!hasAccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak. Halaman ini hanya untuk admin.'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Optional: Navigate back atau ke halaman lain
      // Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Manajemen Tips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchController.clear();
                  Provider.of<TipsProvider>(context, listen: false)
                      .clearSearchResults();
                }
              });
            },
            icon: Icon(
              _isSearchMode ? Icons.close : Icons.search,
              color: Colors.white,
            ),
          ),
          // Admin indicator
          if (_hasAdminAccess)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Admin Access Warning
          if (!_hasAdminAccess)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anda tidak memiliki akses admin. Beberapa fitur mungkin tidak tersedia.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          if (_isSearchMode)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari tips...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Provider.of<TipsProvider>(context, listen: false)
                        .searchTips(value);
                  }
                },
              ),
            ),

          // Content
          Expanded(
            child: Consumer<TipsProvider>(
              builder: (context, tipsProvider, child) {
                final tips = _isSearchMode 
                    ? tipsProvider.searchResults 
                    : tipsProvider.tips;

                if (tipsProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  );
                }

                // Show error if exists
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
                            fontSize: 16,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            tipsProvider.error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            tipsProvider.clearError();
                            tipsProvider.refresh();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (tips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearchMode ? Icons.search_off : Icons.article_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearchMode 
                              ? 'Tidak ada hasil pencarian'
                              : 'Belum ada tips',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!_isSearchMode) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Mulai menambahkan tips pertama Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ]
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF4CAF50),
                  onRefresh: () => tipsProvider.refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tips.length,
                    itemBuilder: (context, index) {
                      final tip = tips[index];
                      return _buildTipCard(context, tip, tipsProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button untuk Add Tips (hanya untuk admin)
      floatingActionButton: _hasAdminAccess
          ? FloatingActionButton(
              onPressed: () => _addNewTip(context),
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTipCard(BuildContext context, Map<String, dynamic> tip, TipsProvider tipsProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTipDetail(context, tip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul dan menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['judul'] ?? 'Tanpa Judul',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Oleh: ${tip['username'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Show menu only for admin
                  if (_hasAdminAccess)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editTip(context, tip);
                            break;
                          case 'delete':
                            _deleteTip(context, tip, tipsProvider);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Deskripsi
              Text(
                tip['deskripsi'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer dengan tanggal dan gambar indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tipsProvider.formatTanggal(tip['tanggal_tips']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (tip['gambar'] != null && tip['gambar'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image,
                            size: 14,
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ada Gambar',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDetail(BuildContext context, Map<String, dynamic> tip) {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tip['judul'] ?? 'Detail Tips',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tip['gambar'] != null && tip['gambar'].toString().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Text(
                'Deskripsi:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tip['deskripsi'] ?? '',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Oleh: ${tip['username'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    tipsProvider.formatTanggalWaktu(tip['tanggal_tips']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          // Show edit button only for admin
          if (_hasAdminAccess)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _editTip(context, tip);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Edit', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _addNewTip(BuildContext context) {
    // Navigate to add tip page atau show dialog
    // Implementasi ini tergantung pada bagaimana Anda ingin menambah tip
    print('Add new tip - Admin access confirmed');
    
    // Example: Show add tip dialog
    _showAddEditDialog(context, null);
  }

  void _editTip(BuildContext context, Map<String, dynamic> tip) {
    // Navigate to edit tip page atau show dialog
    // Implementasi ini tergantung pada bagaimana Anda ingin mengedit tip
    print('Edit tip dengan ID: ${tip['id_tips']} - Admin access confirmed');
    
    // Example: Show edit tip dialog
    _showAddEditDialog(context, tip);
  }

  void _showAddEditDialog(BuildContext context, Map<String, dynamic>? tip) {
    final isEdit = tip != null;
    final judulController = TextEditingController(text: tip?['judul'] ?? '');
    final deskripsiController = TextEditingController(text: tip?['deskripsi'] ?? '');
    final gambarController = TextEditingController(text: tip?['gambar'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Tips' : 'Tambah Tips'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gambarController,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar (Opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              judulController.dispose();
              deskripsiController.dispose();
              gambarController.dispose();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final judul = judulController.text.trim();
              final deskripsi = deskripsiController.text.trim();
              final gambar = gambarController.text.trim();
              
              if (judul.isEmpty || deskripsi.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Judul dan deskripsi tidak boleh kosong'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
              
              bool success;
              if (isEdit) {
                success = await tipsProvider.updateTip(
                  idTips: tip['id_tips'],
                  judul: judul,
                  deskripsi: deskripsi,
                  gambar: gambar.isEmpty ? null : gambar,
                  tanggalTips: DateTime.now(),
                );
              } else {
                success = await tipsProvider.addTip(
                  judul: judul,
                  deskripsi: deskripsi,
                  gambar: gambar.isEmpty ? null : gambar,
                  tanggalTips: DateTime.now(),
                );
              }
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Tips berhasil diupdate' : 'Tips berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tipsProvider.error ?? 'Gagal ${isEdit ? 'mengupdate' : 'menambahkan'} tips'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              
              judulController.dispose();
              deskripsiController.dispose();
              gambarController.dispose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: Text(
              isEdit ? 'Update' : 'Tambah',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTip(BuildContext context, Map<String, dynamic> tip, TipsProvider tipsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus tips "${tip['judul']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Gunakan method deleteTip yang sudah menangani auth secara otomatis
              final success = await tipsProvider.deleteTip(
                idTips: tip['id_tips'],
              );
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tips berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tipsProvider.error ?? 'Gagal menghapus tips'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}