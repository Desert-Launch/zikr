import 'package:flutter/material.dart';

/// Centralized color tokens migrated from the Angular THEME_COLORS document.
///
/// Convention: each unique hex is declared ONCE (the canonical).
/// All semantic aliases point at that canonical — so every hex has a single
/// source of truth while existing names remain available to callers.
class AppColors {
  AppColors._();

  // ==================== Auth (Native) Tokens ====================

  /// Soft pastel background gradient used in Auth screens.
  static const Color authGradientStart = Color(0xFFE8D5F5);
  static const Color authGradientMiddle = Color(0xFFF0E6F8);
  static const Color authGradientEnd = Color(0xFFD5E8F5);

  /// Surfaces and borders used in Auth screens.
  static const Color authCardBackground = Colors.white;
  static const Color authInputBackground = Color(0xFFF8F8F8);
  static const Color authInputBorder = Color(0xFFE8E8E8);

  /// Auth text colors.
  static const Color authTextPrimary = Color(0xFF333333);
  static const Color authTextSecondary = Color(0xFF888888);

  /// Primary CTA colors used in Auth (purple gradient).
  static const Color authPrimary = Color(0xFF7C3AED);
  static const Color authPrimaryDark = Color(0xFF5B21B6);

  // Core brand / purple identity
  static const Color brandMain = Color(0xFFC441F4);
  static const Color brandPurple = Color(0xFF754CCC);
  static const Color brandPurpleDark = Color(0xFF5B3A9D);
  static const Color brandPurpleAccent = Color(0xFFAF52DE);
  static const Color brandPurple100 = Color(0xFFD4C8EF);
  static const Color brandGradientPink = Color(0xFF9F46E8);
  static const Color brandGradientMagenta = Color(0xFFA73EE7);
  static const Color brandGradientCyan = Color(0xFF00EBFF);
  static const Color accentBlue = Color(0xFF82DBF7);
  static const Color accentCyan = Color(0xFF13ACE7);

  // Difficulty levels
  static const Color mediumLevel = Color(0xFFFFD147);

  // Noble black scale
  static const Color black800 = Color(0xFF0D0F10);
  static const Color black600 = Color(0xFF1A1D21);
  static const Color black500 = Color(0xFF363A3D);
  static const Color black300 = Color(0xFF9B9C9E);

  // Text & semantics
  static const Color textTitleDark = Colors.white;
  static const Color textBodyDark = Colors.white;
  static const Color textInformationDark = Color(0xFFD1D1D1);
  static const Color textInactiveDark = Color(0xFF5D5D5D);

  static const Color textTitleLight = Color(0xFF1C1C1C);
  static const Color textBodyLight = Color(0xFF222222);
  static const Color textInformationLight = textInactiveDark;
  static const Color textInactiveLight = textInactiveDark;
  static const Color textOutlineLabelLight = Color(0xFF292929);
  static const Color textSuccessLight = Color(0xFF029E62);

  static const Color semanticSuccess = textSuccessLight;
  static const Color semanticError = Color(0xFFDE247C);
  static const Color semanticDanger = Color(0xFFD0302F);
  static const Color semanticWarning = Color(0xFFE26F20);
  static const Color semanticInfo = accentBlue;

  // Surfaces - Dark theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkForeground = textTitleLight;
  static const Color darkBodyBackground = black600;
  static const Color darkAccent = Color(0xFF222027);
  static const Color darkBorderDefault = textOutlineLabelLight;
  static const Color darkSurfaceSuccess = Color(0xFF012D1F);
  static const Color darkSurfaceError = Color(0xFF510626);

  // Surfaces - Light theme
  static const Color lightBackground = Color(0xFFE0E0E0);
  static const Color lightForeground = Colors.white;
  static const Color lightBodyBackground = Color(0xFFFAF2F2);
  static const Color lightAccent = Color(0xFFF6F5FD);
  static const Color lightBorderDefault = textInformationDark;
  static const Color lightSurfaceSuccess = Color(0xFFECFDF4);
  static const Color lightSurfaceError = Color(0xFFFAEAFD);

  // Chat & messaging components
  static const Color chatBubbleBorder = Color(0x80B8B8B8);

  // Quiz / assessment
  static const Color questionActionBackground = Color(0xFFF6F7F9);
  static const Color questionActionBorder = Color(0x33000000);
  static const Color hintColor = semanticWarning;

  // Lists & cards
  static const Color listBackground = Color(0xFFF9F9F9);

