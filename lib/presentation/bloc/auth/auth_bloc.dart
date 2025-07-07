import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:talk_trip/data/models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Isar isar;
  AuthBloc(this.isar) : super(AuthInitial()) {
    on<SignUpWithEmail>(_onSignUpWithEmail);
    on<SignInWithEmail>(_onSignInWithEmail);
    on<SignInWithGoogle>(_onSignInWithGoogle);
    on<SignOut>(_onSignOut);
  }

  Future<void> _onSignUpWithEmail(
      SignUpWithEmail event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final existing =
          await isar.users.filter().emailEqualTo(event.email).findFirst();
      if (existing != null) {
        emit(AuthError('Email already exists'));
        return;
      }
      final user = User()
        ..email = event.email
        ..password = event.password
        ..name = event.name;
      await isar.writeTxn(() async => await isar.users.put(user));
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Sign up failed'));
    }
  }

  Future<void> _onSignInWithEmail(
      SignInWithEmail event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user =
          await isar.users.filter().emailEqualTo(event.email).findFirst();
      if (user == null || user.password != event.password) {
        emit(AuthError('Invalid credentials'));
        return;
      }
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Sign in failed'));
    }
  }

  Future<void> _onSignInWithGoogle(
      SignInWithGoogle event, Emitter<AuthState> emit) async {
    // TODO: Google sign-in logic
    emit(AuthError('Google sign-in not implemented'));
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    emit(AuthInitial());
  }
}
