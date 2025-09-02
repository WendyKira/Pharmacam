import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharm/modules/landing/views/admin/regsiterpharmacie.dart';

class UserModel {
  final String id;
  final String nom;
  final String email;
  final String role;
  final String horaires;
  final String statut;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.horaires,
    required this.statut,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      horaires: data['horaires'] ?? '',
      statut: data['statut'] ?? 'Inactif',
    );
  }
}

// --- Page principale ---
class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Récupération des utilisateurs depuis Firestore
  Stream<List<UserModel>> _getUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Filtrage
  List<UserModel> _filterUsers(List<UserModel> users, {String? role}) {
    List<UserModel> filtered = users;

    if (role != null) {
      filtered = filtered.where((u) => u.role == role).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((u) =>
      u.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.role.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _editUser(UserModel user) {
    FirebaseFirestore.instance
        .collection("users")
        .doc(user.id)
        .update({"statut": user.statut == "Actif" ? "Inactif" : "Actif"});
  }

  void _deleteUser(UserModel user) {
    FirebaseFirestore.instance.collection("users").doc(user.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestion des Utilisateurs"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Tous"),
            Tab(text: "Patients"),
            Tab(text: "Pharmacies"),
            Tab(text: "Admins"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Recherche
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email ou rôle...',
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // Liste dynamique Firestore
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(_filterUsers(users)), // Tous
                    _buildUserList(
                        _filterUsers(users, role: "Patient")), // Patients
                    _buildUserList(
                        _filterUsers(users, role: "Pharmacie")), // Pharmacies
                    _buildUserList(_filterUsers(
                        users, role: "Admin")), // Admins
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // 🔹 Redirection vers la page d'inscription pharmacie
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PharmacieRegisterPage()),
          );
        },
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- Widget de liste ---
  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text("Aucun utilisateur trouvé",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        return Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Icon(_getRoleIcon(user.role), color: Colors.white),
            ),
            title: Text(user.nom, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                Row(
                  children: [
                    _chip(user.role, _getRoleColor(user.role)),
                    SizedBox(width: 6),
                    _chip(user.statut,
                        user.statut == "Actif" ? Colors.green : Colors.orange),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editUser(user)),
                IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUser(user)),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helpers ---
  Widget _chip(String label, Color color) => Container(
    margin: EdgeInsets.only(top: 4),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(12)),
    child:
    Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
  );

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Patient':
        return Colors.blue;
      case 'Pharmacie':
        return Colors.green;
      case 'Admini':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Patient':
        return Icons.person;
      case 'Pharmacie':
        return Icons.local_pharmacy;
      case 'Admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person_outline;
    }
  }
}

// --- main.dart ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: UserManagementPage(),
    debugShowCheckedModeBanner: false,
  ));
}
