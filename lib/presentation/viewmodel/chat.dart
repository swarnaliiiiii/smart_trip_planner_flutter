import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Row(
          children: [
            Text(
              'Hey User',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            )
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 20.h,
            ),
            Text(
              'What\'s your vision\n     for this trip?',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(
              height: 30.h,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Color(0xFF3BAB8C), width: 2.r),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black,
                      height: 3.h,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 12.r, horizontal: 9.r),
                      border: InputBorder.none,
                      hintText: 'Describe your ideal trip...',
                    ),
                  ),
                  Positioned(
                    bottom: 8.h,
                    right: 8.w,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Color(0xFF065F46),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle create itinerary
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2D7D32),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.r),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create My Itinerary',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
