import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/data/models/user.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'package:talk_trip/presentation/bloc/itinerary/itinerary_bloc.dart';
import 'package:talk_trip/presentation/screens/itinerary/itinerary_flow_screen.dart';
import 'package:talk_trip/core/utils/metrics_manager.dart';
import 'package:talk_trip/presentation/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  List<Itinerary> _savedItineraries = [];
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadItineraries();
    _createDefaultUserIfNeeded();
  }

  Future<void> _loadUser() async {
    final isar = Isar.getInstance();
    final users = await isar?.users.where().findAll();
    if (users != null && users.isNotEmpty) {
      setState(() {
        _user = users.first;
      });
    }
  }

  Future<void> _loadItineraries() async {
    final isar = Isar.getInstance();
    final itineraries = await isar?.itinerarys.where().findAll();
    setState(() {
      _savedItineraries = itineraries ?? [];
    });
  }

  Future<void> _createDefaultUserIfNeeded() async {
    final isar = Isar.getInstance();
    final users = await isar?.users.where().findAll();
    if (users == null || users.isEmpty) {
      // Create a default user
      final defaultUser = User()
        ..name = 'Traveler'
        ..email = 'traveler@example.com'
        ..password = 'password';

      await isar?.writeTxn(() async => await isar?.users.put(defaultUser));
      setState(() {
        _user = defaultUser;
      });
    }
  }

  void _onCreateItinerary() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Dispatch Bloc event to create itinerary
    context.read<ItineraryBloc>().add(CreateItinerary(prompt: text));

    // Navigate to itinerary flow screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItineraryFlowScreen(prompt: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hey ${_user?.name ?? ''} 👋',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: Color(0xFF065F46),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: CircleAvatar(
                backgroundColor: Color(0xFF3BAB8C),
                child: Text(
                  _user != null && _user!.name.isNotEmpty
                      ? _user!.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  Center(
                    child: Text(
                      "What's your vision for this trip?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Color(0xFF3BAB8C), width: 2.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  '7 days in Bali next April, 3 people, mid-range budget, wanted to explore less populated areas, it should be a peaceful trip!',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                            ),
                            onSubmitted: (_) => _onCreateItinerary(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.mic, color: Color(0xFF3BAB8C)),
                          onPressed: () {
                            // TODO: Implement proper speech recognition
                            // For now, show a dialog to simulate voice input
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Voice Input'),
                                content: Text(
                                    'Voice input will be implemented with speech recognition. For now, you can type your request.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onCreateItinerary,
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
                  SizedBox(height: 32.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F8FA),
                      border: Border.all(color: Color(0xFF2196F3), width: 1.5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                    child: _savedItineraries.isEmpty
                        ? Center(
                            child: Text('No saved itineraries yet.',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14.sp)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Saved Itineraries',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              ..._savedItineraries.map((itinerary) => Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    child: GestureDetector(
                                      onTap: () {
                                        // TODO: Open itinerary in chat/modify mode
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(16.r),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 8.w,
                                              height: 40.h,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF065F46),
                                                borderRadius:
                                                    BorderRadius.circular(4.r),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    itinerary.title,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    '${itinerary.destination} • ${itinerary.duration} days',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16.sp,
                                              color: Colors.grey[400],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Debug Metrics Overlay
          if (MetricsManager().isDebugMode)
            Positioned(
              top: 100.h,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Total: ${MetricsManager().totalTokens}',
                      style: TextStyle(color: Colors.white, fontSize: 10.sp),
                    ),
                    Text(
                      'Cost: \$${MetricsManager().totalCost.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.white, fontSize: 10.sp),
                    ),
                    if (MetricsManager().lastMetric != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Last: ${MetricsManager().lastMetric!.requestType}',
                        style:
                            TextStyle(color: Colors.grey[300], fontSize: 9.sp),
                      ),
                      Text(
                        'I/O: ${MetricsManager().lastMetric!.inputTokens}/${MetricsManager().lastMetric!.outputTokens}',
                        style:
                            TextStyle(color: Colors.grey[300], fontSize: 9.sp),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