  // Inputs & buttons
  static const Color tabsInactive = Color(0x661C1C1C);
  static const Color tabsActive = textTitleLight;

  // Utility
  static const Color transparent = Colors.transparent;

  // Subjects
  static const Color subjectMath = Color(0xFF4CAF50);
  static const Color subjectHistory = Color(0xFFFF9800);
  static const Color subjectChemistry = Color(0xFF9C27B0);
  static const Color subjectGeography = Color(0xFF00BCD4);
  static const Color subjectPsychology = Color(0xFFE91E63);

  static const Color secondScaffoldBackground = Color(0xFFF6F6F6);

  // Accent light (matches Angular --accentlight)
  static const Color accentLight = lightAccent;

  static const Color grey = Color(0xFF454545);

  // ==================== Faheem Text Colors (matching Board app) ====================

  /// Primary text color - dark gray for main content
  static const Color faheemTextPrimary = Color(0xFF1F2937);

  /// Secondary text color - medium gray for subtitles/descriptions
  static const Color faheemTextSecondary = Color(0xFF6B7280);

  /// Light text color - light gray for hints/placeholders
  static const Color faheemTextLight = Color(0xFF9CA3AF);

  /// White background color
  static const Color faheemBgWhite = Colors.white;

  /// Board/success green color
  static const Color faheemBoard = Color(0xFF10B981);

  // ==================== Faheem Home Screen Colors ====================

  // Hero Section
  static const Color faheemHeroGradientStart = Color(0xFFFBE5C0);
  static const Color faheemHeroGradientEnd = Color(0xFFF5D7A0);

  // Subject Chips
  static const Color faheemChipBorder = Color(0xFFE5E7EB);

  // Subject-specific colors (matching Board design)
  static const Color subjectMathBg = Color(0xFFD1FAE5);
  static const Color subjectEnglishColor = Color(0xFFF59E0B);
  static const Color subjectEnglishBg = Color(0xFFFEF3C7);
  static const Color subjectArabicColor = Color(0xFFEF4444);
  static const Color subjectArabicBg = Color(0xFFFEE2E2);
  static const Color subjectSocialColor = Color(0xFF8B5CF6);
  static const Color subjectSocialBg = Color(0xFFEDE9FE);
  static const Color subjectChemistryColor = Color(0xFF3B82F6);
  static const Color subjectChemistryBg = Color(0xFFDBEAFE);

  // Solve Card (صوّر وافهم)
  static const Color faheemSolveGradientStart = Color(0xFFE8A54B);

  // Mode Cards

  // Lock overlay

  // ==================== Quiz Session Colors ====================

  // Quiz Header (matching Board's faheemPrimaryGradient)
  static const Color quizHeaderGradientStart = Color(0xFF667EEA);
  static const Color quizHeaderGradientEnd = Color(0xFF764BA2);

  // Quiz Progress Bar
  static const Color quizProgressCurrent = quizHeaderGradientStart;
  static const Color quizProgressPending = faheemChipBorder;

  // No Help Notice (matching Board's faheemTest colors)
  static const Color quizNoHelpBg = subjectEnglishBg;
  static const Color quizNoHelpBorder = subjectEnglishColor;
  static const Color quizNoHelpText = Color(0xFF92400E);

  // Quiz Question Card
  static const Color quizQuestionNumberBg = quizHeaderGradientStart;

  // Quiz Answer Option (selected state)
  static const Color quizOptionSelectedBg = subjectSocialBg;
  static const Color quizOptionSelectedBorder = quizHeaderGradientStart;

  // ==================== Quiz Results Colors ====================

  // Results Header (reuse quiz header gradient)
  static const Color resultsHeaderGradientStart = quizHeaderGradientStart;
  static const Color resultsHeaderGradientEnd = quizHeaderGradientEnd;

  // Score Circle
  static const Color resultsScoreCircleBg = Colors.white;
  static const Color resultsScoreCircleShadow = Color(0x33000000);

  // Wrong Answers Card
  static const Color resultsWrongCardBg = Colors.white;
  static const Color resultsWrongItemBg = subjectArabicBg;
  static const Color resultsWrongItemBorder = Color(0xFFFCA5A5);
  static const Color resultsWrongNumberBg = subjectArabicColor;
  static const Color resultsWrongText = Color(0xFFB91C1C);

  // Grade Badge Colors
  static const Color gradeExcellent = faheemBoard;
  static const Color gradeGood = subjectChemistryColor;
  static const Color gradePass = subjectEnglishColor;
  static const Color gradeFail = subjectArabicColor;

