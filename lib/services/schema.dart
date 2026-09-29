const String kSchemaKey = 'schema';

typedef DocMigration = Map<String, dynamic> Function(Map<String, dynamic> doc);

final List<DocMigration> kMigrations = [];

int get kSchemaVersion => kMigrations.length + 1;

class SchemaTooNew implements Exception {
  const SchemaTooNew(this.found, this.supported);
  final int found;
  final int supported;
}

int schemaOf(Map<String, dynamic> doc) {
  final v = doc[kSchemaKey];
  return v is num && v >= 1 ? v.toInt() : 1;
}

Map<String, dynamic> migrateDocument(Map<String, dynamic> doc, {List<DocMigration>? migrations}) {
  final steps = migrations ?? kMigrations;
  final target = steps.length + 1;
  var version = schemaOf(doc);
  if (version > target) throw SchemaTooNew(version, target);
  var out = {...doc};
  while (version < target) {
    out = steps[version - 1](out);
    version++;
    out[kSchemaKey] = version;
  }
  return out;
}

const _listKeys = [
  'sessions',
  'bodyweight',
  'measures',
  'shots',
  'moments',
  'places',
  'routines',
  'custom',
  'checkins',
  'noSuggest',
  'archived',
  'warmup',
  'repsOnly',
  'repsOnlyOff',
  'awardsSeen',
];

const _mapKeys = [
  'profile',
  'favorites',
  'weeklyPlan',
  'planExtras',
  'media',
  'exRest',
  'progress',
  'marks',
  'exMode',
  'awards',
];

const _markers = [
  ..._listKeys,
  ..._mapKeys,
  kSchemaKey,
  'notes',
  'exNotes',
  'dark',
  'onboarded',
  'units',
  'theme',
  'language',
];

enum DocumentProblem { notGymMane, wrongShape, newer }

DocumentProblem? checkDocument(Map<String, dynamic> doc) {
  if (!_markers.any(doc.containsKey)) return DocumentProblem.notGymMane;
  if (schemaOf(doc) > kSchemaVersion) return DocumentProblem.newer;
  for (final k in _listKeys) {
    if (doc[k] != null && doc[k] is! List) return DocumentProblem.wrongShape;
  }
  for (final k in _mapKeys) {
    if (doc[k] != null && doc[k] is! Map) return DocumentProblem.wrongShape;
  }
  return null;
}
