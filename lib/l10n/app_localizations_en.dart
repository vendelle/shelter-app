// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Shelter Walk Tracker';

  @override
  String get navOverview => 'Overview';

  @override
  String get navPlanner => 'Planner';

  @override
  String get navManage => 'Manage';

  @override
  String get walkOverview => 'Walk Overview';

  @override
  String get refresh => 'Refresh';

  @override
  String get dogs => 'Dogs';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastWeek => 'Last week';

  @override
  String get allDogs => 'All dogs';

  @override
  String get mostUrgentFirst => 'Most urgent first';

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get retry => 'Retry';

  @override
  String get walkPlanner => 'Walk Planner';

  @override
  String get walkGroup => 'Walk group';

  @override
  String get solo => 'Solo';

  @override
  String groupN(int n) {
    return 'Group $n';
  }

  @override
  String get addNote => 'Add note';

  @override
  String noteFor(String name) {
    return 'Note for $name';
  }

  @override
  String get noteHintDog => 'e.g. hospital, bring to vet';

  @override
  String get noteHintVolunteer => 'e.g. 10-13, 2 dogs only';

  @override
  String get remove => 'Remove';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get noWalksPlannedYet => 'No walks planned yet';

  @override
  String get addFirstVolunteer => 'Add first volunteer';

  @override
  String get addVolunteer => 'Add Volunteer';

  @override
  String get addVolunteerButton => 'Add volunteer';

  @override
  String get searchVolunteers => 'Search volunteers...';

  @override
  String get allVolunteersAssigned => 'All volunteers are already assigned';

  @override
  String get noVolunteersMatch => 'No volunteers match your search';

  @override
  String get addDog => 'Add dog';

  @override
  String get selectDogs => 'Select dogs';

  @override
  String get tapToAddLongPress =>
      'Tap to add  •  Long press to select multiple';

  @override
  String get allDogsAssigned => 'All dogs are already assigned';

  @override
  String addNDogs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dogs',
      one: 'dog',
    );
    return 'Add $count $_temp0';
  }

  @override
  String removeVolunteerTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String removeVolunteerContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dogs',
      one: 'dog',
    );
    return 'This will unassign $count $_temp0.';
  }

  @override
  String get failedToLoadPlan => 'Failed to load plan';

  @override
  String nVolunteersNDogs(int volunteers, int dogs, int total) {
    return '$volunteers volunteers  •  $dogs/$total dogs';
  }

  @override
  String get manage => 'Manage';

  @override
  String get dogsTitleTab => 'Dogs';

  @override
  String get volunteersTab => 'Volunteers';

  @override
  String get current => 'Current';

  @override
  String get adopted => 'Adopted';

  @override
  String get addDogButton => 'Add Dog';

  @override
  String get noDogsFound => 'No dogs found';

  @override
  String get noAdoptedDogs => 'No adopted dogs';

  @override
  String get editDog => 'Edit Dog';

  @override
  String get name => 'Name';

  @override
  String get shelterId => 'Shelter ID';

  @override
  String get kennel => 'Kennel';

  @override
  String get kennelHint => '3-digit number';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get shelterIdRequired => 'Shelter ID is required';

  @override
  String get kennelRequired => 'Kennel is required';

  @override
  String get markAsAdopted => 'Mark as adopted';

  @override
  String get restore => 'Restore';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get addVolunteerTitle => 'Add Volunteer';

  @override
  String get editVolunteer => 'Edit Volunteer';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get role => 'Role';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get markAsInactive => 'Mark as inactive';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get noVolunteersFound => 'No volunteers found';

  @override
  String get noInactiveVolunteers => 'No inactive volunteers';

  @override
  String dogFamiliarity(String name) {
    return '$name — Dog Familiarity';
  }

  @override
  String get allGood => 'All good';

  @override
  String get difficultButPossible => 'Difficult but possible';

  @override
  String get noChance => 'No chance';

  @override
  String get close => 'Close';

  @override
  String failed(String error) {
    return 'Failed: $error';
  }

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get roleSenior => 'Volunteer';

  @override
  String get roleIndependent => 'Independent supporter';

  @override
  String get roleSupporter => 'Supporter';

  @override
  String get roleNew => 'New';

  @override
  String get usingSystemTheme => 'Using system theme';

  @override
  String get switchToLightMode => 'Switch to light mode';

  @override
  String get switchToDarkMode => 'Switch to dark mode';

  @override
  String get today => 'Today';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String kennelLabel(String kennel) {
    return 'Kennel: $kennel';
  }

  @override
  String get languageToggle => 'Change language';
}
