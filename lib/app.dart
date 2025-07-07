import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/themes/app_theme.dart';
import 'package:talk_trip/presentation/bloc/auth/auth_bloc.dart';
import 'package:talk_trip/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:talk_trip/core/database/database_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => FutureBuilder(
        future: DatabaseService.instance,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final isar = snapshot.data!;
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => AuthBloc(isar)),
                BlocProvider(create: (_) => ItineraryBloc(isar)),
              ],
              child: MaterialApp(
                builder: (context, widget) {
                  final mediaQueryData = MediaQuery.of(context);
                  final scaledMediaQueryData = mediaQueryData.copyWith(
                    textScaler: TextScaler.noScaling,
                  );
                  return MediaQuery(
                    data: scaledMediaQueryData,
                    child: widget!,
                  );
                },
                debugShowCheckedModeBanner: false,
                title: 'TalkTrip',
                initialRoute: RouteManager.initialRoute,
                onGenerateRoute: AppRouter.onGenerateRoute,
                theme: AppTheme.darkTheme,
              ),
            );
          }
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        },
      ),
    );
  }
}
