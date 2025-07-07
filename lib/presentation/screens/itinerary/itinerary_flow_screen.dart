import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'dart:convert';

class ItineraryFlowScreen extends StatefulWidget {
  final String prompt;
  const ItineraryFlowScreen({super.key, required this.prompt});

  @override
  State<ItineraryFlowScreen> createState() => _ItineraryFlowScreenState();
}

class _ItineraryFlowScreenState extends State<ItineraryFlowScreen> {
  bool _showChat = false;
  final TextEditingController _chatController = TextEditingController();
  List<String> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    context.read<ItineraryBloc>().add(CreateItinerary(prompt: widget.prompt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF065F46)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _showChat ? 'Refine Itinerary' : 'Creating Itinerary...',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Color(0xFF065F46),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: CircleAvatar(
              backgroundColor: Color(0xFF3BAB8C),
              child: Text('S', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ItineraryBloc, ItineraryState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is ItineraryLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60.w,
                      height: 60.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF065F46)),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text('Curating a perfect plan for you...',
                        style: TextStyle(
                            fontSize: 16.sp, color: Colors.grey[600])),
                  ],
                ),
              );
            } else if (state is ItineraryLoaded) {
              final itinerary = state.itinerary;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showChat) ...[
                      _ItineraryCard(
                        itinerary: itinerary,
                        onCopy: () {
                          Clipboard.setData(
                              ClipboardData(text: itinerary.title));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Copied to clipboard'),
                                backgroundColor: Color(0xFF065F46)),
                          );
                        },
                        onRegenerate: () {
                          context
                              .read<ItineraryBloc>()
                              .add(RegenerateItinerary(itinerary: itinerary));
                        },
                        onSaveOffline: () {
                          context
                              .read<ItineraryBloc>()
                              .add(SaveItinerary(itinerary: itinerary));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Itinerary saved offline!'),
                                backgroundColor: Color(0xFF065F46)),
                          );
                        },
                        onFollowUp: () {
                          setState(() => _showChat = true);
                        },
                      ),
                    ] else ...[
                      Expanded(
                        child: ListView(
                          children: [
                            _ItineraryCard(
                              itinerary: itinerary,
                              onCopy: () {},
                              onRegenerate: () {},
                              onSaveOffline: () {},
                              onFollowUp: null,
                            ),
                            ..._chatHistory.map((msg) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 8.h),
                                    padding: EdgeInsets.all(12.r),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(msg,
                                        style: TextStyle(fontSize: 15.sp)),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(12.r),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                decoration: InputDecoration(
                                  hintText: 'Ask to modify the itinerary...',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r)),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            ElevatedButton(
                              onPressed: () {
                                if (_chatController.text.trim().isNotEmpty) {
                                  final followUpText =
                                      _chatController.text.trim();
                                  setState(() {
                                    _chatHistory.add(followUpText);
                                    _chatController.clear();
                                  });

                                  // Dispatch FollowUpItinerary event
                                  if (state is ItineraryLoaded) {
                                    context.read<ItineraryBloc>().add(
                                          FollowUpItinerary(
                                            itinerary: state.itinerary,
                                            followUp: followUpText,
                                          ),
                                        );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF065F46),
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(12.r),
                              ),
                              child: Icon(Icons.send, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            } else if (state is ItineraryError) {
              return Center(
                  child:
                      Text(state.message, style: TextStyle(color: Colors.red)));
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  final Itinerary itinerary;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSaveOffline;
  final VoidCallback? onFollowUp;
  const _ItineraryCard({
    required this.itinerary,
    this.onCopy,
    this.onRegenerate,
    this.onSaveOffline,
    this.onFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Show process steps
    bool debugMode = true;
    String debugStep = '';
    List<dynamic> days = [];
    String? rawJson = itinerary.jsonData;
    String? extractedJson;
    if (rawJson != null && rawJson.isNotEmpty) {
      debugStep = 'JSON received';
      try {
        // Try to extract the first JSON object from the response
        int jsonStart = rawJson.indexOf('{');
        int jsonEnd = rawJson.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          extractedJson = rawJson.substring(jsonStart, jsonEnd);
        } else {
          extractedJson = rawJson;
        }
        final json = jsonDecode(extractedJson);
        debugStep = 'JSON parsed';
        if (json['days'] != null && json['days'] is List) {
          days = json['days'];
          debugStep = 'Days extracted';
        }
      } catch (e) {
        debugStep = 'JSON parse error';
      }
    }
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 24.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Itinerary Created ',
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46))),
                  Text('🏝️', style: TextStyle(fontSize: 18.sp)),
                ],
              ),
              SizedBox(height: 12.h),
              Text(itinerary.title,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
              SizedBox(height: 8.h),
              if (days.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var day in days)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(fontSize: 14.sp)),
                          Expanded(
                            child: Text(
                              'Day ${day['dayNumber']}: ${day['title'] ?? ''} - ${day['description'] ?? ''}',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ],
                      ),
                  ],
                )
              else
                Text('Day 1: Sample day breakdown...',
                    style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {}, // TODO: Open in maps
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              color: Color(0xFF2196F3), size: 18.sp),
                          SizedBox(width: 4.w),
                          Text('Open in maps',
                              style: TextStyle(
                                  color: Color(0xFF2196F3), fontSize: 13.sp)),
                        ],
                      ),
                    ),
                    Spacer(),
                    Flexible(
                      child: Text(
                        '${itinerary.destination} • ${itinerary.duration} days',
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  if (onFollowUp != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onFollowUp,
                        icon: Icon(Icons.tune, color: Colors.white),
                        label: Text('Follow up to refine',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2D7D32),
                          padding: EdgeInsets.symmetric(vertical: 16.r),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (onSaveOffline != null) SizedBox(width: 8.w),
                  if (onSaveOffline != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSaveOffline,
                        icon:
                            Icon(Icons.save_outlined, color: Color(0xFF065F46)),
                        label: Text('Save Offline',
                            style: TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.r),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          side: BorderSide(color: Color(0xFF065F46)),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Copy full itinerary JSON to clipboard
                      final json = itinerary.jsonData ?? '';
                      Clipboard.setData(ClipboardData(text: json));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Itinerary copied to clipboard!')),
                      );
                    },
                    icon:
                        Icon(Icons.copy, size: 16.sp, color: Colors.grey[600]),
                    label: Text('Copy',
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.grey[600])),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Regenerate itinerary
                      context
                          .read<ItineraryBloc>()
                          .add(RegenerateItinerary(itinerary: itinerary));
                    },
                    icon: Icon(Icons.refresh,
                        size: 16.sp, color: Colors.grey[600]),
                    label: Text('Regenerate',
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.grey[600])),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Save itinerary offline
                      context
                          .read<ItineraryBloc>()
                          .add(SaveItinerary(itinerary: itinerary));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Itinerary saved offline!')),
                      );
                    },
                    icon: Icon(Icons.save_outlined, color: Color(0xFF065F46)),
                    label: Text('Save Offline',
                        style: TextStyle(
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.r),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      side: BorderSide(color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (debugMode)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debugStep,
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  if (debugStep == 'JSON parse error' && rawJson != null)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      constraints: BoxConstraints(maxWidth: 200, maxHeight: 80),
                      child: SingleChildScrollView(
                        child: Text(
                          rawJson,
                          style: TextStyle(color: Colors.red, fontSize: 8),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
