import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/core/utils/diff_utils.dart';

class DiffHighlightWidget extends StatelessWidget {
  final ItineraryDiff diff;

  const DiffHighlightWidget({
    super.key,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    if (!diff.hasChanges) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.update,
                color: Colors.blue[600],
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Itinerary Updated',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // Changed fields
          ...diff.changedFields.entries.map((entry) => 
            _buildChangeItem(entry.value, Colors.orange, Icons.edit)
          ),
          
          // Added activities
          ...diff.addedActivities.map((activity) => 
            _buildChangeItem('Added activity: $activity', Colors.green, Icons.add)
          ),
          
          // Removed activities
          ...diff.removedActivities.map((activity) => 
            _buildChangeItem('Removed activity: $activity', Colors.red, Icons.remove)
          ),
          
          // Added restaurants
          ...diff.addedRestaurants.map((restaurant) => 
            _buildChangeItem('Added restaurant: $restaurant', Colors.green, Icons.restaurant)
          ),
          
          // Removed restaurants
          ...diff.removedRestaurants.map((restaurant) => 
            _buildChangeItem('Removed restaurant: $restaurant', Colors.red, Icons.restaurant)
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(String text, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.sp,
                color: color[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}