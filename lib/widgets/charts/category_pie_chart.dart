import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';

class CategoryPieChart extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final List<CategoryModel> categories;
  final double size;
  final bool showLegend;
  final bool showPercentages;
  final bool showValues;
  final bool isInteractive;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final String? title;
  final int? maxCategories;

  const CategoryPieChart({
    Key? key,
    required this.expenses,
    required this.categories,
    this.size = 200,
    this.showLegend = true,
    this.showPercentages = true,
    this.showValues = false,
    this.isInteractive = true,
    this.backgroundColor,
    this.padding,
    this.title,
    this.maxCategories,
  }) : super(key: key);

  // ✅ made public
  static const List<Color> defaultColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    Colors.purple,
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.brown,
  ];

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  List<_PieSlice> _slices = [];
  int? _selectedIndex;
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
  void didUpdateWidget(CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses ||
        oldWidget.categories != widget.categories) {
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
    final categoryTotals = <String, double>{};
    _totalAmount = 0;

    for (final expense in widget.expenses) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      _totalAmount += expense.amount;
    }

    if (_totalAmount == 0) {
      _slices.clear();
      return;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<MapEntry<String, double>> displayEntries = sortedEntries;
    if (widget.maxCategories != null &&
        sortedEntries.length > widget.maxCategories!) {
      displayEntries = sortedEntries.take(widget.maxCategories! - 1).toList();
      final othersTotal = sortedEntries
          .skip(widget.maxCategories! - 1)
          .fold<double>(0, (sum, entry) => sum + entry.value);

      if (othersTotal > 0) {
        displayEntries.add(MapEntry('others', othersTotal));
      }
    }

    _slices.clear();
    double startAngle = -math.pi / 2;

    for (int i = 0; i < displayEntries.length; i++) {
      final entry = displayEntries[i];
      final percentage = entry.value / _totalAmount;
      final sweepAngle = percentage * 2 * math.pi;

      final category = entry.key == 'others'
          ? null
          : widget.categories.firstWhere(
            (cat) => cat.id == entry.key,
        orElse: () => CategoryModel(
          id: entry.key,
          userId: 'user_1', // ✅ required
          type: 'expense', // ✅ required
          name: 'Unknown',
          icon: Icons.help.codePoint,
          color: CategoryPieChart.defaultColors[i %
              CategoryPieChart.defaultColors.length]
              .value,
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      _slices.add(_PieSlice(
        categoryId: entry.key,
        categoryName:
        entry.key == 'others' ? 'Others' : (category?.name ?? 'Unknown'),
        amount: entry.value,
        percentage: percentage,
        color: entry.key == 'others'
            ? Colors.grey
            : (category != null
            ? Color(category.color)
            : CategoryPieChart.defaultColors[
        i % CategoryPieChart.defaultColors.length]),
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        icon: entry.key == 'others' ? Icons.more_horiz.codePoint : category?.icon,
      ));

      startAngle += sweepAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: widget.backgroundColor != null
          ? BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (_slices.isEmpty)
            _buildEmptyChart()
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: widget.showLegend ? 2 : 3,
                  child: Center(
                    child: _buildPieChart(),
                  ),
                ),
                if (widget.showLegend) ...[
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildLegend()),
                ],
              ],
            ),
            if (_selectedIndex != null && widget.isInteractive)
              _buildSelectedDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: widget.size,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(height: 8),
            Text(
              'No data to display',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: widget.isInteractive ? _handleTapDown : null,
          child: CustomPaint(
            painter: PieChartPainter(
              slices: _slices,
              selectedIndex: _selectedIndex,
              animation: _animation.value,
              showPercentages: widget.showPercentages,
              showValues: widget.showValues,
              context: context,
            ),
            size: Size(widget.size, widget.size),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_slices.length, (index) {
          final slice = _slices[index];
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: widget.isInteractive
                ? () => setState(() {
              _selectedIndex = _selectedIndex == index ? null : index;
            })
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                isSelected ? slice.color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: slice.color, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (slice.icon != null) ...[
                    Icon(
                      IconData(slice.icon!, fontFamily: 'MaterialIcons'),
                      size: 16,
                      color: slice.color,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      slice.categoryName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.showValues
                        ? CurrencyUtils.formatCurrency(slice.amount)
                        : '${(slice.percentage * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: slice.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedDetails() {
    if (_selectedIndex == null || _selectedIndex! >= _slices.length) {
      return const SizedBox.shrink();
    }
    final slice = _slices[_selectedIndex!];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: slice.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slice.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (slice.icon != null) ...[
                Icon(
                  IconData(slice.icon!, fontFamily: 'MaterialIcons'),
                  color: slice.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  slice.categoryName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: slice.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.7))),
                  Text(CurrencyUtils.formatCurrency(slice.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Percentage',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.7))),
                  Text('${(slice.percentage * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: slice.color,
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final tapPosition = details.localPosition - center;
    final distance = tapPosition.distance;
    if (distance > widget.size / 2) return;
    final angle = math.atan2(tapPosition.dy, tapPosition.dx) + math.pi / 2;
    final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;
    for (int i = 0; i < _slices.length; i++) {
      final slice = _slices[i];
      final startAngle =
      slice.startAngle < 0 ? slice.startAngle + 2 * math.pi : slice.startAngle;
      final endAngle = startAngle + slice.sweepAngle;
      if (normalizedAngle >= startAngle && normalizedAngle <= endAngle) {
        setState(() {
          _selectedIndex = _selectedIndex == i ? null : i;
        });
        break;
      }
    }
  }
}

class _PieSlice {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final int? icon;
  _PieSlice({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    this.icon,
  });
}

class PieChartPainter extends CustomPainter {
  final List<_PieSlice> slices;
  final int? selectedIndex;
  final double animation;
  final bool showPercentages;
  final bool showValues;
  final BuildContext context;
  PieChartPainter({
    required this.slices,
    required this.selectedIndex,
    required this.animation,
    required this.showPercentages,
    required this.showValues,
    required this.context,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.8;
    final selectedRadius = radius * 1.1;
    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final isSelected = selectedIndex == i;
      final currentRadius = isSelected ? selectedRadius : radius;
      final paint = Paint()..color = slice.color..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = Theme.of(context).scaffoldBackgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final animatedSweepAngle = slice.sweepAngle * animation;
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(Rect.fromCircle(center: center, radius: currentRadius),
          slice.startAngle, animatedSweepAngle, false);
      path.close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, strokePaint);
      if ((showPercentages || showValues) && slice.percentage > 0.05) {
        final labelAngle = slice.startAngle + (animatedSweepAngle / 2);
        final labelRadius = currentRadius * 0.7;
        final labelX = center.dx + labelRadius * math.cos(labelAngle);
        final labelY = center.dy + labelRadius * math.sin(labelAngle);
        final text = showValues
            ? CurrencyUtils.formatCurrency(slice.amount)
            : '${(slice.percentage * 100).toStringAsFixed(1)}%';
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: _getContrastColor(slice.color),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas,
            Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2));
      }
    }
    if (selectedIndex != null) {
      final centerPaint = Paint()
        ..color = Theme.of(context).scaffoldBackgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.3, centerPaint);
      final totalText =
          'Total\n${CurrencyUtils.formatCurrency(slices.fold<double>(0, (sum, slice) => sum + slice.amount))}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: totalText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(center.dx - textPainter.width / 2,
              center.dy - textPainter.height / 2));
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ✅ fixed SimplePieChart
class SimplePieChart extends StatelessWidget {
  final Map<String, double> data;
  final double size;
  final bool showLegend;
  const SimplePieChart({
    Key? key,
    required this.data,
    this.size = 200,
    this.showLegend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenses = <ExpenseModel>[];
    final categories = <CategoryModel>[];
    int index = 0;
    data.forEach((key, value) {
      final categoryId = 'category_$index';
      categories.add(CategoryModel(
        id: categoryId,
        userId: 'user_1', // ✅ required
        type: 'expense',  // ✅ required
        name: key,
        description: 'Auto-generated category',
        icon: Icons.category.codePoint,
        color: CategoryPieChart
            .defaultColors[index % CategoryPieChart.defaultColors.length]
            .value,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expenses.add(ExpenseModel(
        id: 'expense_$index',
        userId: 'user_1', // ✅ required
        title: key,       // ✅ required
        description: key,
        amount: value,
        categoryId: categoryId,
        categoryName: key, // ✅ required
        date: DateTime.now(),
        type: 'expense',   // ✅ required
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      index++;
    });
    return CategoryPieChart(
      expenses: expenses,
      categories: categories,
      size: size,
      showLegend: showLegend,
    );
  }
}
