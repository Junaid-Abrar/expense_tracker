import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/expense_model.dart';

enum TrendType {
  daily,
  weekly,
  monthly,
  yearly,
}

enum TrendIndicator {
  line,
  area,
  comparison,
}

class TrendChart extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final TrendType trendType;
  final TrendIndicator indicator;
  final double height;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String? title;
  final bool showComparison;
  final bool showAverage;
  final bool isInteractive;
  final EdgeInsetsGeometry? padding;

  const TrendChart({
    Key? key,
    required this.expenses,
    this.trendType = TrendType.daily,
    this.indicator = TrendIndicator.line,
    this.height = 250,
    this.primaryColor,
    this.secondaryColor,
    this.title,
    this.showComparison = false,
    this.showAverage = true,
    this.isInteractive = true,
    this.padding,
  }) : super(key: key);

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  Map<DateTime, double> _currentData = {};
  Map<DateTime, double> _comparisonData = {};
  double _maxValue = 0;
  double _minValue = 0;
  double _average = 0;
  int? _selectedPointIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _processData();
    _animationController.forward();
  }

  @override
  void didUpdateWidget(TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses ||
        oldWidget.trendType != widget.trendType) {
      _processData();
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _processData() {
    _currentData.clear();
    _comparisonData.clear();

    if (widget.expenses.isEmpty) {
      _maxValue = 100;
      _minValue = 0;
      _average = 0;
      return;
    }

    // Group expenses by time period
    final groupedExpenses = _groupExpensesByPeriod(widget.expenses);
    _currentData = groupedExpenses['current'] ?? {};

    if (widget.showComparison) {
      _comparisonData = groupedExpenses['comparison'] ?? {};
    }

    // Calculate statistics
    final allValues = [
      ..._currentData.values,
      if (widget.showComparison) ..._comparisonData.values,
    ];

    if (allValues.isNotEmpty) {
      _maxValue = allValues.reduce(math.max) * 1.1;
      _minValue = allValues.reduce(math.min);
      _average = allValues.reduce((a, b) => a + b) / allValues.length;
    } else {
      _maxValue = 100;
      _minValue = 0;
      _average = 0;
    }
  }

  Map<String, Map<DateTime, double>> _groupExpensesByPeriod(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final currentPeriodExpenses = <ExpenseModel>[];
    final comparisonPeriodExpenses = <ExpenseModel>[];

    // Determine periods based on trend type
    final periods = _getPeriodRanges(now);

    for (final expense in expenses) {
      if (_isInPeriod(expense.date, periods['current']!)) {
        currentPeriodExpenses.add(expense);
      } else if (widget.showComparison && _isInPeriod(expense.date, periods['comparison']!)) {
        comparisonPeriodExpenses.add(expense);
      }
    }

    return {
      'current': _groupExpensesByDate(currentPeriodExpenses),
      'comparison': _groupExpensesByDate(comparisonPeriodExpenses),
    };
  }

  Map<String, DateTimeRange> _getPeriodRanges(DateTime now) {
    switch (widget.trendType) {
      case TrendType.daily:
        return {
          'current': DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
          'comparison': DateTimeRange(
            start: now.subtract(const Duration(days: 60)),
            end: now.subtract(const Duration(days: 30)),
          ),
        };
      case TrendType.weekly:
        return {
          'current': DateTimeRange(
            start: now.subtract(const Duration(days: 84)), // 12 weeks
            end: now,
          ),
          'comparison': DateTimeRange(
            start: now.subtract(const Duration(days: 168)), // 24 weeks
            end: now.subtract(const Duration(days: 84)),
          ),
        };
      case TrendType.monthly:
        return {
          'current': DateTimeRange(
            start: DateTime(now.year - 1, now.month, 1),
            end: now,
          ),
          'comparison': DateTimeRange(
            start: DateTime(now.year - 2, now.month, 1),
            end: DateTime(now.year - 1, now.month, 1),
          ),
        };
      case TrendType.yearly:
        return {
          'current': DateTimeRange(
            start: DateTime(now.year - 5, 1, 1),
            end: now,
          ),
          'comparison': DateTimeRange(
            start: DateTime(now.year - 10, 1, 1),
            end: DateTime(now.year - 5, 1, 1),
          ),
        };
    }
  }

  bool _isInPeriod(DateTime date, DateTimeRange range) {
    return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
        date.isBefore(range.end.add(const Duration(days: 1)));
  }

  Map<DateTime, double> _groupExpensesByDate(List<ExpenseModel> expenses) {
    final grouped = <DateTime, double>{};

    for (final expense in expenses) {
      final key = _getDateKey(expense.date);
      grouped[key] = (grouped[key] ?? 0) + expense.amount;
    }

    // Fill missing dates with zero values
    if (grouped.isNotEmpty) {
      final sortedKeys = grouped.keys.toList()..sort();
      final start = sortedKeys.first;
      final end = sortedKeys.last;

      DateTime current = start;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        grouped[current] = grouped[current] ?? 0;
        current = _getNextDate(current);
      }
    }

    return grouped;
  }

  DateTime _getDateKey(DateTime date) {
    switch (widget.trendType) {
      case TrendType.daily:
        return DateTime(date.year, date.month, date.day);
      case TrendType.weekly:
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case TrendType.monthly:
        return DateTime(date.year, date.month, 1);
      case TrendType.yearly:
        return DateTime(date.year, 1, 1);
    }
  }

  DateTime _getNextDate(DateTime date) {
    switch (widget.trendType) {
      case TrendType.daily:
        return date.add(const Duration(days: 1));
      case TrendType.weekly:
        return date.add(const Duration(days: 7));
      case TrendType.monthly:
        return DateTime(date.year, date.month + 1, 1);
      case TrendType.yearly:
        return DateTime(date.year + 1, 1, 1);
    }
  }

  String _formatDate(DateTime date) {
    switch (widget.trendType) {
      case TrendType.daily:
        return '${date.day}/${date.month}';
      case TrendType.weekly:
        return 'W${_getWeekNumber(date)}';
      case TrendType.monthly:
        return '${_getMonthName(date.month).substring(0, 3)}';
      case TrendType.yearly:
        return '${date.year}';
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTrendIndicator(),
              ],
            ),
            const SizedBox(height: 8),
          ],

          _buildStatsRow(),
          const SizedBox(height: 16),

          Expanded(
            child: _currentData.isEmpty
                ? _buildEmptyChart()
                : _buildChart(),
          ),

          if (_selectedPointIndex != null && widget.isInteractive)
            _buildSelectedPointDetails(),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final currentTotal = _currentData.values.fold<double>(0, (sum, value) => sum + value);
    final comparisonTotal = widget.showComparison
        ? _comparisonData.values.fold<double>(0, (sum, value) => sum + value)
        : currentTotal;

    final percentageChange = comparisonTotal != 0
        ? ((currentTotal - comparisonTotal) / comparisonTotal) * 100
        : 0.0;

    final isPositive = percentageChange >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${percentageChange.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _currentData.values.fold<double>(0, (sum, value) => sum + value);
    final count = _currentData.values.where((value) => value > 0).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Total', CurrencyUtils.formatCurrency(total)),
        ),
        Expanded(
          child: _buildStatItem('Average', CurrencyUtils.formatCurrency(_average)),
        ),
        Expanded(
          child: _buildStatItem('Days with expenses', count.toString()),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(height: 8),
          Text(
            'No trend data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: widget.isInteractive ? _handleTapDown : null,
          child: CustomPaint(
            painter: TrendChartPainter(
              currentData: _currentData,
              comparisonData: _comparisonData,
              maxValue: _maxValue,
              minValue: _minValue,
              average: _average,
              primaryColor: widget.primaryColor ?? AppColors.primary,
              secondaryColor: widget.secondaryColor ?? AppColors.secondary,
              indicator: widget.indicator,
              showComparison: widget.showComparison,
              showAverage: widget.showAverage,
              selectedPointIndex: _selectedPointIndex,
              animation: _animation.value,
              formatDate: _formatDate,
              context: context,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSelectedPointDetails() {
    if (_selectedPointIndex == null) return const SizedBox.shrink();

    final sortedEntries = _currentData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (_selectedPointIndex! >= sortedEntries.length) return const SizedBox.shrink();

    final entry = sortedEntries[_selectedPointIndex!];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(entry.key),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  CurrencyUtils.formatCurrency(entry.value),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (widget.showComparison && _comparisonData.isNotEmpty) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previous Period',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatCurrency(_comparisonData[entry.key] ?? 0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.secondaryColor ?? AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    if (_currentData.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;

    // Calculate which point was tapped based on chart dimensions
    const padding = 40.0;
    final chartWidth = renderBox.size.width - (padding * 2);
    final sortedEntries = _currentData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) return;

    final pointWidth = chartWidth / sortedEntries.length;
    final tappedIndex = ((localPosition.dx - padding) / pointWidth).round();

    if (tappedIndex >= 0 && tappedIndex < sortedEntries.length) {
      setState(() {
        _selectedPointIndex = _selectedPointIndex == tappedIndex ? null : tappedIndex;
      });
    }
  }
}

class TrendChartPainter extends CustomPainter {
  final Map<DateTime, double> currentData;
  final Map<DateTime, double> comparisonData;
  final double maxValue;
  final double minValue;
  final double average;
  final Color primaryColor;
  final Color secondaryColor;
  final TrendIndicator indicator;
  final bool showComparison;
  final bool showAverage;
  final int? selectedPointIndex;
  final double animation;
  final String Function(DateTime) formatDate;
  final BuildContext context;

  TrendChartPainter({
    required this.currentData,
    required this.comparisonData,
    required this.maxValue,
    required this.minValue,
    required this.average,
    required this.primaryColor,
    required this.secondaryColor,
    required this.indicator,
    required this.showComparison,
    required this.showAverage,
    required this.selectedPointIndex,
    required this.animation,
    required this.formatDate,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentData.isEmpty) return;

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final comparisonPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Theme.of(context).dividerColor.withOpacity(0.3)
      ..strokeWidth = 1;

    final averagePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
      fontSize: 10,
    );

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = currentData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines
    for (int i = 0; i < sortedEntries.length; i += math.max(1, sortedEntries.length ~/ 6)) {
      final x = padding + (chartWidth * i / (sortedEntries.length - 1));
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, size.height - padding),
        gridPaint,
      );
    }

    // Draw average line
    if (showAverage && maxValue > 0) {
      final averageY = padding + chartHeight - (chartHeight * average / maxValue);
      canvas.drawLine(
        Offset(padding, averageY),
        Offset(size.width - padding, averageY),
        averagePaint,
      );

      // Average label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Avg: ${CurrencyUtils.formatCurrency(average)}',
          style: textStyle.copyWith(color: Colors.orange),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - padding - textPainter.width, averageY - 15));
    }

    // Draw comparison data (if enabled)
    if (showComparison && comparisonData.isNotEmpty) {
      _drawTrendLine(canvas, comparisonData, size, comparisonPaint, false);
    }

    // Draw current data
    switch (indicator) {
      case TrendIndicator.area:
        _drawAreaChart(canvas, currentData, size, paint, areaPaint);
        break;
      case TrendIndicator.line:
        _drawTrendLine(canvas, currentData, size, paint, true);
        break;
      case TrendIndicator.comparison:
        _drawComparisonBars(canvas, currentData, comparisonData, size);
        break;
    }

    // Draw labels
    _drawLabels(canvas, size, sortedEntries, textStyle);

    // Draw Y-axis values
    _drawYAxisLabels(canvas, size, textStyle);
  }

  void _drawTrendLine(Canvas canvas, Map<DateTime, double> data, Size size, Paint paint, bool drawPoints) {
    if (data.isEmpty) return;

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final x = padding + (chartWidth * i / (sortedEntries.length - 1));
      final y = padding + chartHeight - (chartHeight * entry.value / maxValue * animation);

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Use quadratic curves for smoother lines
        final prevPoint = points[i - 1];
        final controlPoint = Offset(
          (prevPoint.dx + x) / 2,
          prevPoint.dy,
        );
        path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    if (drawPoints) {
      final pointPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      final selectedPointPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        final isSelected = selectedPointIndex == i;

        if (isSelected) {
          // Draw larger circle for selected point
          canvas.drawCircle(point, 6, selectedPointPaint);
          canvas.drawCircle(point, 4, Paint()..color = Colors.white);
        } else {
          canvas.drawCircle(point, 4, pointPaint);
        }
      }
    }
  }

  void _drawAreaChart(Canvas canvas, Map<DateTime, double> data, Size size, Paint linePaint, Paint areaPaint) {
    if (data.isEmpty) return;

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final areaPath = Path();
    final linePath = Path();

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final x = padding + (chartWidth * i / (sortedEntries.length - 1));
      final y = padding + chartHeight - (chartHeight * entry.value / maxValue * animation);

      if (i == 0) {
        areaPath.moveTo(x, padding + chartHeight);
        areaPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        areaPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }

      if (i == sortedEntries.length - 1) {
        areaPath.lineTo(x, padding + chartHeight);
        areaPath.close();
      }
    }

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);
  }

  void _drawComparisonBars(Canvas canvas, Map<DateTime, double> currentData, Map<DateTime, double> comparisonData, Size size) {
    if (currentData.isEmpty) return;

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = currentData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final barWidth = (chartWidth / sortedEntries.length) * 0.6;
    final currentBarPaint = Paint()..color = primaryColor;
    final comparisonBarPaint = Paint()..color = secondaryColor;

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final x = padding + (chartWidth * (i + 0.5) / sortedEntries.length);

      // Current period bar
      final currentHeight = (chartHeight * entry.value / maxValue) * animation;
      final currentY = padding + chartHeight - currentHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - barWidth / 4, currentY, barWidth / 2, currentHeight),
          const Radius.circular(2),
        ),
        currentBarPaint,
      );

      // Comparison period bar (if data exists)
      final comparisonValue = comparisonData[entry.key] ?? 0;
      if (comparisonValue > 0) {
        final comparisonHeight = (chartHeight * comparisonValue / maxValue) * animation;
        final comparisonY = padding + chartHeight - comparisonHeight;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + barWidth / 4, comparisonY, barWidth / 2, comparisonHeight),
            const Radius.circular(2),
          ),
          comparisonBarPaint,
        );
      }
    }
  }

  void _drawLabels(Canvas canvas, Size size, List<MapEntry<DateTime, double>> sortedEntries, TextStyle textStyle) {
    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);

    for (int i = 0; i < sortedEntries.length; i += math.max(1, sortedEntries.length ~/ 6)) {
      final entry = sortedEntries[i];
      final x = padding + (chartWidth * i / (sortedEntries.length - 1));

      final textPainter = TextPainter(
        text: TextSpan(text: formatDate(entry.key), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 20));
    }
  }

  void _drawYAxisLabels(Canvas canvas, Size size, TextStyle textStyle) {
    const padding = 40.0;
    final chartHeight = size.height - (padding * 2);

    for (int i = 0; i <= 4; i++) {
      final value = maxValue * i / 4;
      final y = padding + (chartHeight * (4 - i) / 4);

      final textPainter = TextPainter(
        text: TextSpan(text: CurrencyUtils.formatCurrency(value), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}