import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

class ItineraryFlowScreen extends StatefulWidget {
  final String prompt;
  final Itinerary? initialItinerary;
  const ItineraryFlowScreen(
      {super.key, required this.prompt, this.initialItinerary});

  @override
  State<ItineraryFlowScreen> createState() => _ItineraryFlowScreenState();
}

class _ItineraryFlowScreenState extends State<ItineraryFlowScreen> {
  bool _showChat = false;
  final TextEditingController _chatController = TextEditingController();
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isThinking = false;
  Itinerary? _currentItinerary;
  late final String _initialPrompt;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';

  @override
  void initState() {
    super.initState();
    _initialPrompt = widget.prompt;
    _speech = stt.SpeechToText();
    if (widget.initialItinerary != null) {
      _currentItinerary = widget.initialItinerary;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _chatHistory.add({
            'type': 'ai',
            'itinerary': _currentItinerary,
          });
          _showChat = true;
        });
        context
            .read<ItineraryBloc>()
            .emit(ItineraryLoaded(widget.initialItinerary!));
      });
    } else {
      context.read<ItineraryBloc>().add(CreateItinerary(prompt: widget.prompt));
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _voiceInput = val.recognizedWords;
              _chatController.text = _voiceInput;
            });
          },
          listenFor: Duration(seconds: 10),
          pauseFor: Duration(seconds: 3),
          localeId: 'en_US',
          cancelOnError: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF065F46)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _initialPrompt,
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
          listener: (context, state) {
            if (state is ItineraryLoading) {
              setState(() {
                _isThinking = true;
              });
            } else if (state is ItineraryLoaded) {
              setState(() {
                _isThinking = false;
                _currentItinerary = state.itinerary;
                _chatHistory.add({
                  'type': 'ai',
                  'itinerary': state.itinerary,
                });
                _showChat = true;
              });
            }
          },
          builder: (context, state) {
            if (state is ItineraryError) {
              return Center(
                  child:
                      Text(state.message, style: TextStyle(color: Colors.red)));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    itemCount: _chatHistory.length + (_isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isThinking && index == _chatHistory.length) {
                        return _AIMessageCard(message: 'Thinking...');
                      }
                      final msg = _chatHistory[index];
                      if (msg['type'] == 'user') {
                        return _UserMessageCard(message: msg['text']);
                      } else if (msg['type'] == 'ai') {
                        final itinerary = msg['itinerary'] as Itinerary?;
                        if (itinerary != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AIMessageCard(
                                message: _formatItineraryMessage(itinerary),
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
                                  context.read<ItineraryBloc>().add(
                                      RegenerateItinerary(
                                          itinerary: itinerary));
                                },
                                onSaveOffline: () {
                                  context
                                      .read<ItineraryBloc>()
                                      .add(SaveItinerary(itinerary: itinerary));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Itinerary saved offline!'),
                                        backgroundColor: Color(0xFF065F46)),
                                  );
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 16.w, top: 4.h, bottom: 8.h),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.r),
                                    onTap: () async {
                                      print(
                                          'DEBUG: Open in maps button pressed for itinerary: \'${itinerary.destination}\'');
                                      String? mapsUrl;
                                      String? mapLink;
                                      if (itinerary.days.isNotEmpty) {
                                        final firstDay = itinerary.days.first;
                                        if (firstDay.activities.isNotEmpty) {
                                          final activity =
                                              firstDay.activities.first;
                                          if (activity.mapLink != null &&
                                              activity.mapLink!.contains(
                                                  'maps.google.com')) {
                                            mapLink = activity.mapLink;
                                          }
                                        }
                                        if (mapLink == null &&
                                            firstDay.restaurants.isNotEmpty) {
                                          final restaurant =
                                              firstDay.restaurants.first;
                                          if (restaurant.mapLink != null &&
                                              restaurant.mapLink!.contains(
                                                  'maps.google.com')) {
                                            mapLink = restaurant.mapLink;
                                          }
                                        }
                                      }
                                      if (mapLink != null) {
                                        final coordReg = RegExp(
                                            r'@(-?\\d+\\.\\d+),(-?\\d+\\.\\d+)');
                                        final match =
                                            coordReg.firstMatch(mapLink!);
                                        if (match != null) {
                                          final lat = match.group(1);
                                          final lng = match.group(2);
                                          mapsUrl =
                                              'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                        } else {
                                          mapsUrl = mapLink;
                                        }
                                      } else {
                                        mapsUrl =
                                            'https://www.google.com/maps/search/?api=1&query=' +
                                                Uri.encodeComponent(
                                                    itinerary.destination);
                                      }
                                      // Try geo: URI first
                                      final geoUrl = Uri.parse('geo:0,0?q=' +
                                          Uri.encodeComponent(
                                              itinerary.destination));
                                      print(
                                          'DEBUG: Attempting to launch geo URI: $geoUrl');
                                      if (await canLaunchUrl(geoUrl)) {
                                        await launchUrl(geoUrl,
                                            mode:
                                                LaunchMode.externalApplication);
                                        print(
                                            'DEBUG: geo: URI launched successfully.');
                                      } else {
                                        // Fallback to browser
                                        final webUrl = Uri.parse(mapsUrl!);
                                        print(
                                            'DEBUG: geo: URI failed, attempting browser URL: $webUrl');
                                        if (await canLaunchUrl(webUrl)) {
                                          await launchUrl(webUrl,
                                              mode: LaunchMode
                                                  .externalApplication);
                                          print(
                                              'DEBUG: Maps URL launched in browser.');
                                        } else {
                                          print(
                                              'DEBUG: Could not launch maps in browser or app.');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Could not open maps.')),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            Color(0xFF2196F3).withOpacity(0.18),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        border: Border.all(
                                            color: Color(0xFF2196F3),
                                            width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF2196F3)
                                                .withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 8.h),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Color(0xFF2196F3),
                                              size: 20.sp),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Open in maps',
                                            style: TextStyle(
                                              color: Color(0xFF2196F3),
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return _AIMessageCard(message: msg['text'] ?? '');
                        }
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                      left: 12.w, right: 8.w, bottom: 12.h, top: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                                color: Color(0xFF3BAB8C), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: _isListening
                                      ? [
                                          BoxShadow(
                                            color: Color(0xFF3BAB8C)
                                                .withOpacity(0.6),
                                            blurRadius: 16,
                                            spreadRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic_off : Icons.mic,
                                    color: Color(0xFF3BAB8C),
                                  ),
                                  onPressed: _listen,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  decoration: InputDecoration(
                                    hintText: 'Follow up to refine',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8.w, vertical: 12.h),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon:
                                    Icon(Icons.send, color: Color(0xFF2D7D32)),
                                onPressed: () {
                                  if (_chatController.text.trim().isNotEmpty &&
                                      _currentItinerary != null) {
                                    final followUpText =
                                        _chatController.text.trim();
                                    setState(() {
                                      _chatHistory.add({
                                        'type': 'user',
                                        'text': followUpText
                                      });
                                      _chatController.clear();
                                    });
                                    context.read<ItineraryBloc>().add(
                                          FollowUpItinerary(
                                            itinerary: _currentItinerary!,
                                            followUp: followUpText,
                                          ),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatItineraryMessage(Itinerary itinerary) {
    // Parse the itinerary JSON and display all days in a structured format
    StringBuffer buffer = StringBuffer();
    String? rawJson = itinerary.jsonData;
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        int jsonStart = rawJson.indexOf('{');
        int jsonEnd = rawJson.lastIndexOf('}') + 1;
        String extractedJson = (jsonStart != -1 && jsonEnd > jsonStart)
            ? rawJson.substring(jsonStart, jsonEnd)
            : rawJson;
        final json = jsonDecode(extractedJson);
        if (json['days'] != null && json['days'] is List) {
          for (var day in json['days']) {
            buffer.writeln('Day ${day['dayNumber']}: ${day['title'] ?? ''}');
            if (day['description'] != null &&
                day['description'].toString().isNotEmpty) {
              buffer.writeln('  Description: ${day['description']}');
            }
            // Activities
            if (day['activities'] != null &&
                day['activities'] is List &&
                day['activities'].isNotEmpty) {
              buffer.writeln('  Activities:');
              for (var activity in day['activities']) {
                buffer.writeln(
                    '    • 🏛️ ${activity['name'] ?? activity['title'] ?? ''} — ${activity['type'] ?? ''}');
                if (activity['description'] != null &&
                    activity['description'].toString().isNotEmpty) {
                  buffer.writeln(
                      '      - Description: ${activity['description']}');
                }
                if (activity['location'] != null &&
                    activity['location'].toString().isNotEmpty) {
                  buffer.writeln('      - Location: ${activity['location']}');
                }
                if (activity['mapLink'] != null &&
                    activity['mapLink'].toString().isNotEmpty) {
                  buffer.writeln('      - Map: ${activity['mapLink']}');
                }
                if (activity['timeSlot'] != null &&
                    activity['timeSlot'].toString().isNotEmpty) {
                  buffer.writeln('      - Time: ${activity['timeSlot']}');
                }
                if (activity['estimatedCost'] != null) {
                  buffer
                      .writeln('      - Cost: 24${activity['estimatedCost']}');
                }
                if (activity['rating'] != null) {
                  buffer.writeln('      - Rating: ⭐ ${activity['rating']}');
                }
              }
            }
            // Restaurants
            if (day['restaurants'] != null &&
                day['restaurants'] is List &&
                day['restaurants'].isNotEmpty) {
              buffer.writeln('  Restaurants:');
              for (var restaurant in day['restaurants']) {
                buffer.writeln(
                    '    • 🍽️ ${restaurant['name'] ?? ''} — ${restaurant['cuisine'] ?? ''}');
                if (restaurant['description'] != null &&
                    restaurant['description'].toString().isNotEmpty) {
                  buffer.writeln(
                      '      - Description: ${restaurant['description']}');
                }
                if (restaurant['location'] != null &&
                    restaurant['location'].toString().isNotEmpty) {
                  buffer.writeln('      - Location: ${restaurant['location']}');
                }
                if (restaurant['mapLink'] != null &&
                    restaurant['mapLink'].toString().isNotEmpty) {
                  buffer.writeln('      - Map: ${restaurant['mapLink']}');
                }
                if (restaurant['priceRange'] != null &&
                    restaurant['priceRange'].toString().isNotEmpty) {
                  buffer.writeln('      - Price: ${restaurant['priceRange']}');
                }
                if (restaurant['rating'] != null) {
                  buffer.writeln('      - Rating: ⭐ ${restaurant['rating']}');
                }
              }
            }
            buffer.writeln('');
            buffer
                .writeln('--------------------------------------------------');
            buffer.writeln('');
          }
        } else {
          buffer.writeln('No days found in itinerary.');
        }
      } catch (e) {
        buffer.writeln('Error parsing itinerary days.');
      }
    } else {
      buffer.writeln('No itinerary data found.');
    }
    return buffer.toString();
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
    bool debugMode = kDebugMode;
    String debugStep = '';
    List<dynamic> days = [];
    String? rawJson = itinerary.jsonData;
    String? extractedJson;
    if (rawJson != null && rawJson.isNotEmpty) {
      debugStep = 'JSON received';
      try {
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
                color: Colors.white.withOpacity(0.05),
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
              else ...[
                Text('No days found in itinerary.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.red)),
                if (debugMode && rawJson != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Raw JSON: $rawJson',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
              ],
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () async {
                          String? mapsUrl;
                          // Try to extract coordinates from the first activity or restaurant with a mapLink
                          String? mapLink;
                          if (itinerary.days.isNotEmpty) {
                            final firstDay = itinerary.days.first;
                            if (firstDay.activities.isNotEmpty) {
                              final activity = firstDay.activities.first;
                              if (activity.mapLink != null &&
                                  activity.mapLink!
                                      .contains('maps.google.com')) {
                                mapLink = activity.mapLink;
                              }
                            }
                            if (mapLink == null &&
                                firstDay.restaurants.isNotEmpty) {
                              final restaurant = firstDay.restaurants.first;
                              if (restaurant.mapLink != null &&
                                  restaurant.mapLink!
                                      .contains('maps.google.com')) {
                                mapLink = restaurant.mapLink;
                              }
                            }
                          }
                          if (mapLink != null) {
                            // Try to extract coordinates from the mapLink
                            final coordReg =
                                RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
                            final match = coordReg.firstMatch(mapLink!);
                            if (match != null) {
                              final lat = match.group(1);
                              final lng = match.group(2);
                              mapsUrl =
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                            } else {
                              mapsUrl = mapLink;
                            }
                          } else {
                            // Fallback: search by destination name
                            mapsUrl =
                                'https://www.google.com/maps/search/?api=1&query=' +
                                    Uri.encodeComponent(itinerary.destination);
                          }
                          final url = Uri.parse(mapsUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open maps.')),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                                color: Color(0xFF2196F3), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2196F3).withOpacity(0.08),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on,
                                  color: Color(0xFF2196F3), size: 20.sp),
                              SizedBox(width: 6.w),
                              Text(
                                'Open in maps',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
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
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                debugStep,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserMessageCard extends StatelessWidget {
  final String message;
  const _UserMessageCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: 15.sp, color: Colors.black87),
        ),
      ),
    );
  }
}

class _AIMessageCard extends StatelessWidget {
  final String message;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSaveOffline;
  const _AIMessageCard({
    required this.message,
    this.onCopy,
    this.onRegenerate,
    this.onSaveOffline,
  });
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFF8E1),
                  child: Icon(Icons.android, color: Color(0xFFFFC107)),
                  radius: 16.r,
                ),
                SizedBox(width: 8.w),
                Text('Itinera AI',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(message, style: TextStyle(fontSize: 15.sp)),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (onCopy != null)
                  IconButton(
                    icon:
                        Icon(Icons.copy, size: 18.sp, color: Colors.grey[600]),
                    onPressed: onCopy,
                  ),
                if (onSaveOffline != null)
                  IconButton(
                    icon: Icon(Icons.save_outlined,
                        size: 18.sp, color: Color(0xFF065F46)),
                    onPressed: onSaveOffline,
                  ),
                if (onRegenerate != null)
                  IconButton(
                    icon: Icon(Icons.refresh,
                        size: 18.sp, color: Colors.grey[600]),
                    onPressed: onRegenerate,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
