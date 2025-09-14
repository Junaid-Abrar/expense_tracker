import 'package:flutter/material.dart';

enum BudgetCardType { standard, compact, detailed, overview }

class BudgetCard extends StatefulWidget {
  final String title;
  final double budgetAmount;
  final double spentAmount;
  final BudgetCardType type;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final EdgeInsets? margin;

  const BudgetCard({
    Key? key,
    required this.title,
    required this.budgetAmount,
    required this.spentAmount,
    this.type = BudgetCardType.standard,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.margin,
  }) : super(key: key);

  @override
  _BudgetCardState createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getProgressPercentage() {
    if (widget.budgetAmount == 0) return 0.0;
    return (widget.spentAmount / widget.budgetAmount).clamp(0.0, 1.0);
  }

  Color _getStatusColor() {
    final percentage = _getProgressPercentage();
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    return Colors.green;
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: Container(
            margin: widget.margin ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: _buildCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    switch (widget.type) {
      case BudgetCardType.standard:
        return _buildStandardCard();
      case BudgetCardType.compact:
        return _buildCompactCard();
      case BudgetCardType.detailed:
        return _buildDetailedCard();
      case BudgetCardType.overview:
        return _buildOverviewCard();
    }
  }

  Widget _buildStandardCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleMedium),
                _buildActionsMenu(),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _getProgressPercentage(),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_getStatusColor()),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Spent: \$${widget.spentAmount.toStringAsFixed(2)}"),
                Text("Budget: \$${widget.budgetAmount.toStringAsFixed(2)}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.account_balance_wallet, color: _getStatusColor()),
        title: Text(widget.title),
        subtitle: LinearProgressIndicator(
          value: _getProgressPercentage(),
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(_getStatusColor()),
        ),
        trailing: Text(
          "\$${widget.spentAmount.toStringAsFixed(0)} / ${widget.budgetAmount.toStringAsFixed(0)}",
          style: TextStyle(color: _getStatusColor()),
        ),
        onTap: widget.onTap,
      ),
    );
  }

  Widget _buildDetailedCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleLarge),
                Icon(_getStatusIcon(), color: _getStatusColor()),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _getProgressPercentage(),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_getStatusColor()),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Text("Spent: \$${widget.spentAmount.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.grey.shade700)),
            Text("Budget: \$${widget.budgetAmount.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            _buildActionsMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(widget.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: _getProgressPercentage(),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_getStatusColor()),
            ),
            const SizedBox(height: 4),
            Text(
              "\$${widget.spentAmount.toStringAsFixed(0)} of ${widget.budgetAmount.toStringAsFixed(0)}",
            ),
          ],
        ),
        trailing: Icon(_getStatusIcon(), color: _getStatusColor()),
      ),
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') widget.onEdit?.call();
        if (value == 'delete') widget.onDelete?.call();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text("Edit")),
        const PopupMenuItem(value: 'delete', child: Text("Delete")),
      ],
    );
  }

  IconData _getStatusIcon() {
    final percentage = _getProgressPercentage();
    if (percentage >= 1.0) return Icons.warning;
    if (percentage >= 0.8) return Icons.info;
    return Icons.check_circle;
  }
}

// Convenience wrappers
class StandardBudgetCard extends BudgetCard {
  const StandardBudgetCard({
    Key? key,
    required String title,
    required double budgetAmount,
    required double spentAmount,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    EdgeInsets? margin,
  }) : super(
    key: key,
    title: title,
    budgetAmount: budgetAmount,
    spentAmount: spentAmount,
    type: BudgetCardType.standard,
    onTap: onTap,
    onEdit: onEdit,
    onDelete: onDelete,
    margin: margin,
  );
}

class CompactBudgetCard extends BudgetCard {
  const CompactBudgetCard({
    Key? key,
    required String title,
    required double budgetAmount,
    required double spentAmount,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    EdgeInsets? margin,
  }) : super(
    key: key,
    title: title,
    budgetAmount: budgetAmount,
    spentAmount: spentAmount,
    type: BudgetCardType.compact,
    onTap: onTap,
    onEdit: onEdit,
    onDelete: onDelete,
    margin: margin,
  );
}

class OverviewBudgetCard extends BudgetCard {
  const OverviewBudgetCard({
    Key? key,
    required String title,
    required double budgetAmount,
    required double spentAmount,
    VoidCallback? onTap,
    EdgeInsets? margin,
  }) : super(
    key: key,
    title: title,
    budgetAmount: budgetAmount,
    spentAmount: spentAmount,
    type: BudgetCardType.overview,
    onTap: onTap,
    margin: margin,
  );
}
