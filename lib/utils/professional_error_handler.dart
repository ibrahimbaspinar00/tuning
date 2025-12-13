import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class ProfessionalErrorHandler {
  static final ProfessionalErrorHandler _instance = ProfessionalErrorHandler._internal();
  factory ProfessionalErrorHandler() => _instance;
  ProfessionalErrorHandler._internal();

  /// Profesyonel hata gösterimi
  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    bool isDismissible = true,
  }) {
    _showProfessionalDialog(
      context: context,
      type: ErrorType.error,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
      isDismissible: isDismissible,
    );
  }

  /// Başarı mesajı
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    Duration? autoClose,
  }) {
    _showProfessionalDialog(
      context: context,
      type: ErrorType.success,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
      autoClose: autoClose,
    );
  }

  /// Bilgi mesajı
  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    _showProfessionalDialog(
      context: context,
      type: ErrorType.info,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Uyarı mesajı
  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    _showProfessionalDialog(
      context: context,
      type: ErrorType.warning,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Profesyonel dialog gösterimi
  static void _showProfessionalDialog({
    required BuildContext context,
    required ErrorType type,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    bool isDismissible = true,
    Duration? autoClose,
  }) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (context) => ProfessionalErrorDialog(
        type: type,
        title: title,
        message: message,
        actionText: actionText,
        onAction: onAction,
        autoClose: autoClose,
      ),
    );
  }

  /// Snackbar ile hızlı mesaj
  static void showQuickMessage({
    required BuildContext context,
    required String message,
    ErrorType type = ErrorType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData icon;

    switch (type) {
      case ErrorType.error:
        backgroundColor = Colors.red[600]!;
        icon = Icons.error_outline;
        break;
      case ErrorType.success:
        backgroundColor = Colors.green[600]!;
        icon = Icons.check_circle_outline;
        break;
      case ErrorType.warning:
        backgroundColor = Colors.orange[600]!;
        icon = Icons.warning_outlined;
        break;
      case ErrorType.info:
        backgroundColor = Colors.blue[600]!;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Network hatası kontrolü
  static void handleNetworkError(BuildContext context, dynamic error) {
    if (error is SocketException) {
      showError(
        context: context,
        title: 'Bağlantı Hatası',
        message: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
        actionText: 'Tekrar Dene',
        onAction: () {
          Navigator.pop(context);
          // Retry logic
        },
      );
    } else {
      showError(
        context: context,
        title: 'Bir Hata Oluştu',
        message: 'Lütfen daha sonra tekrar deneyin.',
      );
    }
  }

  /// Firebase hatası kontrolü
  static void handleFirebaseError(BuildContext context, dynamic error) {
    String title = 'Veritabanı Hatası';
    String message = 'Veriler yüklenirken bir hata oluştu.';

    if (error.toString().contains('permission')) {
      message = 'Bu işlem için yetkiniz bulunmuyor.';
    } else if (error.toString().contains('network')) {
      message = 'Ağ bağlantısı sorunu. Lütfen internet bağlantınızı kontrol edin.';
    } else if (error.toString().contains('timeout')) {
      message = 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }

    showError(
      context: context,
      title: title,
      message: message,
      actionText: 'Tamam',
    );
  }
}

enum ErrorType { error, success, warning, info }

class ProfessionalErrorDialog extends StatefulWidget {
  final ErrorType type;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Duration? autoClose;

  const ProfessionalErrorDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.autoClose,
  });

  @override
  State<ProfessionalErrorDialog> createState() => _ProfessionalErrorDialogState();
}

class _ProfessionalErrorDialogState extends State<ProfessionalErrorDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Auto close
    if (widget.autoClose != null) {
      Future.delayed(widget.autoClose!, () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.0, 1.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(),
                    
                    // Content
                    _buildContent(),
                    
                    // Actions
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    Color headerColor;
    IconData icon;
    String headerText;

    switch (widget.type) {
      case ErrorType.error:
        headerColor = Colors.red[600]!;
        icon = Icons.error_outline;
        headerText = 'Hata';
        break;
      case ErrorType.success:
        headerColor = Colors.green[600]!;
        icon = Icons.check_circle_outline;
        headerText = 'Başarılı';
        break;
      case ErrorType.warning:
        headerColor = Colors.orange[600]!;
        icon = Icons.warning;
        headerText = 'Uyarı';
        break;
      case ErrorType.info:
        headerColor = Colors.blue[600]!;
        icon = Icons.info_outline;
        headerText = 'Bilgi';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        widget.message,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          if (widget.actionText != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('İptal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onAction?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getActionColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.actionText!),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getActionColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getActionColor() {
    switch (widget.type) {
      case ErrorType.error:
        return Colors.red[600]!;
      case ErrorType.success:
        return Colors.green[600]!;
      case ErrorType.warning:
        return Colors.orange[600]!;
      case ErrorType.info:
        return Colors.blue[600]!;
    }
  }
}
