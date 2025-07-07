import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/presentation/bloc/auth/auth_bloc.dart';
import 'package:talk_trip/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:talk_trip/core/database/database_service.dart';
import 'package:talk_trip/presentation/screens/auth/sign_in_screen.dart';
import 'package:talk_trip/presentation/screens/auth/sign_up_screen.dart';
import 'package:talk_trip/presentation/screens/home/home_screen.dart';
import 'package:talk_trip/presentation/screens/itinerary/itinerary_flow_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TalkTrip',
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          final scaledMediaQueryData = mediaQueryData.copyWith(
            textScaler: TextScaler.noScaling,
          );
          return MediaQuery(
            data: scaledMediaQueryData,
            child: child!,
          );
        },
        home: FutureBuilder(
          future: DatabaseService.instance,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final isar = snapshot.data!;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => AuthBloc(isar)),
                  BlocProvider(create: (_) => ItineraryBloc(isar)),
                ],
                child: SignUpScreen(),
              );
            }
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
        routes: {
          '/signin': (_) => SignInScreen(),
          '/signup': (_) => SignUpScreen(),
          '/home': (_) => HomeScreen(),
          // '/itinerary': (_) => ItineraryFlowScreen(prompt: ''), // Use push with prompt param
        },
      ),
    );
  }
}