  // ==================== Solve Screen Colors ====================

  // Solve Header (purple gradient - same as quiz)
  static const Color solveHeaderGradientStart = quizHeaderGradientStart;
  static const Color solveHeaderGradientEnd = quizHeaderGradientEnd;

  // Upload Area
  static const Color solveUploadBorder = quizHeaderGradientStart;
  static const Color solveUploadBg = Color(0xFFF5F3FF);
  static const Color solveUploadIconBg = subjectSocialBg;

  // Feature Card
  static const Color solveFeatureChipBg = subjectSocialBg;
  static const Color solveFeatureChipText = quizHeaderGradientStart;

  // Chat Messages

  // AI Response Card
  static const Color solveNarrationBg = subjectSocialBg;
  static const Color solveKeyPointBg = subjectMathBg;
  static const Color solveKeyPointBorder = faheemBoard;
  static const Color solveKeyPointText = Color(0xFF047857);

  // Bullet Colors
  static const Color solveBulletBlue = subjectChemistryColor;
  static const Color solveBulletGreen = faheemBoard;
  static const Color solveBulletPurple = subjectSocialColor;
  static const Color solveBulletOrange = subjectEnglishColor;
  static const Color solveBulletRed = subjectArabicColor;

  // ==================== Capsule Units Colors ====================

  // Header (purple gradient - same as quiz)
  static const Color capsuleHeaderGradientStart = quizHeaderGradientStart;
  static const Color capsuleHeaderGradientEnd = quizHeaderGradientEnd;

  // Unit Card
  static const Color capsuleUnitCardBg = Colors.white;
  static const Color capsuleUnitCardBorder = faheemChipBorder;
  static const Color capsuleUnitCardBorderExpanded = quizHeaderGradientStart;
  static const Color capsuleUnitNumberBg = quizHeaderGradientStart;

  // Lesson Item
  static const Color capsuleLessonBg = Color(0xFFF9FAFB);
  static const Color capsuleLessonNumberBg = subjectSocialBg;
  static const Color capsuleLessonNumberText = quizHeaderGradientStart;

  // الملزمة Button
  static const Color capsuleMolazmaGradientStart = subjectSocialColor;

  // ==================== Modern Audio Player Colors ====================

  // Warm gradient background (like the reference design)
  static const Color audioPlayerBgStart = Color(0xFFFDF4E3);
  static const Color audioPlayerBgMiddle = faheemHeroGradientStart;
  static const Color audioPlayerBgEnd = faheemHeroGradientEnd;

  // Waveform colors
  static const Color audioWaveformActive = faheemSolveGradientStart;
  static const Color audioWaveformInactive = Color(0xFFE0D5C5);

  // Player controls
  static const Color audioPlayerControlBg = faheemSolveGradientStart;
  static const Color audioPlayerControlIcon = Colors.white;
  static const Color audioPlayerSecondaryIcon = Color(0xFF4A4A4A);
  static const Color audioPlayerText = Color(0xFF2D2D2D);
  static const Color audioPlayerTextSecondary = Color(0xFF6B6B6B);

  // Illustration area

  // ==================== Clean Home Redesign Colors ====================

  // Canvas Background (soft grey-blue off-white)
  static const Color cleanCanvas = Color(0xFFF5F7FA);

  // Clean Card Surfaces
  static const Color cleanCardWhite = Colors.white;
  static const Color cleanCardShadow = Color(0x12000000); // 7% opacity
  static const Color cleanCardShadowLight = Color(0x08000000); // 3% opacity

  // Clean Text Colors
  static const Color cleanTextPrimary = Color(0xFF1A1A2E);
  static const Color cleanTextSecondary = faheemTextSecondary;
  static const Color cleanTextTertiary = faheemTextLight;

  // Hero Focus Card (gradient mesh - the only colorful element)
  static const Color heroGradientStart = quizHeaderGradientStart;
  static const Color heroGradientMiddle = quizHeaderGradientEnd;
  static const Color heroGradientEnd = subjectSocialColor;

  // Streak Badge
  static const Color streakOrange = Color(0xFFFF6B35);

  // AI Dock
  static const Color aiDockBg = Colors.white;

  // Mode Card Icons (colorful icons on white cards)
  static const Color modeStudyIcon = subjectChemistryColor;
  static const Color modeQuizIcon = subjectEnglishColor;
  static const Color modeNotesIcon = faheemBoard;
  static const Color modeAskIcon = subjectSocialColor;

