import 'package:flutter/material.dart';

// A global notifier that holds the current theme mode (Light or Dark)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);