import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharm/modules/landing/views/pharmacie/assistant_IA.dart';
import 'package:pharm/modules/landing/views/pharmacie/liste_commande.dart';
import 'package:pharm/modules/landing/views/pharmacie/listes_produits.dart';
import 'package:pharm/modules/landing/views/pharmacie/paramettres.dart';
import 'package:pharm/modules/landing/views/pharmacie/pharmacie_garde.dart';
import 'dart:io';
import '../../../../utilitaires/apps_colors.dart';
import '../loginphar.dart';

class PharmacieDashboardPage extends StatefulWidget {
  const PharmacieDashboardPage({super.key});

  @override
  State<PharmacieDashboardPage> createState() => _PharmacieDashboardState();
}

class _PharmacieDashboardState extends State<PharmacieDashboardPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  late AnimationController _animationController;

  late final List<Widget> _pages;

  String pharmacieEmail = "";
  String? pharmaciePhotoUrl;
  String? pharmacieName;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pages = const [
      ListesProduitsPage(),   // 1 -> Produits
      GestionCommandesPage(), // 2 -> Commandes
      GardePage(),            // 3 -> Garde
      AssistantIAPage(),      // 4 -> Assistant IA
      ParametresPage(),       // 5 -> Paramètres
    ];

    _loadPharmacie();
  }

  /// Mappe l’index du menu (0,1,2,3,4,6) vers l’index du IndexedStack (0..5)
  int get _stackIndex {
    switch (_selectedIndex) {
      case 0:
        return 0; // Dashboard
      case 1:
        return 1; // Produits
      case 2:
        return 2; // Commandes
      case 3:
        return 3; // Garde
      case 4:
        return 4; // Assistant IA
      case 6:
        return 5; // Paramètres (map 6 -> 5)
      default:
        return 0;
    }
  }

  /// Chargement des infos profil depuis users/{uid}
  Future<void> _loadPharmacie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => pharmacieEmail = user.email ?? "Inconnu");

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final data = snap.data() ?? {};

      setState(() {
        final url = (data['photoUrl'] ?? '').toString();
        pharmaciePhotoUrl = url.isNotEmpty ? url : null;

        final nom = (data['nom'] ?? '').toString();
        pharmacieName =
        nom.isNotEmpty ? nom : pharmacieEmail.split('@').first;
      });
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
      setState(() {
        pharmacieName = pharmacieEmail.split('@').first;
      });
    }
  }

  /// Upload photo -> Storage, maj users/{uid}.photoUrl
  Future<void> _selectProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    final user = FirebaseAuth.instance.currentUser;
    if (pickedFile == null || user == null) return;

    try {
      File file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child("pharmacie_profiles")
          .child("${user.uid}.jpg");
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(
        {"photoUrl": downloadUrl, "updatedAt": FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      setState(() => pharmaciePhotoUrl = downloadUrl);
    } catch (e) {
      debugPrint("Erreur upload photo: $e");
    }
  }

  /// Supprimer photo -> suppr champ dans users/{uid}
  Future<void> _removeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"photoUrl": FieldValue.delete()});
      setState(() => pharmaciePhotoUrl = null);
    } catch (e) {
      debugPrint("Erreur suppression photo: $e");
    }
  }

  /// Déconnexion (confirmation)
  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout, color: Colors.red.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(fontSize: 16, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Annuler',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginPharPage()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: const Text('Déconnexion',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Initiales à partir du nom ou email
  String _getInitials() {
    if (pharmacieName != null && pharmacieName!.isNotEmpty) {
      final parts = pharmacieName!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
      } else {
        return pharmacieName!.substring(0, 1).toUpperCase();
      }
    }
    if (pharmacieEmail.isNotEmpty) {
      final name = pharmacieEmail.split('@').first;
      return name.isNotEmpty ? name[0].toUpperCase() : "PH";
    }
    return "PH";
  }

  String get _greetingName {
    final base =
    (pharmacieName ?? pharmacieEmail.split('@').first).trim();
    final lower = base.toLowerCase();
    // évite "Pharmacie Pharmacie ..."
    if (lower.startsWith('pharmacie')) return base;
    return 'Pharmacie $base';
  }

  // ---------- Streams pour stats live ----------
  Stream<int> _productsCountStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('liste_de_produits')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> _ordersCountStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('commandes')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> _pendingCountStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('commandes')
        .where('status', isEqualTo: 'En attente')
        .snapshots()
        .map((s) => s.size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: _buildSidebar(),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        const SizedBox(height: 32),

        // Profil
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onTap: _handleProfilePhotoChange,
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primary,
                        backgroundImage: pharmaciePhotoUrl != null
                            ? NetworkImage(pharmaciePhotoUrl!)
                            : null,
                        child: pharmaciePhotoUrl == null
                            ? Text(
                          _getInitials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacieName ?? pharmacieEmail.split('@')[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pharmacie',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Menu
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [
                _buildMenuItem(0, Icons.dashboard_rounded, 'Dashboard'),
                const SizedBox(height: 8),
                _buildMenuItem(1, Icons.medication_rounded, 'Produits'),
                const SizedBox(height: 8),
                _buildMenuItem(2, Icons.shopping_bag_rounded, 'Commandes'),
                const SizedBox(height: 8),
                _buildMenuItem(3, Icons.access_time_rounded, 'Garde'),
                const SizedBox(height: 8),
                _buildMenuItem(4, Icons.psychology_rounded, 'Assistant IA'),
                const SizedBox(height: 8),
                _buildMenuItem(6, Icons.settings_rounded, 'Paramètres'),
              ],
            ),
          ),
        ),

        // Déconnexion
        Container(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: TextButton.icon(
              onPressed: () => _handleLogout(context),
              icon: Icon(Icons.logout_rounded,
                  color: Colors.red.shade600, size: 20),
              label: Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() => _selectedIndex = index);
            _animationController
                .forward()
                .then((_) => _animationController.reverse());
          },
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: isSelected
                          ? Colors.white
                          : AppColors.primary,
                      size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                      isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 1))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            // Recherche
            Expanded(
              flex: 2,
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Logo
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PHARMACAM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Notifications
            Row(
              children: [
                _buildNotificationButton(Icons.notifications_rounded, 0),
                const SizedBox(width: 12),
                _buildNotificationButton(Icons.mail_rounded, 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(IconData icon, int count) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            icon,
            color: Colors.grey.shade600,
            size: 20,
          ),
        ),
        if (count > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints:
              const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ---------- SPA: contenu central ----------
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: IndexedStack(
        index: _stackIndex,
        children: [
          // 0: Dashboard
          _buildDashboardSection(),

          // 1..5: pages
          _pages[0], // Produits
          _pages[1], // Commandes
          _pages[2], // Garde
          _pages[3], // Assistant IA
          _pages[4], // Paramètres
        ],
      ),
    );
  }

  // ------- Dashboard -------
  Widget _buildDashboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bienvenue
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour $_greetingName !',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bienvenue sur votre tableau de bord PHARMACAM',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Stats live
        Row(
          children: [
            Expanded(
              child: _statCardStream(
                'Produits',
                Icons.medication_rounded,
                Colors.blue,
                _productsCountStream(),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCardStream(
                'Commandes',
                Icons.shopping_bag_rounded,
                Colors.green,
                _ordersCountStream(),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCardStream(
                'En attente',
                Icons.hourglass_bottom_rounded,
                Colors.orange,
                _pendingCountStream(),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Widgets : Dernières commandes & Top pharmacies
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRecentOrdersCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildTopPharmaciesCard()),
          ],
        ),
      ],
    );
  }

  Widget _statCardStream(
      String title,
      IconData icon,
      Color color,
      Stream<int> stream, {
        VoidCallback? onTap,
      }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final value = snap.hasData ? snap.data! : 0;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------- Dernières commandes -------
  Widget _buildRecentOrdersCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _panelWrapper(
        icon: Icons.shopping_bag_rounded,
        title: 'Dernières commandes',
        trailing: const SizedBox.shrink(),
        child: _emptyHint('Connectez-vous'),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('commandes')
        .orderBy('createdAt', descending: true)
        .limit(5);

    return _panelWrapper(
      icon: Icons.shopping_bag_rounded,
      title: 'Dernières commandes',
      trailing: TextButton(
        onPressed: () => setState(() => _selectedIndex = 2),
        child: const Text('Voir tout'),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(minHeight: 3),
            );
          }
          if (snap.hasError) {
            return _errorHint('Erreur: ${snap.error}');
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return _emptyHint('Aucune commande récente');

          return Column(
            children: docs.map((d) {
              final data = d.data();
              final code = (data['code'] ?? 'Commande').toString();
              final client = (data['clientName'] ?? '--').toString();
              final total =
              (data['total'] is num) ? (data['total'] as num).toStringAsFixed(0) : '--';
              final status = (data['status'] ?? 'En attente').toString();

              String dateStr = '';
              try {
                final ts = data['createdAt'];
                if (ts is Timestamp) {
                  final dt = ts.toDate();
                  dateStr =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _statusPill(status),
                            ]),
                            const SizedBox(height: 4),
                            Text('$client • $dateStr',
                                style:
                                TextStyle(color: Colors.grey.shade600)),
                          ]),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      total != '--' ? '$total XAF' : '--',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ------- Top pharmacies (3) -------
  Widget _buildTopPharmaciesCard() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Pharmacie')
        .limit(6); // on filtre côté client pour enlever moi, et on garde 3

    return _panelWrapper(
      icon: Icons.local_pharmacy_rounded,
      title: 'Top pharmacies',
      trailing: const SizedBox.shrink(),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(minHeight: 3),
            );
          }
          if (snap.hasError) {
            return _errorHint('Erreur: ${snap.error}');
          }

          final all = (snap.data?.docs ?? [])
              .where((d) => d.id != currentUid)
              .toList();

          final docs = all.take(3).toList();
          if (docs.isEmpty) return _emptyHint('Aucune autre pharmacie trouvée');

          return Column(
            children: docs.map((d) {
              final data = d.data();
              final nom = (data['nom'] ?? 'Pharmacie').toString();
              final ville = (data['ville'] ?? '').toString();
              final adresse = (data['adresse'] ?? '').toString();
              final tel = (data['telephone'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_pharmacy_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                if (ville.isNotEmpty || adresse.isNotEmpty)
                                  _pill(
                                    Icons.location_on_rounded,
                                    [ville, adresse]
                                        .where((e) => e.isNotEmpty)
                                        .join(' • '),
                                  ),
                                if (tel.isNotEmpty)
                                  _pill(Icons.phone_rounded, tel),
                              ],
                            ),
                          ]),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ------- Helpers panneaux -------
  Widget _panelWrapper({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _errorHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(text, style: TextStyle(color: Colors.red.shade700)),
    );
  }

  Widget _statusPill(String s) {
    Color bg, fg;
    switch (s) {
      case 'En attente':
        bg = Colors.orange.withOpacity(0.12);
        fg = Colors.orange.shade800;
        break;
      case 'Validée':
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primary;
        break;
      case 'Préparée':
        bg = Colors.indigo.withOpacity(0.12);
        fg = Colors.indigo.shade700;
        break;
      case 'Expédiée':
        bg = Colors.purple.withOpacity(0.12);
        fg = Colors.purple.shade700;
        break;
      case 'Livrée':
        bg = Colors.green.withOpacity(0.12);
        fg = Colors.green.shade700;
        break;
      case 'Annulée':
        bg = Colors.red.withOpacity(0.12);
        fg = Colors.red.shade700;
        break;
      default:
        bg = AppColors.primary.withOpacity(0.10);
        fg = AppColors.primary;
    }
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ]),
    );
  }

  /// Choix/Suppression photo via modal
  void _handleProfilePhotoChange() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Photo de profil',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Text(
          'Choisissez une action pour votre photo de profil',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Annuler',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _selectProfilePhoto();
            },
            icon: const Icon(Icons.photo_library_rounded, size: 16),
            label: const Text('Galerie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
          if (pharmaciePhotoUrl != null) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _removeProfilePhoto();
              },
              icon: const Icon(Icons.delete_rounded, size: 16),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
