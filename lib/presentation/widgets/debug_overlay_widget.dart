import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:talk_trip/core/utils/metrics_manager.dart';

class DebugOverlayWidget extends StatefulWidget {
  final Widget child;

  const DebugOverlayWidget({
    super.key,
    required this.child,
  });

  @override
  State<DebugOverlayWidget> createState() => _DebugOverlayWidgetState();
}

class _DebugOverlayWidgetState extends State<DebugOverlayWidget> {
  bool _showOverlay = false;
  final MetricsManager _metricsManager = MetricsManager();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Debug toggle button
        Positioned(
          top: 100.h,
          right: 16.w,
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _showOverlay = !_showOverlay;
                _metricsManager.setDebugMode(_showOverlay);
              });
            },
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: _showOverlay ? Colors.red : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bug_report,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ),

        // Debug overlay
        if (_showOverlay)
          Positioned(
            top: 150.h,
            right: 16.w,
            child: Container(
              width: 280.w,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Debug Metrics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showOverlay = false;
                            _metricsManager.setDebugMode(false);
                          });
                        },
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  
                  _buildMetricRow('Total Tokens:', '${_metricsManager.totalTokens}'),
                  _buildMetricRow('Total Cost:', '\$${_metricsManager.totalCost.toStringAsFixed(4)}'),
                  
                  if (_metricsManager.lastMetric != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Last Request:',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildMetricRow('Input:', '${_metricsManager.lastMetric!.inputTokens}'),
                    _buildMetricRow('Output:', '${_metricsManager.lastMetric!.outputTokens}'),
                    _buildMetricRow('Cost:', '\$${_metricsManager.lastMetric!.estimatedCost.toStringAsFixed(4)}'),
                    _buildMetricRow('Type:', _metricsManager.lastMetric!.requestType),
                  ],
                  
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () {
                      _metricsManager.clearMetrics();
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Clear Metrics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
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

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 10.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}