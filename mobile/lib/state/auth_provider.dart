import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewState {
  final AppUser? user;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final String? confirmationEmail;

  const AuthViewState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.confirmationEmail,
  });

  bool get isAuthenticated => user != null;

  AuthViewState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
    String? confirmationEmail,
    bool clearConfirmation = false,
  }) {
    return AuthViewState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      confirmationEmail: clearConfirmation
          ? null
          : (confirmationEmail ?? this.confirmationEmail),
    );
  }
}

final authProvider =
    StateNotifierProvider<AuthController, AuthViewState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController extends StateNotifier<AuthViewState> {
  final AuthRepository _repo;
  StreamSubscription<AuthState>? _authSub;

  AuthController(this._repo) : super(const AuthViewState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    AppUser? restored;
    try {
      restored = await _repo.restoreSession();
    } catch (_) {
      if (!mounted) return;
      state = const AuthViewState(
          isInitialized: true,
          errorMessage: 'Session could not be restored. Please sign in again.');
      return;
    }
    if (!mounted) return;
    state = AuthViewState(
      user: restored,
      isLoading: false,
      isInitialized: true,
    );

    final sb = SupabaseService.client;
    if (sb != null) {
      _authSub = sb.auth.onAuthStateChange.listen((data) async {
        final refreshed = await _repo.restoreSession();
        if (!mounted) return;
        state = state.copyWith(
          user: refreshed,
          clearUser: refreshed == null,
          isLoading: false,
        );
      });
    }
  }

  Future<bool> signInDemo(UserRole role) async {
    state = state.copyWith(
        isLoading: true, clearError: true, clearConfirmation: true);
    try {
      final demoUser = await _repo.signInDemo(role);
      state = state.copyWith(user: demoUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
        isLoading: true, clearError: true, clearConfirmation: true);
    try {
      final user = await _repo.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    state = state.copyWith(
        isLoading: true, clearError: true, clearConfirmation: true);
    try {
      final user = await _repo.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on EmailConfirmationRequired catch (e) {
      state = state.copyWith(
          isLoading: false,
          clearUser: true,
          confirmationEmail: e.email,
          clearError: true);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(
        isLoading: true, clearError: true, clearConfirmation: true);
    try {
      await _repo.signInWithGoogleOAuth();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _repo.resetPassword(email);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthViewState(
      user: null,
      isLoading: false,
      isInitialized: true,
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
