// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'in_app_browser_pattern.dart';

bool isInAppBrowser() =>
    inAppBrowserUserAgent.hasMatch(html.window.navigator.userAgent);
