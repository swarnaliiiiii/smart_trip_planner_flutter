part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class SignUpWithEmail extends AuthEvent {
  final String name;
  final String email;
  final String password;
  SignUpWithEmail(
      {required this.name, required this.email, required this.password});
}

class SignInWithEmail extends AuthEvent {
  final String email;
  final String password;
  SignInWithEmail({required this.email, required this.password});
}

class SignInWithGoogle extends AuthEvent {}

class SignOut extends AuthEvent {}
