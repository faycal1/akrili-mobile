import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/notifications/fcm_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    onUnauthorized: () {
      storage.clearAuth();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(client: client, storage: storage);
});

// Holds whether active UI view is 'host' or 'guest'
final activeRoleModeProvider = StateProvider<String>((ref) => 'guest');

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;
  final SecureStorageService _storage;
  final Ref _ref;

  AuthStateNotifier(this._repository, this._storage, this._ref)
      : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    try {
      final savedUrl = await _storage.getBaseUrl();
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _repository.client.updateBaseUrl(savedUrl.trim());
      }

      final isAuth = await _repository.isAuthenticated();
      if (!isAuth) {
        state = const AsyncValue.data(null);
        return;
      }

      // Try fetching fresh profile from /api/me
      try {
        final user = await _repository.getMe();
        await _applyRoleMode(user);
        state = AsyncValue.data(user);
        // Register device token on startup if logged in
        FcmService.instance.registerDeviceToken(_repository);
        FcmService.instance.listenToTokenRefresh(_repository);
      } catch (e) {
        // Fallback to cached profile if offline
        final cached = await _repository.getCachedUser();
        if (cached != null) {
          await _applyRoleMode(cached);
          state = AsyncValue.data(cached);
        } else {
          state = const AsyncValue.data(null);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final savedUrl = await _storage.getBaseUrl();
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _repository.client.updateBaseUrl(savedUrl.trim());
      }

      await _repository.login(email: email, password: password);
      // Fetch fresh /api/me with roles
      final freshUser = await _repository.getMe();
      await _applyRoleMode(freshUser);
      state = AsyncValue.data(freshUser);

      // Register FCM device token
      FcmService.instance.registerDeviceToken(_repository);
      FcmService.instance.listenToTokenRefresh(_repository);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final savedUrl = await _storage.getBaseUrl();
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _repository.client.updateBaseUrl(savedUrl.trim());
      }

      await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        role: role,
      );
      final freshUser = await _repository.getMe();
      await _applyRoleMode(freshUser);
      state = AsyncValue.data(freshUser);

      // Register FCM device token
      FcmService.instance.registerDeviceToken(_repository);
      FcmService.instance.listenToTokenRefresh(_repository);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
    } finally {
      _ref.read(activeRoleModeProvider.notifier).state = 'guest';
      state = const AsyncValue.data(null);
    }
  }

  void handleUnauthorized() {
    // Local-only teardown: never call the server here. The token is already
    // rejected, so hitting /auth/logout or /device-tokens would 401 again and
    // re-enter this handler, looping. User-initiated logout() still hits the API.
    _storage.clearAuth();
    _storage.deleteFcmToken();
    _ref.read(activeRoleModeProvider.notifier).state = 'guest';
    state = const AsyncValue.data(null);
  }

  Future<void> switchRoleMode(String mode) async {
    _ref.read(activeRoleModeProvider.notifier).state = mode;
    await _storage.saveActiveRole(mode);
  }

  Future<void> _applyRoleMode(UserModel user) async {
    final savedRole = await _storage.getActiveRole();
    if (savedRole != null && (savedRole == 'host' || savedRole == 'guest')) {
      _ref.read(activeRoleModeProvider.notifier).state = savedRole;
    } else {
      // Branch default mode: if user is host and not tenant, default to host; else guest
      final defaultMode = user.isHost ? 'host' : 'guest';
      _ref.read(activeRoleModeProvider.notifier).state = defaultMode;
      await _storage.saveActiveRole(defaultMode);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  final client = ref.watch(apiClientProvider);

  final notifier = AuthStateNotifier(repo, storage, ref);
  client.onUnauthorized = notifier.handleUnauthorized;
  return notifier;
});
