import 'dart:io';

/// Sincroniza la versión desde [pubspec.yaml] y opcionalmente la incrementa.
///
/// Uso:
///   dart run tool/sync_app_version.dart          # sync + mostrar info
///   dart run tool/sync_app_version.dart show
///   dart run tool/sync_app_version.dart bump patch
///   dart run tool/sync_app_version.dart bump minor
///   dart run tool/sync_app_version.dart bump major
///   dart run tool/sync_app_version.dart bump build
void main(List<String> args) {
  final root = _findProjectRoot();
  final pubspecFile = File('${root.path}/pubspec.yaml');
  final configFile = File('${root.path}/tool/version_config.yaml');
  final appVersionFile = File('${root.path}/lib/core/config/app_version.dart');

  if (!pubspecFile.existsSync()) {
    stderr.writeln('No se encontró pubspec.yaml en ${root.path}');
    exit(1);
  }

  final command = args.isEmpty ? 'sync' : args.first;
  final bumpTarget = args.length > 1 ? args[1] : null;

  var pubspec = pubspecFile.readAsStringSync();
  var version = _readPubspecVersion(pubspec);

  if (command == 'bump') {
    if (bumpTarget == null) {
      _printUsage();
      exit(1);
    }
    version = _bumpVersion(version, bumpTarget);
    pubspec = _writePubspecVersion(pubspec, version);
    pubspecFile.writeAsStringSync(pubspec);
    stdout.writeln('Versión actualizada → ${version.full}');
  } else if (command != 'sync' && command != 'show') {
    _printUsage();
    exit(1);
  }

  final slug = _readAppSlug(configFile);
  _writeAppVersionDart(appVersionFile, version, slug);

  stdout.writeln('App: $slug');
  stdout.writeln('Versión: ${version.full}');
  stdout.writeln('APK sugerido: $slug-${version.full}.apk');
  stdout.writeln('Generado: lib/core/config/app_version.dart');

  if (command == 'sync') {
    stdout.writeln('');
    stdout.writeln('Siguiente paso:');
    stdout.writeln('  ./tool/build_release_apk.sh');
    stdout.writeln('  # o: flutter build apk --release');
  }
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
}

class _AppVersion {
  const _AppVersion({
    required this.name,
    required this.build,
  });

  final String name;
  final int build;

  String get full => '$name+$build';
}

_AppVersion _readPubspecVersion(String pubspec) {
  final match = RegExp(r'^version:\s*([^\s#]+)', multiLine: true).firstMatch(pubspec);
  if (match == null) {
    stderr.writeln('No se pudo leer version: en pubspec.yaml');
    exit(1);
  }

  final raw = match.group(1)!;
  final parts = raw.split('+');
  final name = parts.first.trim();
  final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;

  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(name)) {
    stderr.writeln('Formato de versión inválido: $name (usa X.Y.Z)');
    exit(1);
  }

  return _AppVersion(name: name, build: build);
}

String _writePubspecVersion(String pubspec, _AppVersion version) {
  return pubspec.replaceFirst(
    RegExp(r'^version:\s*[^\n]+', multiLine: true),
    'version: ${version.full}',
  );
}

_AppVersion _bumpVersion(_AppVersion current, String target) {
  final parts = current.name.split('.').map(int.parse).toList();
  final build = current.build + 1;

  final name = switch (target) {
    'build' => current.name,
    'patch' => '${parts[0]}.${parts[1]}.${parts[2] + 1}',
    'minor' => '${parts[0]}.${parts[1] + 1}.0',
    'major' => '${parts[0] + 1}.0.0',
    _ => null,
  };

  if (name == null) {
    stderr.writeln('Tipo de bump inválido: $target');
    stderr.writeln('Usa: patch | minor | major | build');
    exit(1);
  }

  return _AppVersion(name: name, build: build);
}

String _readAppSlug(File configFile) {
  if (!configFile.existsSync()) {
    return 'Margeen';
  }

  for (final line in configFile.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('app_slug:')) {
      return trimmed.split(':').last.trim();
    }
  }

  return 'Margeen';
}

void _writeAppVersionDart(File file, _AppVersion version, String slug) {
  file.writeAsStringSync('''// Generado por: dart run tool/sync_app_version.dart
// No editar manualmente.

abstract final class AppVersion {
  static const name = '${version.name}';
  static const build = ${version.build};
  static const full = '${version.full}';
  static const apkSlug = '$slug';

  static String get label => 'v\$name (\$build)';
}
''');
}

void _printUsage() {
  stdout.writeln('Uso:');
  stdout.writeln('  dart run tool/sync_app_version.dart');
  stdout.writeln('  dart run tool/sync_app_version.dart show');
  stdout.writeln('  dart run tool/sync_app_version.dart bump patch');
  stdout.writeln('  dart run tool/sync_app_version.dart bump minor');
  stdout.writeln('  dart run tool/sync_app_version.dart bump major');
  stdout.writeln('  dart run tool/sync_app_version.dart bump build');
}
