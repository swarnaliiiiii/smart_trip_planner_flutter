import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/data/models/message.dart';

class ChatMessageWidget extends StatelessWidget {
  final Message message;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final bool isLastMessage;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onCopy,
    this.onRegenerate,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: const Color(0xFF065F46),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF065F46)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                SizedBox(width: 8.w),
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: const Color(0xFF3BAB8C),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ],
            ],
          ),
          if (!message.isUser) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(left: 40.w),
              child: Wrap(
                spacing: 8.w,
                children: [
                  // Copy button
                  InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_outlined,
                            size: 16.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Regenerate button (only for last AI message)
                  if (isLastMessage) ...[
                    InkWell(
                      onTap: onRegenerate,
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_outlined,
                              size: 16.sp,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Regenerate',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}