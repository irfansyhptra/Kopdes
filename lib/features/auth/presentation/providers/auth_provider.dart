import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/network/dio_client.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  sessionExpired,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// 1. Data Source and Repository Providers
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(dio: ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

// 2. Use Case Providers
final loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);
final registerUseCaseProvider = Provider(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);
final logoutUseCaseProvider = Provider(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);
final getCurrentUserUseCaseProvider = Provider(
  (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)),
);
final checkAuthStatusUseCaseProvider = Provider(
  (ref) => CheckAuthStatusUseCase(ref.watch(authRepositoryProvider)),
);
final updateProfileUseCaseProvider = Provider(
  (ref) => UpdateProfileUseCase(ref.watch(authRepositoryProvider)),
);

// 3. State Notifier Provider
final StateNotifierProvider<AuthStateNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
      return AuthStateNotifier(
        loginUseCase: ref.watch(loginUseCaseProvider),
        registerUseCase: ref.watch(registerUseCaseProvider),
        logoutUseCase: ref.watch(logoutUseCaseProvider),
        checkAuthStatusUseCase: ref.watch(checkAuthStatusUseCaseProvider),
        updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
        localDataSource: ref.watch(authLocalDataSourceProvider),
      );
    });

class AuthStateNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthLocalDataSource _localDataSource;

  AuthStateNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required AuthLocalDataSource localDataSource,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _logoutUseCase = logoutUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _localDataSource = localDataSource,
       super(AuthState.initial());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final isLoggedIn = await _checkAuthStatusUseCase();
      if (isLoggedIn) {
        final cachedUserModel = await _localDataSource.getUserCached();
        if (cachedUserModel != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: cachedUserModel.toEntity(),
          );
          return;
        }
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final session = await _loginUseCase(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final session = await _registerUseCase(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      state = AuthState(status: AuthStatus.authenticated, user: session.user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _logoutUseCase();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final updatedUser = await _updateProfileUseCase(name: name, phone: phone);
      state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated, // keep authenticated
        errorMessage: e.toString(),
      );
    }
  }

  void forceSessionExpired() {
    _localDataSource.clearSession();
    state = const AuthState(status: AuthStatus.sessionExpired);
  }
}
