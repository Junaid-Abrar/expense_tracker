import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/expense_model.dart';

enum ChartType {
  line,
  bar,
  area,
}

enum ChartPeriod {
  week,
  month,
  quarter,
  year,
}

class ExpenseChart extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final ChartType type;
  final ChartPeriod period;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double height;
  final bool showGrid;
  final bool showLabels;
  final bool showValues;
  final String? title;
  final EdgeInsetsGeometry? padding;

  const ExpenseChart({
    Key? key,
    required this.expenses,
    this.type = ChartType.line,
    this.period = ChartPeriod.month,
    this.primaryColor,
    this.secondaryColor,
    this.height = 200,
    this.showGrid = true,
    this.showLabels = true,
    this.showValues = false,
    this.title,
    this.padding,
  }) : super(key: key);

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  Map<DateTime, double> _chartData = {};
  double _maxValue = 0;

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
  void didUpdateWidget(ExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses ||
        oldWidget.period != widget.period) {
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
    _chartData.clear();

    if (widget.expenses.isEmpty) {
      _maxValue = 0;
      return;
    }

    // Group expenses by date based on period
    final Map<DateTime, double> groupedData = {};

    for (final expense in widget.expenses) {
      final DateTime key = _getDateKey(expense.date);
      groupedData[key] = (groupedData[key] ?? 0) + expense.amount;
    }

    // Fill missing dates with zero values
    final sortedKeys = groupedData.keys.toList()..sort();
    if (sortedKeys.isNotEmpty) {
      final DateTime startDate = sortedKeys.first;
      final DateTime endDate = sortedKeys.last;

      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        _chartData[currentDate] = groupedData[currentDate] ?? 0;
        currentDate = _getNextDate(currentDate);
      }
    }

    _maxValue = _chartData.values.isNotEmpty
        ? _chartData.values.reduce((a, b) => a > b ? a : b) * 1.1
        : 0;
  }

  DateTime _getDateKey(DateTime date) {
    switch (widget.period) {
      case ChartPeriod.week:
        return DateTime(date.year, date.month, date.day);
      case ChartPeriod.month:
        return DateTime(date.year, date.month, date.day);
      case ChartPeriod.quarter:
        return DateTime(date.year, date.month, 1);
      case ChartPeriod.year:
        return DateTime(date.year, date.month, 1);
    }
  }

  DateTime _getNextDate(DateTime date) {
    switch (widget.period) {
      case ChartPeriod.week:
      case ChartPeriod.month:
        return DateTime(date.year, date.month, date.day + 1);
      case ChartPeriod.quarter:
      case ChartPeriod.year:
        return DateTime(date.year, date.month + 1, 1);
    }
  }

  String _formatDate(DateTime date) {
    switch (widget.period) {
      case ChartPeriod.week:
        return '${date.day}';
      case ChartPeriod.month:
        return '${date.day}';
      case ChartPeriod.quarter:
        return '${_getMonthName(date.month)}';
      case ChartPeriod.year:
        return '${_getMonthName(date.month).substring(0, 3)}';
    }
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
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _chartData.isEmpty
                ? _buildEmptyChart()
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(height: 8),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    switch (widget.type) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.area:
        return _buildAreaChart();
    }
  }

  Widget _buildLineChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: LineChartPainter(
            data: _chartData,
            maxValue: _maxValue,
            color: widget.primaryColor ?? AppColors.primary,
            showGrid: widget.showGrid,
            showLabels: widget.showLabels,
            showValues: widget.showValues,
            animation: _animation.value,
            formatDate: _formatDate,
            context: context,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildBarChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: BarChartPainter(
            data: _chartData,
            maxValue: _maxValue,
            color: widget.primaryColor ?? AppColors.primary,
            showGrid: widget.showGrid,
            showLabels: widget.showLabels,
            showValues: widget.showValues,
            animation: _animation.value,
            formatDate: _formatDate,
            context: context,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAreaChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: AreaChartPainter(
            data: _chartData,
            maxValue: _maxValue,
            color: widget.primaryColor ?? AppColors.primary,
            secondaryColor: widget.secondaryColor ?? AppColors.primary.withOpacity(0.3),
            showGrid: widget.showGrid,
            showLabels: widget.showLabels,
            showValues: widget.showValues,
            animation: _animation.value,
            formatDate: _formatDate,
            context: context,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class LineChartPainter extends CustomPainter {
  final Map<DateTime, double> data;
  final double maxValue;
  final Color color;
  final bool showGrid;
  final bool showLabels;
  final bool showValues;
  final double animation;
  final String Function(DateTime) formatDate;
  final BuildContext context;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.showGrid,
    required this.showLabels,
    required this.showValues,
    required this.animation,
    required this.formatDate,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 10,
    );

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Draw grid
    if (showGrid) {
      for (int i = 0; i <= 4; i++) {
        final y = padding + (chartHeight * i / 4);
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          gridPaint,
        );
      }
    }

    // Draw line
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
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw labels
    if (showLabels) {
      for (int i = 0; i < sortedEntries.length; i += (sortedEntries.length > 7 ? 2 : 1)) {
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

    // Draw values on Y-axis
    if (showValues) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final Map<DateTime, double> data;
  final double maxValue;
  final Color color;
  final bool showGrid;
  final bool showLabels;
  final bool showValues;
  final double animation;
  final String Function(DateTime) formatDate;
  final BuildContext context;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.showGrid,
    required this.showLabels,
    required this.showValues,
    required this.animation,
    required this.formatDate,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 10,
    );

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final barWidth = chartWidth / sortedEntries.length * 0.8;

    // Draw grid
    if (showGrid) {
      for (int i = 0; i <= 4; i++) {
        final y = padding + (chartHeight * i / 4);
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          gridPaint,
        );
      }
    }

    // Draw bars
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final x = padding + (chartWidth * (i + 0.5) / sortedEntries.length) - (barWidth / 2);
      final barHeight = (chartHeight * entry.value / maxValue) * animation;
      final y = padding + chartHeight - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }

    // Draw labels
    if (showLabels) {
      for (int i = 0; i < sortedEntries.length; i += (sortedEntries.length > 7 ? 2 : 1)) {
        final entry = sortedEntries[i];
        final x = padding + (chartWidth * (i + 0.5) / sortedEntries.length);

        final textPainter = TextPainter(
          text: TextSpan(text: formatDate(entry.key), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 20));
      }
    }

    // Draw values on Y-axis
    if (showValues) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AreaChartPainter extends CustomPainter {
  final Map<DateTime, double> data;
  final double maxValue;
  final Color color;
  final Color secondaryColor;
  final bool showGrid;
  final bool showLabels;
  final bool showValues;
  final double animation;
  final String Function(DateTime) formatDate;
  final BuildContext context;

  AreaChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.secondaryColor,
    required this.showGrid,
    required this.showLabels,
    required this.showValues,
    required this.animation,
    required this.formatDate,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 10,
    );

    const padding = 40.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final sortedEntries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Draw grid
    if (showGrid) {
      for (int i = 0; i <= 4; i++) {
        final y = padding + (chartHeight * i / 4);
        canvas.drawLine(
          Offset(padding, y),
          Offset(size.width - padding, y),
          gridPaint,
        );
      }
    }

    // Draw area
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

    // Draw labels and values (same as line chart)
    if (showLabels) {
      for (int i = 0; i < sortedEntries.length; i += (sortedEntries.length > 7 ? 2 : 1)) {
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

    if (showValues) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}