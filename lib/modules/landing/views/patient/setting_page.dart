import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharm/utilitaires/apps_colors.dart';
import 'package:pharm/composants/custom_bottom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  // États pour les paramètres
  bool _notificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _autoBackupEnabled = true;
  bool _dataCompressionEnabled = false;
  bool _analyticsEnabled = true;
  String _selectedLanguage = 'Français';
  String _selectedTheme = 'Système';
  double _cacheSize = 45.2; // MB
  String _appVersion = '';
  String _deviceInfo = '';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Chargement des paramètres sauvegardés
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _pushNotificationsEnabled = prefs.getBool('push_notifications') ?? true;
      _emailNotificationsEnabled = prefs.getBool('email_notifications') ?? false;
      _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      _biometricEnabled = prefs.getBool('biometric') ?? false;
      _autoBackupEnabled = prefs.getBool('auto_backup') ?? true;
      _dataCompressionEnabled = prefs.getBool('data_compression') ?? false;
      _analyticsEnabled = prefs.getBool('analytics') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'Français';
      _selectedTheme = prefs.getString('theme') ?? 'Système';
    });
  }

  // Chargement des informations de l'application
  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    String deviceDetails = '';

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceDetails = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceDetails = '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      deviceDetails = 'Informations non disponibles';
    }

    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      _deviceInfo = deviceDetails;
    });
  }

  // Sauvegarde d'un paramètre
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('push_notifications', _pushNotificationsEnabled);
    await prefs.setBool('email_notifications', _emailNotificationsEnabled);
    await prefs.setBool('dark_mode', _darkModeEnabled);
    await prefs.setBool('biometric', _biometricEnabled);
    await prefs.setBool('auto_backup', _autoBackupEnabled);
    await prefs.setBool('data_compression', _dataCompressionEnabled);
    await prefs.setBool('analytics', _analyticsEnabled);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('theme', _selectedTheme);
  }

  // Animation de bouton
  void _animateButton() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  // Vider le cache
  Future<void> _clearCache() async {
    _animateButton();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _cacheSize = 0.0;
    });
    _showSuccessMessage('Cache vidé avec succès');
  }

  // Exporter les données
  Future<void> _exportData() async {
    _showLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);
    _showSuccessMessage('Données exportées vers le dossier Téléchargements');
  }

  // Importer les données
  Future<void> _importData() async {
    _showLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);
    _showSuccessMessage('Données importées avec succès');
  }

  // Activer l'authentification biométrique
  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      try {
        final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
        if (canCheckBiometrics) {
          final bool didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Veuillez vous authentifier pour activer la biométrie',
            options: const AuthenticationOptions(
              biometricOnly: true,
            ),
          );
          if (didAuthenticate) {
            setState(() {
              _biometricEnabled = true;
            });
            _saveSettings();
            _showSuccessMessage('Authentification biométrique activée');
          }
        } else {
          _showErrorMessage('L\'authentification biométrique n\'est pas disponible');
        }
      } catch (e) {
        _showErrorMessage('Erreur lors de l\'activation de la biométrie');
      }
    } else {
      setState(() {
        _biometricEnabled = false;
      });
      _saveSettings();
      _showSuccessMessage('Authentification biométrique désactivée');
    }
  }

  // Changer la langue
  void _changeLanguage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir la langue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...['Français', 'English', 'Español', 'العربية'].map((langue) =>
                ListTile(
                  title: Text(langue),
                  trailing: _selectedLanguage == langue
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = langue;
                    });
                    _saveSettings();
                    Navigator.pop(context);
                    _showSuccessMessage('Langue changée vers $langue');
                  },
                ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  // Changer le thème
  void _changeTheme() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir le thème',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...['Système', 'Clair', 'Sombre'].map((theme) =>
                ListTile(
                  title: Text(theme),
                  leading: Icon(_getThemeIcon(theme)),
                  trailing: _selectedTheme == theme
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedTheme = theme;
                      if (theme == 'Sombre') _darkModeEnabled = true;
                      if (theme == 'Clair') _darkModeEnabled = false;
                    });
                    _saveSettings();
                    Navigator.pop(context);
                    _showSuccessMessage('Thème changé vers $theme');
                  },
                ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(String theme) {
    switch (theme) {
      case 'Système': return Icons.phone_android;
      case 'Clair': return Icons.light_mode;
      case 'Sombre': return Icons.dark_mode;
      default: return Icons.phone_android;
    }
  }

  // À propos de l'application
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'PharmaCam',
      applicationVersion: _appVersion,
      applicationIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 40),
      ),
      children: [
        Text('Application de digitalisation des services pharmaceutiques '),
        const SizedBox(height: 10),
        Text('Développé avec Flutter'),
        Text('Appareil: $_deviceInfo'),
      ],
    );
  }

  // Contacter le support
  Future<void> _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@pharmapp.com',
      queryParameters: {
        'subject': 'Support PharmaCam',
        'body': 'Version: $_appVersion\nAppareil: $_deviceInfo\n\nDescription du problème:\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorMessage('Impossible d\'ouvrir l\'application email');
    }
  }

  // Afficher les mentions légales
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'Vos données personnelles sont importantes pour nous. '
                'Nous collectons uniquement les informations nécessaires '
                'au fonctionnement de l\'application et ne les partageons '
                'jamais avec des tiers sans votre consentement explicite.\n\n'
                'Données collectées:\n'
                '- Informations de profil\n'
                '- Préférences d\'utilisation\n'
                '- Données d\'usage anonymisées\n\n'
                'Pour plus d\'informations, visitez notre site web.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final Uri uri = Uri.parse('https://pharmacam.com/privacy');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: const Text('Voir en ligne'),
          ),
        ],
      ),
    );
  }

  // Messages d'information
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 20),
            const Text('Traitement en cours...'),
          ],
        ),
      ),
    );
  }

  // Confirmation de déconnexion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Paramètres',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  const SizedBox(height: 20),

                  // Section Notifications
                  _buildSection(
                    'Notifications',
                    Icons.notifications,
                    [
                      _buildSwitchTile(
                        'Notifications générales',
                        'Recevoir toutes les notifications',
                        _notificationsEnabled,
                            (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      _buildSwitchTile(
                        'Notifications push',
                        'Recevoir les notifications push',
                        _pushNotificationsEnabled,
                            (value) {
                          setState(() {
                            _pushNotificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      _buildSwitchTile(
                        'Notifications email',
                        'Recevoir les notifications par email',
                        _emailNotificationsEnabled,
                            (value) {
                          setState(() {
                            _emailNotificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section Apparence
                  _buildSection(
                    'Apparence',
                    Icons.palette,
                    [
                      _buildSettingTile(
                        'Thème',
                        _selectedTheme,
                        _getThemeIcon(_selectedTheme),
                        onTap: _changeTheme,
                      ),
                      _buildSettingTile(
                        'Langue',
                        _selectedLanguage,
                        Icons.language,
                        onTap: _changeLanguage,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section Sécurité
                  _buildSection(
                    'Sécurité',
                    Icons.security,
                    [
                      _buildSwitchTile(
                        'Authentification biométrique',
                        'Utilisez votre empreinte ou face ID',
                        _biometricEnabled,
                        _toggleBiometric,
                      ),
                      _buildSwitchTile(
                        'Analyse d\'utilisation',
                        'Aider à améliorer l\'application',
                        _analyticsEnabled,
                            (value) {
                          setState(() {
                            _analyticsEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section Données
                  _buildSection(
                    'Données',
                    Icons.storage,
                    [
                      _buildSwitchTile(
                        'Sauvegarde automatique',
                        'Sauvegarder automatiquement vos données',
                        _autoBackupEnabled,
                            (value) {
                          setState(() {
                            _autoBackupEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      _buildSwitchTile(
                        'Compression des données',
                        'Réduire l\'utilisation de la bande passante',
                        _dataCompressionEnabled,
                            (value) {
                          setState(() {
                            _dataCompressionEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      _buildSettingTile(
                        'Vider le cache',
                        '${_cacheSize.toStringAsFixed(1)} MB utilisés',
                        Icons.cleaning_services,
                        onTap: _clearCache,
                      ),
                      _buildSettingTile(
                        'Exporter les données',
                        'Sauvegarder vos données localement',
                        Icons.download,
                        onTap: _exportData,
                      ),
                      _buildSettingTile(
                        'Importer les données',
                        'Restaurer à partir d\'une sauvegarde',
                        Icons.upload,
                        onTap: _importData,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section Support
                  _buildSection(
                    'Support',
                    Icons.help,
                    [
                      _buildSettingTile(
                        'Contacter le support',
                        'Obtenir de l\'aide',
                        Icons.email,
                        onTap: _contactSupport,
                      ),
                      _buildSettingTile(
                        'À propos',
                        'Informations sur l\'application',
                        Icons.info,
                        onTap: _showAbout,
                      ),
                      _buildSettingTile(
                        'Politique de confidentialité',
                        'Voir nos conditions d\'utilisation',
                        Icons.privacy_tip,
                        onTap: _showPrivacyPolicy,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.warning),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(
        value ? Icons.toggle_on : Icons.toggle_off,
        color: value ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
