#!/usr/bin/env bash
# Sync + build + copia APK con nombre: Margeen-1.0.0+1.apk
set -euo pipefail
cd "$(dirname "$0")/.."
dart run tool/sync_app_version.dart release