  // FAB Colors (Extended Floating Action Button)
  static const Color fabOrangeDark = Color(0xFFD97706);

  // Solve Rejection Card
  static const Color solveRejectionBg = subjectEnglishBg;
  static const Color solveRejectionBorder = subjectEnglishColor;
  static const Color solveRejectionText = Color(0xFF92400E);

  // ==================== Progress — Session Types ====================
  static const Color sessionText = subjectChemistryColor;
  static const Color sessionVoice = subjectSocialColor;
  static const Color sessionVision = subjectEnglishColor;
  static const Color sessionQuiz = faheemBoard;
  static const Color sessionAssessment = subjectArabicColor;

  // ==================== Progress — Concept Status ====================
  static const Color conceptMastered = subjectMath;
  static const Color conceptInProgress = subjectHistory;
  static const Color conceptNotStarted = faheemChipBorder;
  static const Color conceptNotStartedLegend = lightBackground;

  // ==================== Progress — Misc ====================
  static const Color progressMasteryGold = Color(0xFFFFD700);

  // ==================== General Semantic Neutrals ====================
  static const Color neutralBorderLight = faheemChipBorder;
  static const Color neutralBorderMedium = Color(0xFFD1D5DB);
  static const Color neutralBgSubtle = capsuleLessonBg;
  static const Color neutralTextPrimary = faheemTextPrimary;
  static const Color neutralTextSecondary = faheemTextSecondary;

  // ==================== General Semantic Status ====================
  static const Color statusDangerRed = Color(0xFFDC2626);
  static const Color statusWarningAmber = subjectEnglishColor;

  // ==================== General Accents (bright Tailwind-ish palette) ====================
  static const Color accentGreen = faheemBoard;
  static const Color accentRed = subjectArabicColor;
  static const Color accentPurple = subjectSocialColor;
  static const Color accentBlueBright = subjectChemistryColor;
  static const Color accentOrange = subjectHistory;
  static const Color accentGreenMaterial = subjectMath;
  static const Color accentIndigo = quizHeaderGradientStart;
  static const Color accentIndigoDeep = quizHeaderGradientEnd;
  static const Color accentGoldAmber = progressMasteryGold;

  // ==================== Light Surface Backgrounds ====================
  static const Color neutralBg100 = Color(0xFFF3F4F6);
  static const Color surfaceLightYellow = subjectEnglishBg;
  static const Color surfaceLightRed = subjectArabicBg;
  static const Color surfaceLightPurple = subjectSocialBg;
  static const Color surfaceLightPurpleSoft = Color(0xFFF3E8FF);
  static const Color surfaceLightGreen = subjectMathBg;
  static const Color surfaceLightBlue = subjectChemistryBg;

  // ==================== Ask Feature Purple ====================
  static const Color askPurplePrimary = Color(0xFF7B2FFF);
  static const Color askPurpleGlow = Color(0xFF9D5CFF);

  // ==================== Additional Neutral ====================
  static const Color neutralGrey9CA3AF = faheemTextLight;

  // ==================== Tier-5 Shared Colors (2 uses) ====================
  static const Color woodBrown = Color(0xFF6B4E2E);
  static const Color woodBrownDark = Color(0xFF5C3D1E);
  static const Color woodBrownMedium = Color(0xFF4A3728);
  static const Color grey616161 = Color(0xFF616161);
  static const Color grey4A4A4A = audioPlayerSecondaryIcon;
  static const Color micActiveGreen = Color(0xFF00E676);
  static const Color linkBlueDark = Color(0xFF0056B3);

  // ==================== Tier-4 Shared Colors (3+ uses) ====================
  static const Color paperCream = Color(0xFFE0D8C8);
  static const Color paperWarm = Color(0xFFFAF6ED);
  static const Color pinkMagenta = Color(0xFFE040FB);
  static const Color darkNavy = cleanTextPrimary;
  static const Color darkSlate = Color(0xFF192729);
  static const Color accentCyan500 = subjectGeography;
  static const Color pink100 = Color(0xFFE9D5FF);
  static const Color pink500 = subjectPsychology;
  static const Color coral = Color(0xFFE8735A);
  static const Color amberDark = fabOrangeDark;
  static const Color purple200 = Color(0xFFD1C4FF);
  static const Color purple500 = subjectChemistry;
  static const Color green300 = Color(0xFF8BC48A);
}
