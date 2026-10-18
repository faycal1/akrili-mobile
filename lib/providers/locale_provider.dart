import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage_service.dart';
import 'auth_provider.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final SecureStorageService _storage;

  LocaleNotifier(this._storage) : super(const Locale('fr')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final saved = await _storage.getLocale();
    if (saved != null && ['fr', 'ar', 'en'].contains(saved)) {
      state = Locale(saved);
    } else {
      // Default to French
      state = const Locale('fr');
      await _storage.saveLocale('fr');
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (!['fr', 'ar', 'en'].contains(languageCode)) return;
    state = Locale(languageCode);
    await _storage.saveLocale(languageCode);
  }
}

final appLocaleProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocaleNotifier(storage);
});
