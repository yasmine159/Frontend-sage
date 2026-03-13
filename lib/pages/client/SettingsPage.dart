import 'package:flutter/material.dart';
import 'package:frontend_sage3/main.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/services/api_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool   notificationsEnabled = true;
  bool   emailNotifications   = false;
  bool   autoDownload         = true;
  bool   darkMode             = false;
  String selectedLanguage     = 'English';
  String defaultModel         = 'MES01';

  // ── Real user from AuthService ────────────────────────────────────────────
  AuthUser? get _user => AuthService.instance.currentUser;
  String get _username => _user?.username ?? 'User';
  String get _email    => _user?.email    ?? '';
  String get _role     => _user?.role     ?? 'User';

  String get _initials {
    final parts = _username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _username.length >= 2
        ? _username.substring(0, 2).toUpperCase()
        : _username.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    final appState = SageX3App.of(context);
    if (appState != null) darkMode = appState.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.light
                  ? Color(0xFFe2e8f0) : Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildCustomAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Account', [
                      _buildProfileTile(),
                      _buildSettingTile(
                        icon:     Icons.lock_outlined,
                        title:    'Change Password',
                        subtitle: 'Update your password',
                        onTap:    () => _showChangePasswordDialog(),
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSection('Preferences', [
                      _buildSwitchTile(
                        icon:      Icons.notifications_outlined,
                        title:     'Push Notifications',
                        subtitle:  'Receive upload status updates',
                        value:     notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => notificationsEnabled = v),
                      ),
                      _buildSwitchTile(
                        icon:      Icons.email_outlined,
                        title:     'Email Notifications',
                        subtitle:  'Get emails for completed uploads',
                        value:     emailNotifications,
                        onChanged: (v) =>
                            setState(() => emailNotifications = v),
                      ),
                      _buildSwitchTile(
                        icon:      Icons.download_outlined,
                        title:     'Auto Download',
                        subtitle:  'Automatically download templates',
                        value:     autoDownload,
                        onChanged: (v) =>
                            setState(() => autoDownload = v),
                      ),
                      _buildSwitchTile(
                        icon:      Icons.dark_mode_outlined,
                        title:     'Dark Mode',
                        subtitle:  'Enable dark theme',
                        value:     darkMode,
                        onChanged: (v) {
                          setState(() => darkMode = v);
                          SageX3App.of(context)?.toggleTheme(v);
                        },
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSection('App Settings', [
                      _buildSettingTile(
                        icon:     Icons.language,
                        title:    'Language',
                        subtitle: selectedLanguage,
                        onTap:    () => _showLanguageDialog(),
                      ),
                      _buildSettingTile(
                        icon:     Icons.model_training,
                        title:    'Default Model',
                        subtitle: defaultModel,
                        onTap:    () => _showModelDialog(),
                      ),
                      _buildSettingTile(
                        icon:     Icons.storage,
                        title:    'Storage',
                        subtitle: 'Manage app storage',
                        onTap:    () =>
                            _showComingSoonSnackBar('Storage settings'),
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSection('Support', [
                      _buildSettingTile(
                        icon:     Icons.help_outline,
                        title:    'Help & FAQ',
                        subtitle: 'Get help and answers',
                        onTap:    () =>
                            _showComingSoonSnackBar('Help center'),
                      ),
                      _buildSettingTile(
                        icon:     Icons.privacy_tip_outlined,
                        title:    'Privacy Policy',
                        subtitle: 'View privacy policy',
                        onTap:    () =>
                            _showComingSoonSnackBar('Privacy policy'),
                      ),
                      _buildSettingTile(
                        icon:     Icons.description_outlined,
                        title:    'Terms of Service',
                        subtitle: 'View terms of service',
                        onTap:    () =>
                            _showComingSoonSnackBar('Terms of service'),
                      ),
                      _buildSettingTile(
                        icon:     Icons.feedback_outlined,
                        title:    'Send Feedback',
                        subtitle: 'Help us improve',
                        onTap:    () => _showFeedbackDialog(),
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSection('About', [
                      _buildSettingTile(
                        icon:     Icons.info_outline,
                        title:    'App Version',
                        subtitle: '1.0.0',
                        trailing: SizedBox.shrink(),
                      ),
                      _buildSettingTile(
                        icon:     Icons.update,
                        title:    'Check for Updates',
                        subtitle: 'You\'re up to date',
                        onTap:    () =>
                            _showComingSoonSnackBar('Update check'),
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildLogoutButton(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ]),
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
        boxShadow: [BoxShadow(
          color:      theme.brightness == Brightness.light
              ? Colors.black12 : Colors.black54,
          blurRadius: 10, offset: Offset(0, 2),
        )],
      ),
      child: Row(children: [
        IconButton(
          icon:      Icon(Icons.arrow_back,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8),
        Text('Settings',
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.bold,
              color:      theme.colorScheme.onSurface,
            )),
      ]),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: EdgeInsets.only(left: 4, bottom: 12),
        child: Text(title,
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.bold,
              color:      theme.colorScheme.onSurface.withOpacity(0.7),
            )),
      ),
      Container(
        decoration: BoxDecoration(
          color:        theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color:      theme.brightness == Brightness.light
                ? Colors.black12 : Colors.black54,
            blurRadius: 8, offset: Offset(0, 4),
          )],
        ),
        child: Column(children: children),
      ),
    ]);
  }

  // ── Profile tile — shows real user data ───────────────────────────────────
  Widget _buildProfileTile() {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius:          28,
        backgroundColor: colorScheme.primary,
        child: Text(_initials,
            style: TextStyle(
              color:      Colors.white,
              fontWeight: FontWeight.bold,
              fontSize:   16,
            )),
      ),
      title: Text(_username,
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.bold,
            color:      colorScheme.onSurface,
          )),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_email,
              style: TextStyle(
                fontSize: 13,
                color:    colorScheme.onSurface.withOpacity(0.7),
              )),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color:        colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_role,
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                  color:      colorScheme.primary,
                )),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right,
          color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: () => _showComingSoonSnackBar('Profile editing'),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String   title,
    required String   subtitle,
    Widget?           trailing,
    VoidCallback?     onTap,
  }) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:        colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 24),
      ),
      title: Text(title,
          style: TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
            color:      colorScheme.onSurface,
          )),
      subtitle: Text(subtitle,
          style: TextStyle(
            fontSize: 13,
            color:    colorScheme.onSurface.withOpacity(0.7),
          )),
      trailing: trailing ??
          Icon(Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData           icon,
    required String             title,
    required String             subtitle,
    required bool               value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:        colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 24),
      ),
      title: Text(title,
          style: TextStyle(
            fontSize:   15,
            fontWeight: FontWeight.w600,
            color:      colorScheme.onSurface,
          )),
      subtitle: Text(subtitle,
          style: TextStyle(
            fontSize: 13,
            color:    colorScheme.onSurface.withOpacity(0.7),
          )),
      trailing: Switch(
        value:       value,
        onChanged:   onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon:  Icon(Icons.logout, color: theme.colorScheme.error),
        label: Text('Logout',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.bold,
              color:      theme.colorScheme.error,
            )),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          side:    BorderSide(color: theme.colorScheme.error, width: 2),
          shape:   RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Change password — calls real API ──────────────────────────────────────
  void _showChangePasswordDialog() {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl     = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool  isLoading           = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Change Password',
              style: TextStyle(color: colorScheme.onSurface)),
          backgroundColor: colorScheme.surface,
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (errorMsg != null) ...[
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(errorMsg!,
                    style: TextStyle(
                        color: colorScheme.error, fontSize: 13)),
              ),
              SizedBox(height: 12),
            ],
            _dialogField(currentPasswordCtrl,
                'Current Password', colorScheme),
            SizedBox(height: 12),
            _dialogField(newPasswordCtrl,
                'New Password', colorScheme),
            SizedBox(height: 12),
            _dialogField(confirmPasswordCtrl,
                'Confirm Password', colorScheme),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordCtrl.text !=
                          confirmPasswordCtrl.text) {
                        setDlgState(
                            () => errorMsg = 'Passwords do not match');
                        return;
                      }
                      setDlgState(() => isLoading = true);
                      try {
                        await ApiService().changePassword(
                          _user!.id,
                          currentPasswordCtrl.text,
                          newPasswordCtrl.text,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('Password updated!'),
                            backgroundColor: Color(0xFF10b981),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } catch (e) {
                        setDlgState(() {
                          isLoading = false;
                          errorMsg  = e
                              .toString()
                              .replaceFirst('Exception: ', '');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label,
      ColorScheme colorScheme) {
    return TextField(
      controller:  ctrl,
      obscureText: true,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: colorScheme.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: colorScheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Logout',
            style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear auth state then go to login
              AuthService.instance.logout();
              Navigator.pop(ctx);
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

  void _showLanguageDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Select Language',
            style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'French', 'Spanish', 'German']
              .map((lang) => RadioListTile<String>(
                    title: Text(lang,
                        style:
                            TextStyle(color: colorScheme.onSurface)),
                    value:      lang,
                    groupValue: selectedLanguage,
                    activeColor: colorScheme.primary,
                    onChanged: (v) {
                      setState(() => selectedLanguage = v!);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showModelDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Default Model',
            style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['MES01', 'MES02', 'MES03', 'MES04']
              .map((model) => RadioListTile<String>(
                    title: Text(model,
                        style:
                            TextStyle(color: colorScheme.onSurface)),
                    value:      model,
                    groupValue: defaultModel,
                    activeColor: colorScheme.primary,
                    onChanged: (v) {
                      setState(() => defaultModel = v!);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final colorScheme      = Theme.of(context).colorScheme;
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Send Feedback',
            style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: TextField(
          controller: feedbackCtrl,
          maxLines:   5,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:  'Tell us what you think...',
            hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: colorScheme.primary.withOpacity(0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:         Text('Thank you for your feedback!'),
                backgroundColor: colorScheme.primary,
                behavior:        SnackBarBehavior.floating,
              ));
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

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text('$feature coming soon!'),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.primary,
    ));
  }
}