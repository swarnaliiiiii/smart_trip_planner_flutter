import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/presentation/bloc/chat/chat_bloc.dart';
import 'package:talk_trip/presentation/viewmodel/chat.dart';
import 'package:talk_trip/data/sources/api/gen_ai_service.dart';
import 'package:talk_trip/data/repo/message_repo.dart';
import 'package:talk_trip/core/database/database_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
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
        debugShowCheckedModeBanner: false,
        title: 'TalkTrip',
        home: FutureBuilder(
          future: DatabaseService.instance,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return BlocProvider(
                create: (context) => ChatBloc(
                  GenerativeAIWebService(),
                  MessageRepository(snapshot.data!),
                ),
                child: ChatScreen(),
              );
            }
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }
}