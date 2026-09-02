#!/usr/bin/env bash
set -euo pipefail

app_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$app_dir"

cp tool/ios_ad_free/monetization_service.dart lib/services/monetization_service.dart
cp tool/ios_ad_free/banner_slot.dart lib/features/banner_slot.dart
sed -i.bak \
  -e '/^[[:space:]]*google_mobile_ads:/d' \
  -e '/^[[:space:]]*in_app_purchase:/d' \
  pubspec.yaml
rm -f pubspec.yaml.bak

# The paid iOS binary must not contain Google's advertising application ID.
/usr/libexec/PlistBuddy -c 'Delete :GADApplicationIdentifier' ios/Runner/Info.plist 2>/dev/null || true

if rg -n 'google_mobile_ads|in_app_purchase|GADApplicationIdentifier' \
    lib pubspec.yaml ios/Runner/Info.plist; then
  echo 'iOS ad-free preparation left an advertising or IAP reference.' >&2
  exit 1
fi

echo 'Prepared paid, ad-free iOS source.'
