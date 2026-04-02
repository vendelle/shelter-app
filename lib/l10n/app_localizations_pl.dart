// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Schroniskowy Tracker Spacerów';

  @override
  String get navOverview => 'Przegląd';

  @override
  String get navPlanner => 'Planer';

  @override
  String get navManage => 'Zarządzaj';

  @override
  String get walkOverview => 'Przegląd spacerów';

  @override
  String get refresh => 'Odśwież';

  @override
  String get dogs => 'Psy';

  @override
  String get thisWeek => 'Ten tydzień';

  @override
  String get lastWeek => 'Ostatni tydzień';

  @override
  String get allDogs => 'Wszystkie psy';

  @override
  String get mostUrgentFirst => 'Najpilniejsze';

  @override
  String get failedToLoadData => 'Nie udało się załadować danych';

  @override
  String get retry => 'Ponów';

  @override
  String get walkPlanner => 'Planer spacerów';

  @override
  String get walkGroup => 'Grupa spacerowa';

  @override
  String get solo => 'Solo';

  @override
  String groupN(int n) {
    return 'Grupa $n';
  }

  @override
  String get addNote => 'Dodaj notatkę';

  @override
  String noteFor(String name) {
    return 'Notatka dla $name';
  }

  @override
  String get noteHintDog => 'np. szpital, zabrać do weterynarza';

  @override
  String get noteHintVolunteer => 'np. 10-13, tylko 2 psy';

  @override
  String get remove => 'Usuń';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get saved => 'Zapisano';

  @override
  String get noWalksPlannedYet => 'Brak zaplanowanych spacerów';

  @override
  String get addFirstVolunteer => 'Dodaj pierwszego wolontariusza';

  @override
  String get addVolunteer => 'Dodaj wolontariusza';

  @override
  String get addVolunteerButton => 'Dodaj wolontariusza';

  @override
  String get searchVolunteers => 'Szukaj wolontariuszy...';

  @override
  String get allVolunteersAssigned => 'Wszyscy wolontariusze są już przypisani';

  @override
  String get noVolunteersMatch =>
      'Brak wolontariuszy pasujących do wyszukiwania';

  @override
  String get addDog => 'Dodaj psa';

  @override
  String get selectDogs => 'Wybierz psy';

  @override
  String get tapToAddLongPress =>
      'Dotknij, aby dodać • Przytrzymaj, aby wybrać kilka';

  @override
  String get allDogsAssigned => 'Wszystkie psy są już przypisane';

  @override
  String addNDogs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'psów',
      few: 'psy',
      one: 'psa',
    );
    return 'Dodaj $count $_temp0';
  }

  @override
  String removeVolunteerTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String removeVolunteerContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'psów',
      few: 'psów',
      one: 'psa',
    );
    return 'Spowoduje to odpisanie $count $_temp0.';
  }

  @override
  String get failedToLoadPlan => 'Nie udało się załadować planu';

  @override
  String nVolunteersNDogs(int volunteers, int dogs, int total) {
    return '$volunteers wolontariuszy  •  $dogs/$total psów';
  }

  @override
  String get manage => 'Zarządzaj';

  @override
  String get dogsTitleTab => 'Psy';

  @override
  String get volunteersTab => 'Wolontariusze';

  @override
  String get current => 'Obecne';

  @override
  String get adopted => 'Adoptowane';

  @override
  String get addDogButton => 'Dodaj psa';

  @override
  String get noDogsFound => 'Nie znaleziono psów';

  @override
  String get noAdoptedDogs => 'Brak adoptowanych psów';

  @override
  String get editDog => 'Edytuj psa';

  @override
  String get name => 'Imię';

  @override
  String get shelterId => 'ID schroniska';

  @override
  String get kennel => 'Boks';

  @override
  String get kennelHint => '3-cyfrowy numer';

  @override
  String get nameRequired => 'Imię jest wymagane';

  @override
  String get shelterIdRequired => 'ID schroniska jest wymagane';

  @override
  String get kennelRequired => 'Boks jest wymagany';

  @override
  String get markAsAdopted => 'Oznacz jako adoptowanego';

  @override
  String get restore => 'Przywróć';

  @override
  String get add => 'Dodaj';

  @override
  String get edit => 'Edytuj';

  @override
  String get active => 'Aktywni';

  @override
  String get inactive => 'Nieaktywni';

  @override
  String get addVolunteerTitle => 'Dodaj wolontariusza';

  @override
  String get editVolunteer => 'Edytuj wolontariusza';

  @override
  String get firstName => 'Imię';

  @override
  String get lastName => 'Nazwisko';

  @override
  String get role => 'Rola';

  @override
  String get firstNameRequired => 'Imię jest wymagane';

  @override
  String get lastNameRequired => 'Nazwisko jest wymagane';

  @override
  String get markAsInactive => 'Oznacz jako nieaktywnego';

  @override
  String get reactivate => 'Reaktywuj';

  @override
  String get noVolunteersFound => 'Nie znaleziono wolontariuszy';

  @override
  String get noInactiveVolunteers => 'Brak nieaktywnych wolontariuszy';

  @override
  String dogFamiliarity(String name) {
    return '$name — Znajomość psów';
  }

  @override
  String get allGood => 'Dobrze idzie';

  @override
  String get difficultButPossible => 'Trudny, ale możliwy';

  @override
  String get noChance => 'Bez szans';

  @override
  String get close => 'Zamknij';

  @override
  String failed(String error) {
    return 'Nie udało się: $error';
  }

  @override
  String failedToSave(String error) {
    return 'Nie udało się zapisać: $error';
  }

  @override
  String get roleSenior => 'Wolontariusz';

  @override
  String get roleIndependent => 'Samodzielny opiekun';

  @override
  String get roleSupporter => 'Wspierający';

  @override
  String get roleNew => 'Nowy';

  @override
  String get usingSystemTheme => 'Motyw systemowy';

  @override
  String get switchToLightMode => 'Przełącz na jasny motyw';

  @override
  String get switchToDarkMode => 'Przełącz na ciemny motyw';

  @override
  String get today => 'Dziś';

  @override
  String get weekdayMon => 'Pon';

  @override
  String get weekdayTue => 'Wt';

  @override
  String get weekdayWed => 'Śr';

  @override
  String get weekdayThu => 'Czw';

  @override
  String get weekdayFri => 'Pt';

  @override
  String get weekdaySat => 'Sob';

  @override
  String get weekdaySun => 'Niedz';

  @override
  String get monthJan => 'Sty';

  @override
  String get monthFeb => 'Lut';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Kwi';

  @override
  String get monthMay => 'Maj';

  @override
  String get monthJun => 'Cze';

  @override
  String get monthJul => 'Lip';

  @override
  String get monthAug => 'Sie';

  @override
  String get monthSep => 'Wrz';

  @override
  String get monthOct => 'Paź';

  @override
  String get monthNov => 'Lis';

  @override
  String get monthDec => 'Gru';

  @override
  String kennelLabel(String kennel) {
    return 'Boks: $kennel';
  }

  @override
  String get languageToggle => 'Zmień język';
}
