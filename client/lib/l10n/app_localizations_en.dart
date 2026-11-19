// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ArogyaVani';

  @override
  String get welcomeTitle => 'Welcome to ArogyaVani';

  @override
  String get welcomeSubtitle => 'Your voice-first health companion in English and Kannada';

  @override
  String get getStarted => 'Get Started';

  @override
  String get homeTab => 'Home';

  @override
  String get reportsTab => 'Reports';

  @override
  String get medicineTab => 'Medicine';

  @override
  String get symptomsTab => 'Symptoms';

  @override
  String get profileTab => 'Profile';

  @override
  String get tapToSpeak => 'Tap microphone to speak';

  @override
  String get listening => 'Listening...';

  @override
  String get emergencyCall => 'Emergency 108';
}
