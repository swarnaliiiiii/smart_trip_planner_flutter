import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThinkingBubbleWidget extends StatefulWidget {
  const ThinkingBubbleWidget({super.key});

  @override
  State<ThinkingBubbleWidget> createState() => _ThinkingBubbleWidgetState();
}

class _ThinkingBubbleWidgetState extends State<ThinkingBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: Color(0xFF065F46),
            child: Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0),
                    SizedBox(width: 4.w),
                    _buildDot(1),
                    SizedBox(width: 4.w),
                    _buildDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final animationValue = (_animation.value - delay).clamp(0.0, 1.0);
    final opacity = (animationValue * 2).clamp(0.0, 1.0);
    
    return Container(
      width: 8.w,
      height: 8.h,
      decoration: BoxDecoration(
        color: Color(0xFF065F46).withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}