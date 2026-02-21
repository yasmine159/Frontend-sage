import 'package:flutter/material.dart';
import 'package:frontend_sage3/main.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState(); // This is correct
}

class _SettingsPageState extends State<SettingsPage> { // This should extend State<SettingsPage>, NOT State<SageX3App>
  bool notificationsEnabled = true;
  bool emailNotifications = false;
  bool autoDownload = true;
  bool darkMode = false;
  String selectedLanguage = 'English';
  String defaultModel = 'MES01';

  @override
  void initState() {
    super.initState();
    // Get initial dark mode state from app
    final appState = SageX3App.of(context);
    if (appState != null) {
      darkMode = appState.isDarkMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.light
                  ? Color(0xFFe2e8f0)
                  : Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Account',
                        [
                          _buildProfileTile(),
                          _buildSettingTile(
                            icon: Icons.lock_outlined,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: () => _showChangePasswordDialog(),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildSection(
                        'Preferences',
                        [
                          _buildSwitchTile(
                            icon: Icons.notifications_outlined,
                            title: 'Push Notifications',
                            subtitle: 'Receive upload status updates',
                            value: notificationsEnabled,
                            onChanged: (value) {
                              setState(() => notificationsEnabled = value);
                            },
                          ),
                          _buildSwitchTile(
                            icon: Icons.email_outlined,
                            title: 'Email Notifications',
                            subtitle: 'Get emails for completed uploads',
                            value: emailNotifications,
                            onChanged: (value) {
                              setState(() => emailNotifications = value);
                            },
                          ),
                          _buildSwitchTile(
                            icon: Icons.download_outlined,
                            title: 'Auto Download',
                            subtitle: 'Automatically download templates',
                            value: autoDownload,
                            onChanged: (value) {
                              setState(() => autoDownload = value);
                            },
                          ),
                          _buildSwitchTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Mode',
                            subtitle: 'Enable dark theme',
                            value: darkMode,
                            onChanged: (value) {
                              setState(() => darkMode = value);

                              // 🔥 THIS CHANGES THE WHOLE APP THEME
                              final appState = SageX3App.of(context);
                              appState?.toggleTheme(value);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildSection(
                        'App Settings',
                        [
                          _buildSettingTile(
                            icon: Icons.language,
                            title: 'Language',
                            subtitle: selectedLanguage,
                            onTap: () => _showLanguageDialog(),
                          ),
                          _buildSettingTile(
                            icon: Icons.model_training,
                            title: 'Default Model',
                            subtitle: defaultModel,
                            onTap: () => _showModelDialog(),
                          ),
                          _buildSettingTile(
                            icon: Icons.storage,
                            title: 'Storage',
                            subtitle: 'Manage app storage',
                            onTap: () => _showComingSoonSnackBar('Storage settings'),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildSection(
                        'Support',
                        [
                          _buildSettingTile(
                            icon: Icons.help_outline,
                            title: 'Help & FAQ',
                            subtitle: 'Get help and answers',
                            onTap: () => _showComingSoonSnackBar('Help center'),
                          ),
                          _buildSettingTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'View privacy policy',
                            onTap: () => _showComingSoonSnackBar('Privacy policy'),
                          ),
                          _buildSettingTile(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'View terms of service',
                            onTap: () => _showComingSoonSnackBar('Terms of service'),
                          ),
                          _buildSettingTile(
                            icon: Icons.feedback_outlined,
                            title: 'Send Feedback',
                            subtitle: 'Help us improve',
                            onTap: () => _showFeedbackDialog(),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildSection(
                        'About',
                        [
                          _buildSettingTile(
                            icon: Icons.info_outline,
                            title: 'App Version',
                            subtitle: '1.0.0',
                            trailing: SizedBox.shrink(),
                          ),
                          _buildSettingTile(
                            icon: Icons.update,
                            title: 'Check for Updates',
                            subtitle: 'You\'re up to date',
                            onTap: () => _showComingSoonSnackBar('Update check'),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildLogoutButton(),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black12
                : Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black12
                    : Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTile() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.person, color: Colors.white, size: 28),
      ),
      title: Text(
        'John Doe',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        'john.doe@company.com',
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: () => _showComingSoonSnackBar('Profile editing'),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);

    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: Icon(Icons.logout, color: theme.colorScheme.error),
        label: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          side: BorderSide(color: theme.colorScheme.error, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassword,
              obscureText: true,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPassword,
              obscureText: true,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmPassword,
              obscureText: true,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonSnackBar('Password change');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Select Language', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'French', 'Spanish', 'German'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang, style: TextStyle(color: colorScheme.onSurface)),
              value: lang,
              groupValue: selectedLanguage,
              activeColor: colorScheme.primary,
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showModelDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Default Model', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['MES01', 'MES02', 'MES03', 'MES04'].map((model) {
            return RadioListTile<String>(
              title: Text(model, style: TextStyle(color: colorScheme.onSurface)),
              value: model,
              groupValue: defaultModel,
              activeColor: colorScheme.primary,
              onChanged: (value) {
                setState(() => defaultModel = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send Feedback', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: TextField(
          controller: feedbackController,
          maxLines: 5,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }
}