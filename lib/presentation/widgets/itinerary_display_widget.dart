import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/data/models/itinerary.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraryDisplayWidget extends StatelessWidget {
  final Itinerary itinerary;

  const ItineraryDisplayWidget({
    super.key,
    required this.itinerary,
  });

  Future<void> _openInMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url = 'https://maps.google.com/?q=$encodedLocation';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Color(0xFF2196F3), width: 2.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Fixed height
          Container(
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Color(0xFF065F46),
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        itinerary.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  itinerary.destination,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10.h),
                // Fixed: Wrap Row in Flexible to prevent horizontal overflow
                Row(
                  children: [
                    Flexible(
                      child: _buildInfoChip(
                        icon: Icons.calendar_today,
                        text: '${itinerary.duration} days',
                      ),
                    ),
                    SizedBox(width: 8.w), // Increased spacing
                    Flexible(
                      child: _buildInfoChip(
                        icon: Icons.attach_money,
                        text: itinerary.budget,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Open in Maps button - Fixed height
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: GestureDetector(
              onTap: () => _openInMaps(itinerary.destination),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.r, horizontal: 12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Color(0xFF2196F3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 16.sp,
                      color: Color(0xFF2196F3),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Open in maps',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Days list - Fixed: Use Expanded instead of fixed height
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: ListView.builder(
                itemCount: itinerary.days.length,
                itemBuilder: (context, index) {
                  final day = itinerary.days.elementAt(index);
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${day.dayNumber}: ${day.title}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        if (day.description != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            day.description!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        SizedBox(height: 12.h),

                        // Activities
                        ...day.activities
                            .map((activity) => Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6.w,
                                        height: 6.h,
                                        margin:
                                            EdgeInsets.only(top: 6.h, right: 8.w),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF065F46),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    activity.name,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                if (activity.location != null)
                                                  GestureDetector(
                                                    onTap: () => _openInMaps(
                                                        activity.location!),
                                                    child: Icon(
                                                      Icons.map_outlined,
                                                      size: 16.sp,
                                                      color: Color(0xFF2196F3),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (activity.description != null) ...[
                                              SizedBox(height: 4.h),
                                              Text(
                                                activity.description!,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                            if (activity.timeSlot != null) ...[
                                              SizedBox(height: 4.h),
                                              Text(
                                                activity.timeSlot!,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Color(0xFF065F46),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),

                        // Restaurants
                        if (day.restaurants.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            'Dining:',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ...day.restaurants
                              .map((restaurant) => Container(
                                    margin: EdgeInsets.only(bottom: 4.h),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.restaurant,
                                          size: 14.sp,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            '${restaurant.name} (${restaurant.cuisine})',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        if (restaurant.location != null)
                                          GestureDetector(
                                            onTap: () =>
                                                _openInMaps(restaurant.location!),
                                            child: Icon(
                                              Icons.map_outlined,
                                              size: 14.sp,
                                              color: Color(0xFF2196F3),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}