import 'package:flutter/material.dart';

class CatalogSignal {
  // Un notificador simple que cambia su valor cada vez que hay una alteración
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  // Llama a este método cada vez que crees, edites, elimines o cambies el estado de algo
  static void notifyChange() {
    notifier.value++;
  }
}