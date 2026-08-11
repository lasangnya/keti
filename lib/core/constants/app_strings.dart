class AppStrings {
  static const String study = 'Study';
  static const String startStudySession = 'Start study session';
  static const String participantCode = 'Participant code';
  static const String participantCodeHint = 'e.g. P014';
  static const String continueLabel = 'Continue';
  static const String changeParticipant = 'Use a different code';
  static const String day = 'Day';
  static const String resumeAvailable = 'Unfinished session found on this machine';
  static const String offlineCacheNote = 'Loaded from local cache (offline)';
  static const String startDay = 'Start Day';

  // ── Uniform compliance card (plan §5.4 — constant instrument) ────
  static const String complianceHydrationQuestion =
      'Did you drink some water?';
  static const String complianceBreakQuestion =
      'Did you take a short break?';
  static const String complianceButton1 = 'Done';
  static const String complianceButton2 = 'Not now';

  static const String testMode = 'Test Mode';
  static const String testModeActive = 'Test Mode Active';
  static const String reminderStyle = 'Reminder Style';
  static const String ambient = 'Ambient';
  static const String ambientSubtitle = 'Gentle visual reminders without disrupting focus';
  static const String character = 'Character';
  static const String characterSubtitle = 'Keti the capybara gives playful reminders and encouragement';
  static const String reminderType = 'Reminder Type';
  static const String cursor = 'Cursor Proximate';
  static const String cursorSubtitle = 'Near the cursor';
  static const String test = 'Test';
  static const String island = 'Dynamic Island';
  static const String islandSubtitle = 'Near the notch of your screen';
  static const String tray = 'System Tray';
  static const String traySubtitle = 'In your system tray';
  static const String testBreak = 'Break reminder';
  static const String testHydration = 'Hydration reminder';
  static const String notchSize = 'Notch Size';
  static const String small = 'Small';
  static const String medium = 'Medium';
  static const String large = 'Large';

  // ── In-app participant tutorial (design/in_app_participant_tutorial_v2.md) ──
  // Screen 1 — Welcome
  static const String tutorialWelcomeTitle = 'Welcome to the health-reminder study';
  static const String tutorialWelcomeBody =
      'Thank you for taking part.\n\n'
      'In this study, you will use a prototype that provides occasional '
      'on-screen reminders to support hydration and short movement breaks '
      'during normal computer work.\n\n'
      'The session is designed to fit around your usual work. There are no '
      'right or wrong ways to react to reminders.';

  // Screen 2 — Participant ID
  static const String tutorialIdTitle = 'Enter your Participant ID';
  static const String tutorialIdBody =
      'Please enter the Participant ID provided by the researcher.\n\n'
      'Use exactly the same ID:\n'
      '• in this prototype\n'
      '• in the pre-study questionnaire\n'
      '• in the end-of-session questionnaire\n'
      '• in the final questionnaire\n\n'
      'Do not enter your name or email address here.';
  static const String tutorialIdFieldLabel = 'Participant ID';
  static const String tutorialIdFieldHint = 'e.g. P014';
  static const String tutorialIdBlankError =
      'Please enter the Participant ID provided by the researcher. '
      "It starts with the letter 'P'";
  static const String tutorialIdInvalidError =
      'The Participant ID should start with the letter P followed by digits, '
      'for example P014.';

  // Screen 3 — Before you begin
  static const String tutorialPrepareTitle = 'Prepare for your session';
  static const String tutorialPrepareBody =
      'Before starting, please:\n\n'
      '1. Complete the pre-study questionnaire.\n'
      '2. Keep water within easy reach, if possible.\n'
      '3. Choose a time when you expect to work at your computer for '
      'approximately 2 hours.\n'
      '4. Work on your own usual tasks, such as reading, writing, coding, '
      'design work, or emails.';
  static const String tutorialOpenPreStudy = 'Open the pre-study questionnaire';
  static const String tutorialPreStudyDone = 'I have completed the pre-study questionnaire';

  // Screen 4 — During the session
  static const String tutorialDuringTitle = 'Work as you normally would';
  static const String tutorialDuringBody =
      'The prototype will run in the background while you work.\n\n'
      'From time to time, you may see a reminder to drink water or take a '
      'short movement break. Reminder appearances may vary during the study. '
      'This is an intended part of the prototype evaluation.\n\n'
      'Please continue with your usual work routine. Do not deliberately '
      'change how you work for the study.';

  // Screen 5 — How to respond to reminders
  static const String tutorialRespondTitle = 'Respond naturally';
  static const String tutorialRespondBody =
      'When a health reminder appears, respond in the way that feels most '
      'natural in your current situation.\n\n'
      '• If it is convenient, you may follow the suggestion.\n'
      '• If you are busy, you may dismiss or ignore it.\n'
      '• You do not need to take a break or drink water every time.\n\n'
      'Shortly after a reminder, you may see a brief response card asking '
      'whether you followed the suggested action.\n\n'
      '• Please answer it honestly based on what you actually did.\n'
      '• You may skip or ignore the card if you are busy.\n'
      '• There is no "correct" response.\n\n'
      'Honest, natural reactions are the most helpful for this study.';

  // Screen 6 — Quickly dismissing a reminder
  static const String tutorialDismissTitle = 'Need to focus? You can dismiss a reminder quickly';
  static const String tutorialDismissBody =
      'If a reminder is bothering your work or appears at an inconvenient '
      'moment, move the mouse rapidly from side to side (a quick shake).\n\n'
      'This will dismiss the reminder so that you can continue your work.';

  // Screen 7 — Safety and comfort
  static const String tutorialSafetyTitle = 'Your comfort comes first';
  static const String tutorialSafetyBody =
      'Only take a movement break if it is safe and comfortable for you. You '
      'may adapt or skip any suggested action.\n\n'
      'Stop the study session if you feel uncomfortable, unwell, or need to '
      'deal with an urgent task. You may withdraw as described in the consent '
      'information without any disadvantage.\n\n'
      'For technical problems, use the "Report a problem" button or contact '
      'the researcher.';
  static const String tutorialReportProblem = 'Report a problem';

  // Screen 8 — Finishing the session
  static const String tutorialFinishTitle = 'At the end of the session';
  static const String tutorialFinishBody =
      'When the session timer ends:\n\n'
      '1. Complete the End-of-Session Questionnaire.\n'
      '2. Enter the same Participant ID you used in this app.\n'
      '3. If you have another study session, follow the instructions from the '
      'researcher for when to complete it.\n\n'
      'Please complete the questionnaire soon after finishing the session, '
      'based on your experience in this session.';
  static const String startSession = 'Start session';

  // ── Completed-day views (study flow) ─────────────────────────────
  static const String dayCompleteTitle = 'Day complete';
  static const String dayCompleteThanks =
      'Thank you! All reminders for today are recorded.';
  static const String openEndOfSessionQuestionnaire =
      'Open End-of-Session Questionnaire';
  static const String startDay2 = 'Start Day 2';
  static const String day2NotActivated =
      'Day 2 has not been activated yet. The researcher will enable it — '
      'please check back later.';
  static const String openEndOfStudyQuestionnaire =
      'Open End-of-Study Questionnaire';
  static const String endOfStudyDone =
      'I have completed the study';
  static const String sessionCompleteTitle = 'Session complete';
  static const String sessionCompleteBody =
      'Thank you for completing this session.\n\n'
      'Please complete the End-of-Session Questionnaire now.';
  static const String studyCompleteTitle = 'Study complete';
  static const String studyCompleteBody =
      'Thank you for completing the study.\n\n'
      'Please complete the End-of-Study Questionnaire now.';
  static const String yourParticipantId = 'Your Participant ID:';
  static const String fallbackLinkHint = 'If the button cannot open a browser, use this link:';

  // ── Technical problem dialog ─────────────────────────────────────
  static const String technicalProblemTitle = 'Report a technical problem';
  static const String technicalProblemBody =
      'Please write to the researcher with a short description of what '
      'happened:\n\nLasan Gonsal Korala\nlasan@uni-bremen.de\n\n'
      'Do not include personal, sensitive, or confidential work information.';
  static const String technicalProblemMailto = 'Write an email';
}
