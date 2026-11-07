/// The website's kennel/region for a dog, when it differs from ours.
class LocationSuggestion {
  final String kennel;
  final String? region;

  const LocationSuggestion({required this.kennel, this.region});

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      kennel: json['kennel'] as String,
      region: json['region'] as String?,
    );
  }
}

/// What the shelter's website says about a dog (`GET /api/dogs?shelter=<id>`),
/// as last stored by the nightly sync or an "Odśwież teraz".
class ShelterProfile {
  final int dogId;

  /// Our current kennel/region (not the website's).
  final String? kennel;
  final String? region;

  /// The dog's page on the website; null if its shelter ID has no page.
  final String? url;

  /// False when the website has no dog with this shelter ID.
  final bool found;
  final String? status;
  final String? photoUrl;
  final String? breed;
  final String? color;
  final String? sex;
  final DateTime? birthDate;
  final double? weightKg;
  final bool? neutered;
  final DateTime? arrivalDate;
  final String? arrivalReason;
  final DateTime? departureDate;

  /// Kennel as written on the website, e.g. "430 R12 (domek)".
  final String? location;
  final String? description;
  final DateTime? fetchedAt;
  final LocationSuggestion? locationSuggestion;

  /// The website didn't answer; this is the previously stored data.
  final bool refreshFailed;

  const ShelterProfile({
    required this.dogId,
    this.kennel,
    this.region,
    this.url,
    this.found = false,
    this.status,
    this.photoUrl,
    this.breed,
    this.color,
    this.sex,
    this.birthDate,
    this.weightKg,
    this.neutered,
    this.arrivalDate,
    this.arrivalReason,
    this.departureDate,
    this.location,
    this.description,
    this.fetchedAt,
    this.locationSuggestion,
    this.refreshFailed = false,
  });

  /// "Odśwież teraz" re-fetches at most this often (the API enforces it too).
  static const refreshCooldown = Duration(minutes: 5);

  factory ShelterProfile.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.parse(value);
    }

    final suggestion = json['location_suggestion'] as Map<String, dynamic>?;
    return ShelterProfile(
      dogId: json['dog_id'] as int,
      kennel: json['kennel'] as String?,
      region: json['region'] as String?,
      url: json['url'] as String?,
      found: json['found'] as bool? ?? false,
      status: json['status'] as String?,
      photoUrl: json['photo_url'] as String?,
      breed: json['breed'] as String?,
      color: json['color'] as String?,
      sex: json['sex'] as String?,
      birthDate: date('birth_date'),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      neutered: json['neutered'] as bool?,
      arrivalDate: date('arrival_date'),
      arrivalReason: json['arrival_reason'] as String?,
      departureDate: date('departure_date'),
      location: json['location'] as String?,
      description: json['description'] as String?,
      fetchedAt: date('fetched_at')?.toLocal(),
      locationSuggestion: suggestion == null
          ? null
          : LocationSuggestion.fromJson(suggestion),
      refreshFailed: json['refresh_failed'] as bool? ?? false,
    );
  }

  /// Whether "Odśwież teraz" would fetch again rather than be a no-op.
  bool canRefresh({DateTime? now}) {
    final fetched = fetchedAt;
    if (fetched == null) return true;
    return (now ?? DateTime.now()).difference(fetched) >= refreshCooldown;
  }

  /// Age as whole (years, months) on [today], or null without a birth date.
  ({int years, int months})? ageOn(DateTime today) {
    final born = birthDate;
    if (born == null || born.isAfter(today)) return null;
    var months = (today.year - born.year) * 12 + today.month - born.month;
    if (today.day < born.day) months--;
    return (years: months ~/ 12, months: months % 12);
  }
}
