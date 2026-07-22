import 'package:flutter/material.dart';

class CatalogSignal {
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static void notifyChange() {
    notifier.value++;
  }
}