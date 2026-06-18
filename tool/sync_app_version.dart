import 'dart:io';

/// Sincroniza versión desde pubspec.yaml, compila APK y lo renombra.
///
/// Uso:
///   dart run tool/sync_app_version.dart release
///     → sync + flutter build apk --release + copiar Margeen-1.0.0+1.apk
///
///   dart run tool/sync_app_version.dart
///   flutter build apk --release
///   dart run tool/sync_app_version.dart copy
///
///   dart run tool/sync_app_version.dart bump patch
void main(List<String> args) async {
  final root = _findProjectRoot();
  final pubspecFile = File('${root.path}/pubspec.yaml');
  final configFile = File('${root.path}/tool/version_config.yaml');
  final appVersionFile = File('${root.path}/lib/core/config/app_version.dart');

  if (!pubspecFile.existsSync()) {
    stderr.writeln('No se encontró pubspec.yaml en ${root.path}');
    exit(1);
  }

  final command = args.isEmpty ? 'sync' : args.first;

  if (command == 'release') {
    await _runRelease(root, pubspecFile, configFile, appVersionFile);
    return;
  }

  if (command == 'copy') {
    final pubspec = pubspecFile.readAsStringSync();
    final version = _readPubspecVersion(pubspec);
    final slug = _readAppSlug(configFile);
    _writeAppVersionDart(appVersionFile, version, slug);
    final apkPath = _copyReleaseApk(root, slug, version.full);
    _printApkReady(slug, version.full, apkPath);
    return;
  }

  var pubspec = pubspecFile.readAsStringSync();
  var version = _readPubspecVersion(pubspec);

  if (command == 'bump') {
    final bumpTarget = args.length > 1 ? args[1] : null;
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
  _printSyncInfo(slug, version.full);

  if (command == 'sync') {
    stdout.writeln('');
    stdout.writeln('Compilar y nombrar APK (todo en uno):');
    stdout.writeln('  dart run tool/sync_app_version.dart release');
    stdout.writeln('');
    stdout.writeln('O manualmente:');
    stdout.writeln('  flutter build apk --release');
    stdout.writeln('  dart run tool/sync_app_version.dart copy');
  }
}

Future<void> _runRelease(
  Directory root,
  File pubspecFile,
  File configFile,
  File appVersionFile,
) async {
  final pubspec = pubspecFile.readAsStringSync();
  final version = _readPubspecVersion(pubspec);
  final slug = _readAppSlug(configFile);

  _writeAppVersionDart(appVersionFile, version, slug);
  stdout.writeln('→ Versión sincronizada: ${version.full}');

  stdout.writeln('→ Compilando APK release...');
  final build = await Process.start(
    'flutter',
    ['build', 'apk', '--release'],
    workingDirectory: root.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await build.exitCode;
  if (code != 0) {
    stderr.writeln('Error: flutter build terminó con código $code');
    exit(code);
  }

  final apkPath = _copyReleaseApk(root, slug, version.full);
  stdout.writeln('');
  _printApkReady(slug, version.full, apkPath);
}

void _printSyncInfo(String slug, String versionFull) {
  stdout.writeln('App: $slug');
  stdout.writeln('Versión: $versionFull');
  stdout.writeln('APK: $slug-$versionFull.apk');
  stdout.writeln('Generado: lib/core/config/app_version.dart');
}

void _printApkReady(String slug, String versionFull, String apkPath) {
  stdout.writeln('✓ APK listo para distribuir:');
  stdout.writeln('  $apkPath');
  stdout.writeln('');
  stdout.writeln('Nombre: $slug-$versionFull.apk');
}

String _copyReleaseApk(Directory root, String slug, String versionFull) {
  final outputDir = Directory('${root.path}/build/app/outputs/flutter-apk');
  final source = File('${outputDir.path}/app-release.apk');

  if (!source.existsSync()) {
    stderr.writeln('No se encontró app-release.apk');
    stderr.writeln('Ejecuta primero: flutter build apk --release');
    exit(1);
  }

  final target = File('${outputDir.path}/$slug-$versionFull.apk');
  source.copySync(target.path);
  return target.path;
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
  final match =
      RegExp(r'^version:\s*([^\s#]+)', multiLine: true).firstMatch(pubspec);
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
  stdout.writeln('  dart run tool/sync_app_version.dart release');
  stdout.writeln('  dart run tool/sync_app_version.dart copy');
  stdout.writeln('  dart run tool/sync_app_version.dart');
  stdout.writeln('  dart run tool/sync_app_version.dart bump patch');
  stdout.writeln('  dart run tool/sync_app_version.dart bump minor');
  stdout.writeln('  dart run tool/sync_app_version.dart bump major');
  stdout.writeln('  dart run tool/sync_app_version.dart bump build');
}
