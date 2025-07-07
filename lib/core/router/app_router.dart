import 'package:flutter/material.dart';
import 'package:talk_trip/presentation/screens/auth/sign_in_screen.dart';
import 'package:talk_trip/presentation/screens/auth/sign_up_screen.dart';
import 'package:talk_trip/presentation/screens/home/home_screen.dart';
import 'package:talk_trip/presentation/screens/profile/profile_screen.dart';
import 'routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talk_trip/presentation/bloc/auth/auth_bloc.dart';
import 'package:talk_trip/data/models/user.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteManager.initialRoute:
        return _fade(SignUpScreen());
      case RouteManager.signIn:
        return _fade(SignInScreen());
      case RouteManager.home:
        return _fade(HomeScreen());
      case RouteManager.profile:
        return _fade(
          Builder(
            builder: (context) {
              final authState = BlocProvider.of<AuthBloc>(context).state;
              User? user;
              if (authState is Authenticated) {
                user = authState.user;
              } else {
                user = null;
              }
              return ProfileScreen(user: user);
            },
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
                child: Text('No route defined for \'${settings.name}\'')),
          ),
        );
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: Duration(milliseconds: 300),
    );
  }
}
