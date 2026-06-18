#!/usr/bin/env bash
# Compila APK release y lo copia con nombre: Margeen-1.0.0+1.apk
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ Sincronizando versión..."
dart run tool/sync_app_version.dart sync

VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
SLUG="$(grep '^app_slug:' tool/version_config.yaml | awk '{print $2}')"
OUTPUT_DIR="build/app/outputs/flutter-apk"
SOURCE_APK="${OUTPUT_DIR}/app-release.apk"
TARGET_APK="${OUTPUT_DIR}/${SLUG}-${VERSION}.apk"

echo ""
echo "→ Compilando APK release..."
flutter build apk --release

if [[ ! -f "$SOURCE_APK" ]]; then
  echo "Error: no se encontró $SOURCE_APK" >&2
  exit 1
fi

cp "$SOURCE_APK" "$TARGET_APK"

echo ""
echo "✓ APK listo:"
echo "  $TARGET_APK"
