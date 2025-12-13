import 'package:flutter/material.dart';

class NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionText;

  const NotificationWidget({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
    this.onAction,
    this.actionText,
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  NavigatorState? _navigator;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store Navigator reference safely
    _navigator = Navigator.of(context, rootNavigator: false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted && _navigator != null) {
        try {
          _navigator!.pop();
        } catch (e) {
          // Navigator already popped or widget disposed
          debugPrint('Error dismissing notification: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: _getGradientColors(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIcon(),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getTitle(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onAction != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                widget.onAction!();
                                _dismiss();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                              child: Text(widget.actionText ?? 'İşlem'),
                            ),
                          ],
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _dismiss,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors() {
    switch (widget.type) {
      case NotificationType.success:
        return [Colors.green[400]!, Colors.green[600]!];
      case NotificationType.error:
        return [Colors.red[400]!, Colors.red[600]!];
      case NotificationType.warning:
        return [Colors.orange[400]!, Colors.orange[600]!];
      case NotificationType.info:
        return [Colors.blue[400]!, Colors.blue[600]!];
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case NotificationType.success:
        return 'Başarılı';
      case NotificationType.error:
        return 'Hata';
      case NotificationType.warning:
        return 'Uyarı';
      case NotificationType.info:
        return 'Bilgi';
    }
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class NotificationService {
  static void showSuccess(BuildContext context, String message, {VoidCallback? onAction, String? actionText}) {
    _showNotification(
      context,
      NotificationWidget(
        message: message,
        type: NotificationType.success,
        onAction: onAction,
        actionText: actionText,
      ),
    );
  }

  static void showError(BuildContext context, String message, {VoidCallback? onAction, String? actionText}) {
    _showNotification(
      context,
      NotificationWidget(
        message: message,
        type: NotificationType.error,
        onAction: onAction,
        actionText: actionText,
      ),
    );
  }

  static void showWarning(BuildContext context, String message, {VoidCallback? onAction, String? actionText}) {
    _showNotification(
      context,
      NotificationWidget(
        message: message,
        type: NotificationType.warning,
        onAction: onAction,
        actionText: actionText,
      ),
    );
  }

  static void showInfo(BuildContext context, String message, {VoidCallback? onAction, String? actionText}) {
    _showNotification(
      context,
      NotificationWidget(
        message: message,
        type: NotificationType.info,
        onAction: onAction,
        actionText: actionText,
      ),
    );
  }

  static void _showNotification(BuildContext context, Widget notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => notification,
    );
  }
}
