import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'itinerary_flow_screen.dart';
import 'dart:convert';

class ItineraryDisplayScreen extends StatelessWidget {
  final String prompt;
  const ItineraryDisplayScreen({Key? key, required this.prompt})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Creating Itinerary...',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF065F46),
            )),
      ),
      body: SafeArea(
        child: BlocConsumer<ItineraryBloc, ItineraryState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is ItineraryLoading || state is ItineraryInitial) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2D7D32)),
                    SizedBox(height: 24.h),
                    Text('Curating a perfect plan for you...',
                        style:
                            TextStyle(fontSize: 16.sp, color: Colors.grey[700]))
                  ],
                ),
              );
            } else if (state is ItineraryLoaded) {
              final itinerary = state.itinerary;
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: SingleChildScrollView(
                            child: Text(
                              _formatItineraryMessage(itinerary),
                              style: TextStyle(
                                  fontSize: 15.sp, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ItineraryFlowScreen(
                              prompt: prompt,
                              initialItinerary: itinerary,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.tune, color: Colors.white),
                      label: Text('Follow up to refine',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2D7D32),
                        padding: EdgeInsets.symmetric(vertical: 16.r),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () {
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
              );
            } else if (state is ItineraryError) {
              return Center(
                child: Text(state.message, style: TextStyle(color: Colors.red)),
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _formatItineraryMessage(Itinerary itinerary) {
    // Use the same improved formatting as in ItineraryFlowScreen
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
                      .writeln('      - Cost:  24${activity['estimatedCost']}');
                }
                if (activity['rating'] != null) {
                  buffer.writeln('      - Rating: ⭐ ${activity['rating']}');
                }
              }
            }
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
    buffer.writeln(
        '[Open in maps] ${itinerary.title} | ${itinerary.destination} | ${itinerary.duration} days');
    return buffer.toString();
  }
}
