#!/bin/bash
# Build script for Vercel deployment
# Passes Firebase and demo mode env vars to Flutter build

set -e

DART_DEFINES=""

# Add Firebase config if available
if [ -n "$FIREBASE_API_KEY" ]; then
  DART_DEFINES="--dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY"
  DART_DEFINES="$DART_DEFINES --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN"
  DART_DEFINES="$DART_DEFINES --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID"
  DART_DEFINES="$DART_DEFINES --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID"
  DART_DEFINES="$DART_DEFINES --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID"
fi

# Add demo mode if enabled
if [ "$FLUTTER_DEMO_MODE" = "true" ]; then
  DART_DEFINES="$DART_DEFINES --dart-define=FLUTTER_DEMO_MODE=true"
fi

# Build Flutter web app
flutter/bin/flutter build web --release --pwa-strategy=none $DART_DEFINES
