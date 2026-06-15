class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  bool get isFr => lang == 'fr';

  // ══════════════════════════════════════════════════════════════════════════
  //  NAVIGATION
  // ══════════════════════════════════════════════════════════════════════════
  String get home          => isFr ? 'Accueil'      : 'Home';
  String get history       => isFr ? 'Historique'   : 'History';
  String get reports       => isFr ? 'Rapports'     : 'Reports';
  String get settings      => isFr ? 'Paramètres'   : 'Settings';
  String get importManager => isFr ? "Gestionnaire d'Import" : 'Import Manager';

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGIN PAGE
  // ══════════════════════════════════════════════════════════════════════════
  String get login             => isFr ? 'Connexion'                              : 'Login';
  String get loginHero         => isFr ? 'Bon\nretour.'                           : 'Welcome\nback.';
  String get loginSubtitle     => isFr ? 'Connectez-vous pour accéder à votre espace.' : 'Sign in to access your workspace.';
  String get loginFormSubtitle => isFr ? 'Entrez vos identifiants pour continuer.'     : 'Enter your credentials to continue.';
  String get loginBtn          => isFr ? 'Se connecter'                           : 'Sign in';
  String get rememberMe        => isFr ? 'Se souvenir de moi'                     : 'Remember me';
  String get forgotPassword    => isFr ? 'Mot de passe oublié ?'                  : 'Forgot password?';
  String get noAccount         => isFr ? 'Pas encore de compte ?  '               : "Don't have an account?  ";
  String get createAccount     => isFr ? 'Créer un compte'                        : 'Create an account';

  // ══════════════════════════════════════════════════════════════════════════
  //  REGISTER PAGE
  // ══════════════════════════════════════════════════════════════════════════
  String get registerHero        => isFr ? 'Commencez\nici.'                          : 'Start\nhere.';
  String get registerSubtitle    => isFr ? 'Créez votre compte en quelques secondes.' : 'Create your account in seconds.';
  String get registerFormSubtitle => isFr ? 'Remplissez les informations ci-dessous pour commencer.' : 'Fill in the information below to get started.';
  String get createAccountTitle  => isFr ? 'Créer un compte'                         : 'Create account';
  String get createAccountBtn    => isFr ? 'Créer le compte'                          : 'Create account';
  String get alreadyAccount      => isFr ? 'Vous avez déjà un compte ?  '             : 'Already have an account?  ';
  String get signIn              => isFr ? 'Se connecter'                              : 'Sign in';
  String get iAccept             => isFr ? "J'accepte les "                            : 'I accept the ';
  String get termsOfUse          => isFr ? "conditions d'utilisation"                  : 'terms of use';
  String get acceptTermsRequired => isFr ? "Veuillez accepter les conditions d'utilisation" : 'Please accept the terms of use';
  String get accountCreated      => isFr ? 'Compte créé avec succès !'                : 'Account created successfully!';
  String get yourCompany         => isFr ? 'Votre entreprise'                          : 'Your company';
  String get required            => isFr ? 'Requis'                                    : 'Required';
  String get min3chars           => isFr ? 'Min. 3 caractères'                         : 'Min. 3 characters';
  String get min6chars           => isFr ? 'Min. 6 caractères'                         : 'Min. 6 characters';
  String get notIdentical        => isFr ? 'Non identiques'                             : 'Not matching';
  String get confirmPasswordLabel => isFr ? 'Confirmer'                                : 'Confirm';

  // ══════════════════════════════════════════════════════════════════════════
  //  FORGOT PASSWORD PAGE
  // ══════════════════════════════════════════════════════════════════════════
  String get forgotHero    => isFr ? 'Mot de passe\noublié ?'   : 'Forgot\npassword?';
  String get forgotHeroSub => isFr ? "Pas de panique, on s'en occupe." : "No worries, we'll handle it.";
  String get resetTitle    => isFr ? 'Réinitialiser'            : 'Reset password';
  String get resetSubtitle => isFr
      ? "Entrez votre adresse e-mail et nous vous enverrons un lien de réinitialisation."
      : "Enter your email address and we'll send you a reset link.";
  String get sendLink      => isFr ? 'Envoyer le lien'          : 'Send link';
  String get backToLogin   => isFr ? 'Retour à la connexion'    : 'Back to login';
  String get emailSent     => isFr ? 'Email envoyé !'           : 'Email sent!';
  String emailSentDesc(String addr) => isFr
      ? "Si l'adresse e-mail\n$addr\nexiste dans notre système, vous recevrez un lien de réinitialisation valable 1 heure."
      : "If the email address\n$addr\nexists in our system, you will receive a reset link valid for 1 hour.";

  // ══════════════════════════════════════════════════════════════════════════
  //  COMMON FORM
  // ══════════════════════════════════════════════════════════════════════════
  String get email            => isFr ? 'Adresse e-mail'        : 'Email address';
  String get emailRequired    => isFr ? 'Veuillez entrer votre e-mail' : 'Please enter your email';
  String get emailInvalid     => isFr ? 'Adresse e-mail invalide'      : 'Invalid email address';
  String get password         => isFr ? 'Mot de passe'          : 'Password';
  String get passwordRequired => isFr ? 'Veuillez entrer votre mot de passe' : 'Please enter your password';
  String get cancel           => isFr ? 'Annuler'               : 'Cancel';
  String get confirm          => isFr ? 'Confirmer'             : 'Confirm';
  String get save             => isFr ? 'Enregistrer'           : 'Save';
  String get send             => isFr ? 'Envoyer'               : 'Send';
  String get close            => isFr ? 'Fermer'                : 'Close';
  String get retry            => isFr ? 'Réessayer'             : 'Retry';
  String get refresh          => isFr ? 'Rafraîchir'            : 'Refresh';

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGOUT
  // ══════════════════════════════════════════════════════════════════════════
  String get logout           => isFr ? 'Se déconnecter'        : 'Logout';
  String get logoutQuestion   => isFr ? 'Se déconnecter ?'      : 'Log out?';
  String get logoutConfirm    => isFr ? 'Êtes-vous sûr de vouloir vous déconnecter ?' : 'Are you sure you want to logout?';
  String get logoutConfirmBtn => isFr ? 'Déconnecter'           : 'Disconnect';

  // ══════════════════════════════════════════════════════════════════════════
  //  HISTORY PAGE
  // ══════════════════════════════════════════════════════════════════════════
  String get historyTitle     => isFr ? 'Historique des imports'             : 'Import history';
  String get historySearch    => isFr ? 'Rechercher par fichier ou modèle…'  : 'Search by file or model…';
  String get historyLoadError => isFr ? "Impossible de charger l'historique" : 'Unable to load history';
  String get filterAll        => isFr ? 'Tous'                               : 'All';
  String get filterSuccess    => isFr ? 'Succès'                             : 'Success';
  String get filterFailed     => isFr ? 'Échec'                              : 'Failed';
  String get statTotal        => isFr ? 'Total'                              : 'Total';
  String get statFailed       => isFr ? 'Échecs'                             : 'Failures';
  String get noImportFound    => isFr ? 'Aucun import trouvé'                : 'No import found';
  String get tryOtherKeywords => isFr ? "Essayez d'autres mots-clés"        : 'Try other keywords';
  String get importsWillAppear => isFr ? 'Vos imports apparaîtront ici'     : 'Your imports will appear here';
  String get importDetails    => isFr ? "Détails de l'import"               : 'Import details';
  String get detailFile       => isFr ? 'Fichier'                            : 'File';
  String get detailModel      => isFr ? 'Modèle'                             : 'Model';
  String get detailStatus     => isFr ? 'Statut'                             : 'Status';
  String get detailRows       => isFr ? 'Lignes'                             : 'Rows';
  String get detailMessage    => isFr ? 'Message'                            : 'Message';
  String get detailDate       => isFr ? 'Date'                               : 'Date';
  String get downloadCsv      => isFr ? 'Télécharger CSV'                    : 'Download CSV';
  String get downloadError    => isFr ? 'Erreur lors du téléchargement'      : 'Download error';
  String get loading          => isFr ? 'Chargement…'                        : 'Loading…';

  // ══════════════════════════════════════════════════════════════════════════
  //  HOME / HERO CARDS — desktop
  // ══════════════════════════════════════════════════════════════════════════
  String get heroModelTitle => isFr ? 'Sélection de Modèle'  : 'Model Selection';
  String get heroModelDesc  => isFr
      ? "Parcourez les modèles d'import Sage X3 et téléchargez un template Excel pré-formaté."
      : 'Browse Sage X3 import models and download a pre-formatted Excel template.';
  String get heroModelBtn   => isFr ? 'Voir les modèles'     : 'View models';
  String get modelsCount    => isFr ? 'modèles'              : 'models';

  String get heroCsvTitle   => isFr ? 'Conversion CSV'       : 'CSV Conversion';
  String get heroCsvDesc    => isFr
      ? "Importez votre fichier Excel, validez chaque champ et générez instantanément un CSV prêt pour Sage X3."
      : 'Import your Excel file, validate each field and instantly generate a CSV ready for Sage X3.';
  String get heroCsvBtn     => isFr ? 'Importer un fichier'  : 'Import a file';
  String get importsCount   => isFr ? 'imports'              : 'imports';

  String get heroMappingTitle => isFr ? 'Import Personnalisé'  : 'Custom Import';
  String get heroMappingDesc  => isFr
      ? "Mappez vos propres colonnes Excel vers les champs Sage X3 par glisser-déposer."
      : 'Map your own Excel columns to Sage X3 fields by drag and drop.';
  String get heroMappingBtn   => isFr ? 'Mapper les colonnes'  : 'Map columns';

  String get heroScanTitle  => isFr ? 'Scanner un document'   : 'Scan a document';
  String get heroScanDesc   => isFr
      ? "Prenez une photo de votre tableau papier — l'IA extrait les données et les convertit en Excel."
      : 'Take a photo of your paper table — AI extracts the data and converts it to Excel.';
  String get heroScanBtn    => isFr ? 'Scanner & Importer'    : 'Scan & Import';

  // ── Mobile (short)
  String get heroModelDescShort   => isFr
      ? 'Parcourez les modèles, téléchargez le template Excel.'
      : 'Browse models, download the Excel template.';
  String get heroCsvDescShort     => isFr
      ? 'Importez Excel, validez les champs, générez le CSV.'
      : 'Import Excel, validate fields, generate the CSV.';
  String get heroMappingDescShort => isFr
      ? 'Mappez vos colonnes Excel vers les champs Sage X3.'
      : 'Map your Excel columns to Sage X3 fields.';
  String get heroScanDescShort    => isFr
      ? "Photo de votre tableau papier → Excel automatique via IA."
      : 'Photo of your paper table → automatic Excel via AI.';

  // ══════════════════════════════════════════════════════════════════════════
  //  HOW IT WORKS
  // ══════════════════════════════════════════════════════════════════════════
  String get howItWorks => isFr ? 'Comment ça marche' : 'How it works';
  String get step1Title => isFr ? 'Télécharger'       : 'Download';
  String get step1Desc  => isFr
      ? "Obtenez un template Excel pré-formaté depuis les modèles Sage X3"
      : 'Get a pre-formatted Excel template from Sage X3 models';
  String get step2Title => isFr ? 'Remplir'           : 'Fill in';
  String get step2Desc  => isFr
      ? "Saisissez vos données en suivant les en-têtes et les règles de format"
      : 'Enter your data following the headers and format rules';
  String get step3Title => isFr ? 'Importer'          : 'Import';
  String get step3Desc  => isFr
      ? "Importez votre fichier — la validation et la génération CSV sont automatiques"
      : 'Import your file — validation and CSV generation are automatic';

  // ══════════════════════════════════════════════════════════════════════════
  //  PRO TIP
  // ══════════════════════════════════════════════════════════════════════════
  String get proTipTitle => isFr ? 'Commencez avec un template' : 'Start with a template';
  String get proTipDesc  => isFr
      ? "Les templates contiennent tous les champs requis et les règles de format — ils vous évitent les erreurs d'import."
      : 'Templates contain all required fields and format rules — they help you avoid import errors.';

  // ══════════════════════════════════════════════════════════════════════════
  //  KPI
  // ══════════════════════════════════════════════════════════════════════════
  String get kpiImports => isFr ? 'Imports'  : 'Imports';
  String get kpiSuccess => isFr ? 'Succès'   : 'Success';
  String get kpiFailed  => isFr ? 'Échecs'   : 'Failures';
  String get kpiRate    => isFr ? 'Taux'     : 'Rate';

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTIVITY / MODELS / STATS
  // ══════════════════════════════════════════════════════════════════════════
  String get recentActivity => isFr ? 'Activité récente'               : 'Recent activity';
  String get noActivity     => isFr ? 'Aucune activité pour le moment' : 'No activity yet';
  String get lines          => isFr ? 'lignes'                         : 'rows';
  String get statusDone     => isFr ? 'Terminé'                        : 'Done';
  String get statusFailed   => isFr ? 'Échec'                          : 'Failed';
  String get topModels      => isFr ? 'Modèles les plus utilisés'      : 'Most used models';
  String get noData         => isFr ? 'Aucune donnée'                  : 'No data';
  String get convertedRows  => isFr ? 'Lignes converties'              : 'Converted rows';
  String get usedModels     => isFr ? 'Modèles utilisés'               : 'Models used';

  // ══════════════════════════════════════════════════════════════════════════
  //  TIME AGO
  // ══════════════════════════════════════════════════════════════════════════
  String get justNow              => isFr ? "À l'instant"   : 'Just now';
  String daysAgo(int n)    => isFr ? 'il y a ${n}j'         : '${n}d ago';
  String hoursAgo(int n)   => isFr ? 'il y a ${n}h'         : '${n}h ago';
  String minutesAgo(int n) => isFr ? 'il y a ${n}min'       : '${n}min ago';

  // ══════════════════════════════════════════════════════════════════════════
  //  ERRORS
  // ══════════════════════════════════════════════════════════════════════════
  String get loadError => isFr ? 'Impossible de charger les données' : 'Unable to load data';

  // ══════════════════════════════════════════════════════════════════════════
  //  SETTINGS PAGE
  // ══════════════════════════════════════════════════════════════════════════
  String get account           => isFr ? 'Compte'                        : 'Account';
  String get preferences       => isFr ? 'Préférences'                   : 'Preferences';
  String get support           => isFr ? 'Support'                       : 'Support';
  String get about             => isFr ? 'À propos'                      : 'About';
  String get editProfile       => isFr ? 'Modifier le profil'            : 'Edit profile';
  String get editProfileSub    => isFr ? 'Nom, téléphone, société'       : 'Name, phone, company';
  String get changePassword    => isFr ? 'Changer le mot de passe'       : 'Change password';
  String get changePasswordSub => isFr ? 'Mettre à jour votre mot de passe' : 'Update your password';
  String get darkMode          => isFr ? 'Mode sombre'                   : 'Dark mode';
  String get darkModeSub       => isFr ? 'Activer le thème sombre'       : 'Enable dark theme';
  String get language          => isFr ? 'Langue'                        : 'Language';
  String get chooseLanguage    => isFr ? 'Choisir la langue'             : 'Choose language';
  String get sendFeedback      => isFr ? 'Envoyer un commentaire'        : 'Send feedback';
  String get sendFeedbackSub   => isFr ? 'Signalez un problème ou une suggestion' : 'Report an issue or suggestion';
  String get help              => isFr ? 'Aide & FAQ'                    : 'Help & FAQ';
  String get helpSub           => isFr ? "Obtenir de l'aide"             : 'Get help';
  String get privacy           => isFr ? 'Politique de confidentialité'  : 'Privacy policy';
  String get privacySub        => isFr ? 'Consulter la politique'        : 'View policy';
  String get appVersion        => isFr ? "Version de l'application"      : 'App version';
  String get comingSoon        => isFr ? 'bientôt disponible'            : 'coming soon';

  // ══════════════════════════════════════════════════════════════════════════
  //  PROFILE
  // ══════════════════════════════════════════════════════════════════════════
  String get fullName        => isFr ? 'Nom complet'               : 'Full name';
  String get phone           => isFr ? 'Numéro de téléphone'       : 'Phone number';
  String get company         => isFr ? 'Société / Entreprise'      : 'Company';
  String get nonEditable     => isFr ? 'Non modifiable'            : 'Read only';
  String get profileUpdated  => isFr ? 'Profil mis à jour avec succès' : 'Profile updated successfully';
  String get nameRequired    => isFr ? 'Le nom est obligatoire'    : 'Name is required';
  String get personalInfo    => isFr ? 'Informations personnelles' : 'Personal information';

  // ══════════════════════════════════════════════════════════════════════════
  //  PASSWORD
  // ══════════════════════════════════════════════════════════════════════════
  String get currentPassword   => isFr ? 'Mot de passe actuel'           : 'Current password';
  String get newPassword       => isFr ? 'Nouveau mot de passe'           : 'New password';
  String get confirmPassword   => isFr ? 'Confirmer le mot de passe'      : 'Confirm password';
  String get passwordMismatch  => isFr ? 'Les mots de passe ne correspondent pas' : 'Passwords do not match';
  String get passwordMin       => isFr ? 'Minimum 6 caractères requis'    : 'Minimum 6 characters required';
  String get passwordUpdated   => isFr ? 'Mot de passe mis à jour avec succès' : 'Password updated successfully';
  String get passwordStrength  => isFr ? 'Force : '                       : 'Strength: ';
  String get weak              => isFr ? 'Faible'                         : 'Weak';
  String get medium            => isFr ? 'Moyen'                          : 'Medium';
  String get good              => isFr ? 'Bon'                            : 'Good';
  String get strong            => isFr ? 'Fort'                           : 'Strong';
  String get passwordSecurity  => isFr ? 'Sécurité du compte'             : 'Account security';
  String get updatePassword    => isFr ? 'Mettre à jour'                  : 'Update';

  // ══════════════════════════════════════════════════════════════════════════
  //  FEEDBACK
  // ══════════════════════════════════════════════════════════════════════════
  String get feedbackSentTo => isFr
      ? "Votre commentaire sera envoyé à l'administrateur."
      : 'Your feedback will be sent to the administrator.';
  String get feedbackHint   => isFr
      ? 'Décrivez votre problème ou suggestion…'
      : 'Describe your issue or suggestion…';
  String get feedbackThanks => isFr
      ? 'Merci pour votre commentaire !'
      : 'Thank you for your feedback!';
}