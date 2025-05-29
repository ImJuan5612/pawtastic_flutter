import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:animate_do/animate_do.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'Español';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: _buildSection(
                  context,
                  title: 'Notificaciones',
                  icon: Icons.notifications_rounded,
                  children: [
                    _buildSwitchTile(
                      title: 'Notificaciones Push',
                      subtitle: 'Recibir notificaciones de la aplicación',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: _buildSection(
                  context,
                  title: 'Privacidad',
                  icon: Icons.security_rounded,
                  children: [
                    _buildSwitchTile(
                      title: 'Ubicación',
                      subtitle: 'Permitir acceso a la ubicación',
                      value: _locationEnabled,
                      onChanged: (value) {
                        setState(() => _locationEnabled = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: _buildSection(
                  context,
                  title: 'Apariencia',
                  icon: Icons.palette_rounded,
                  children: [
                    _buildThemeSelector(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: _buildSection(
                  context,
                  title: 'Idioma',
                  icon: Icons.language_rounded,
                  children: [
                    _buildLanguageSelector(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: _buildSection(
                  context,
                  title: 'Información',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _buildInfoTile(
                      title: 'Versión',
                      subtitle: '1.0.0',
                      icon: Icons.android_rounded,
                    ),
                    _buildInfoTile(
                      title: 'Términos y condiciones',
                      subtitle: 'Lee nuestros términos',
                      icon: Icons.description_rounded,
                      onTap: () {
                        // Navegar a términos y condiciones
                      },
                    ),
                    _buildInfoTile(
                      title: 'Política de privacidad',
                      subtitle: 'Lee nuestra política',
                      icon: Icons.privacy_tip_rounded,
                      onTap: () {
                        // Navegar a política de privacidad
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: const Text('Tema'),
      subtitle: Text(_themeMode.name.toUpperCase()),
      trailing: DropdownButton<ThemeMode>(
        value: _themeMode,
        underline: const SizedBox(),
        items: ThemeMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(mode.name.toUpperCase()),
          );
        }).toList(),
        onChanged: (mode) {
          if (mode != null) {
            setState(() => _themeMode = mode);
          }
        },
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return ListTile(
      title: const Text('Idioma'),
      subtitle: Text(_selectedLanguage),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        underline: const SizedBox(),
        items: ['Español', 'English'].map((language) {
          return DropdownMenuItem(
            value: language,
            child: Text(language),
          );
        }).toList(),
        onChanged: (language) {
          if (language != null) {
            setState(() => _selectedLanguage = language);
          }
        },
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
