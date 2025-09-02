import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../utilitaires/apps_colors.dart';

/// ---------------------------------------------------------------------------
/// ParametresPage
/// Firestore: users/{uid}
/// Champs utilisés/ajoutés côté doc user:
///   - nom, responsable, telephone, email, adresse, ville, horaires
///   - preferences: {
///       notificationsEnabled: bool,
///       themeMode: 'system'|'light'|'dark',
///       currency: 'XAF' (par défaut),
///       lowStockThreshold: int (par défaut 5),
///     }
/// ---------------------------------------------------------------------------

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  User? _user;
  DocumentReference<Map<String, dynamic>>? _userDoc;

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPrefs = false;

  // Controllers Profil
  final _nomCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // read-only
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _horairesCtrl = TextEditingController();

  // Préférences
  bool _notifEnabled = true;
  String _themeMode = 'system'; // 'system'|'light'|'dark'
  final List<DropdownMenuItem<String>> _themeItems = const [
    DropdownMenuItem(value: 'system', child: Text('Système')),
    DropdownMenuItem(value: 'light', child: Text('Clair')),
    DropdownMenuItem(value: 'dark', child: Text('Sombre')),
  ];
  String _currency = 'XAF';
  final _currencyItems = const [
    DropdownMenuItem(value: 'XAF', child: Text('XAF')),
    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
    DropdownMenuItem(value: 'USD', child: Text('USD')),
  ];
  final _lowStockCtrl = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      setState(() => _loading = false);
      return;
    }
    _user = u;
    _userDoc = FirebaseFirestore.instance.collection('users').doc(u.uid);

    try {
      final snap = await _userDoc!.get();
      final data = snap.data() ?? {};

      _nomCtrl.text = (data['nom'] ?? '').toString();
      _responsableCtrl.text = (data['responsable'] ?? '').toString();
      _telCtrl.text = (data['telephone'] ?? '').toString();
      _emailCtrl.text = (data['email'] ?? _user!.email ?? '').toString();
      _adresseCtrl.text = (data['adresse'] ?? '').toString();
      _villeCtrl.text = (data['ville'] ?? '').toString();
      _horairesCtrl.text = (data['horaires'] ?? '').toString();

      final prefs = Map<String, dynamic>.from(data['preferences'] ?? {});
      _notifEnabled = prefs['notificationsEnabled'] is bool ? prefs['notificationsEnabled'] : true;
      _themeMode = (prefs['themeMode'] ?? 'system').toString();
      _currency = (prefs['currency'] ?? 'XAF').toString();
      _lowStockCtrl.text = (prefs['lowStockThreshold'] is num)
          ? (prefs['lowStockThreshold']).toString()
          : '5';
    } catch (e) {
      // ignore, affichage basique d'erreur possible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur de chargement: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _responsableCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _horairesCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  // ---------------------------- SAVE ACTIONS ----------------------------

  Future<void> _saveProfile() async {
    if (_userDoc == null) return;
    setState(() => _savingProfile = true);
    try {
      await _userDoc!.update({
        'nom': _nomCtrl.text.trim(),
        'responsable': _responsableCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'adresse': _adresseCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
        'horaires': _horairesCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Profil mis à jour.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePrefs() async {
    if (_userDoc == null) return;
    setState(() => _savingPrefs = true);
    try {
      final threshold = int.tryParse(_lowStockCtrl.text.trim()) ?? 5;
      await _userDoc!.set({
        'preferences': {
          'notificationsEnabled': _notifEnabled,
          'themeMode': _themeMode,
          'currency': _currency,
          'lowStockThreshold': threshold,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          content: Text('Préférences enregistrées.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  Future<void> _openChangePasswordSheet() async {
    if (_user == null) return;

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        Future<void> save() async {
          if (!formKey.currentState!.validate()) return;
          setState(() => saving = true);
          try {
            final email = _user!.email;
            if (email == null) {
              throw 'Votre compte n’a pas d’email associé.';
            }
            final cred = EmailAuthProvider.credential(
              email: email,
              password: currentCtrl.text.trim(),
            );
            await _user!.reauthenticateWithCredential(cred);
            await _user!.updatePassword(newCtrl.text.trim());
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.black87,
                behavior: SnackBarBehavior.floating,
                content: Text('Mot de passe mis à jour.'),
              ),
            );
          } catch (e) {
            setState(() => saving = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                content: Text('Erreur: $e'),
              ),
            );
          }
        }

        InputDecoration _dec(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

        TextStyle _label = const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 46, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(100))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Changer le mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Align(alignment: Alignment.centerLeft, child: Text('Mot de passe actuel', style: _label)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: _dec('••••••••'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: Text('Nouveau mot de passe', style: _label)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: _dec('Min. 6 caractères'),
                    validator: (v) => (v != null && v.trim().length >= 6) ? null : 'Min. 6 caractères',
                  ),
                  const SizedBox(height: 12),

                  Align(alignment: Alignment.centerLeft, child: Text('Confirmer', style: _label)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: _dec('Répéter le nouveau mot de passe'),
                    validator: (v) => (v == newCtrl.text) ? null : 'La confirmation ne correspond pas',
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: saving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Mettre à jour', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------ BUILD ------------------------------

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return _shell(
        Center(
          child: Text('Veuillez vous connecter pour accéder aux paramètres.',
              style: TextStyle(color: Colors.grey.shade700)),
        ),
      );
    }
    if (_loading) {
      return _shell(const Center(child: CircularProgressIndicator()));
    }

    return _shell(
      SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          children: [
            _card(
              headerIcon: Icons.store_rounded,
              headerLabel: 'Profil de la pharmacie',
              child: Column(
                children: [
                  _field('Nom', _nomCtrl, hint: 'Pharmacie Mindili'),
                  _field('Responsable', _responsableCtrl, hint: 'Mr Sergio'),
                  _field('Téléphone', _telCtrl, hint: '658547990', keyboard: TextInputType.phone),
                  _field('Email (lecture seule)', _emailCtrl, readOnly: true),
                  _field('Adresse', _adresseCtrl, hint: 'Odza'),
                  _field('Ville', _villeCtrl, hint: 'Yaoundé'),
                  _field('Horaires', _horairesCtrl, hint: '08h00-21h00'),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _savingProfile ? null : _saveProfile,
                      icon: _savingProfile
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              headerIcon: Icons.tune_rounded,
              headerLabel: 'Préférences',
              child: Column(
                children: [
                  _switchTile(
                    title: 'Notifications',
                    value: _notifEnabled,
                    onChanged: (v) => setState(() => _notifEnabled = v),
                  ),
                  const SizedBox(height: 12),
                  _dropdownTile(
                    title: 'Thème',
                    value: _themeMode,
                    items: _themeItems,
                    onChanged: (v) => setState(() => _themeMode = v ?? _themeMode),
                  ),
                  const SizedBox(height: 12),
                  _dropdownTile(
                    title: 'Devise',
                    value: _currency,
                    items: _currencyItems,
                    onChanged: (v) => setState(() => _currency = v ?? _currency),
                  ),
                  const SizedBox(height: 12),
                  _numberTile(
                    title: 'Seuil alerte Stock',
                    controller: _lowStockCtrl,
                    suffix: 'u.',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _savingPrefs ? null : _savePrefs,
                      icon: _savingPrefs
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _card(
              headerIcon: Icons.security_rounded,
              headerLabel: 'Sécurité',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change ton mot de passe pour sécuriser l’accès.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _openChangePasswordSheet,
                    icon: const Icon(Icons.lock_reset_rounded, size: 16),
                    label: const Text('Changer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------ SHELL (header) ------------------------------

  Widget _shell(Widget body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bandeau top
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.settings_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Paramètres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: body),
      ],
    );
  }

  // ------------------------------ WIDGETS UI ------------------------------

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Widget _card({required IconData headerIcon, required String headerLabel, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(headerIcon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(headerLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, bool readOnly = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            readOnly: readOnly,
            keyboardType: keyboard,
            decoration: _dec(hint ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _dec('Sélectionner'),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _numberTile({required String title, required TextEditingController controller, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: _dec('Ex: 5').copyWith(
            suffixText: suffix,
          ),
        ),
      ],
    );
  }
}
