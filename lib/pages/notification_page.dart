// lib/pages/notification_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../data/models/notification_model.dart';
import '../components/shimmer_loading.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showUnreadOnly = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });

    _scrollController.addListener(_onScroll);
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<NotificationProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadMore();
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (!_shouldRefresh) return;

    _lastRefreshTime = DateTime.now();
    final provider = context.read<NotificationProvider>();
    await provider.loadNotifications(onlyUnread: _showUnreadOnly);
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    final provider = context.read<NotificationProvider>();
    await provider.markAsRead(notification.id);
  }

  Future<void> _markAllAsRead() async {
    final provider = context.read<NotificationProvider>();
    await provider.markAllAsRead();
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      _markAsRead(notification);
    }

    // Navigate berdasarkan type
    final type = notification.type;
    final data = notification.data;

    switch (type) {
      case 'izin_approved':
      case 'izin_rejected':
        final izinId = int.tryParse(data['pengajuan_izin_id'] ?? '');
        if (izinId != null) {
          Navigator.pushNamed(context, AppRoutes.detailIzin, arguments: izinId);
        }
        break;

      case 'tukar_shift_approved':
      case 'tukar_shift_rejected':
        // Navigate ke detail tukar shift (jika sudah ada page-nya)
        final tukarShiftId = int.tryParse(data['tukar_shift_id'] ?? '');
        if (tukarShiftId != null) {
          // TODO: Implement detail tukar shift page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Detail tukar shift belum tersedia')),
          );
        }
        break;

      default:
        // Do nothing
        break;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _shouldRefresh) {
        _loadNotifications();
      }
    });
  }

  Future<void> _deleteNotification(int notificationId) async {
    final provider = context.read<NotificationProvider>();
    await provider.deleteNotification(notificationId);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 251, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            _buildFilterBar(screenWidth, padding),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return _buildShimmerLoading(screenWidth, padding);
                  }

                  if (provider.errorMessage != null) {
                    return _buildError(
                      screenWidth,
                      provider.errorMessage!,
                      _loadNotifications,
                    );
                  }

                  if (provider.notifications.isEmpty) {
                    return _buildEmpty(screenWidth);
                  }

                  return RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(padding),
                      itemCount: provider.notifications.length + 1,
                      itemBuilder: (context, index) {
                        if (index == provider.notifications.length) {
                          if (provider.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final notification = provider.notifications[index];
                        return _buildNotificationItem(
                          notification,
                          screenWidth,
                          padding,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: screenHeight * 0.02,
      ),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: screenWidth * 0.045,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Notifikasi",
            style: TextStyle(
              fontSize: screenWidth * 0.048,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final unreadCount = provider.unreadCount;
              if (unreadCount > 0) {
                return GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenWidth * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tandai Semua',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(width: screenWidth * 0.1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(double screenWidth, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: screenWidth * 0.03,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Tampilkan:',
            style: TextStyle(
              fontSize: screenWidth * 0.036,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Row(
              children: [
                _buildFilterChip('Semua', !_showUnreadOnly, () {
                  setState(() {
                    _showUnreadOnly = false;
                  });
                  _loadNotifications();
                }, screenWidth),
                SizedBox(width: screenWidth * 0.02),
                _buildFilterChip('Belum Dibaca', _showUnreadOnly, () {
                  setState(() {
                    _showUnreadOnly = true;
                  });
                  _loadNotifications();
                }, screenWidth),
              ],
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final unreadCount = provider.unreadCount;
              if (unreadCount > 0) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenWidth * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isActive,
    VoidCallback onTap,
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.034,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    double screenWidth,
    double padding,
  ) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'izin_approved':
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'izin_rejected':
        icon = Icons.cancel;
        iconColor = AppColors.error;
        break;
      case 'tukar_shift_approved':
        icon = Icons.check_circle;
        iconColor = Colors.blue;
        break;
      case 'tukar_shift_rejected':
        icon = Icons.cancel;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.primary;
    }

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: padding),
        margin: EdgeInsets.only(bottom: screenWidth * 0.03),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Notifikasi'),
            content: const Text('Yakin ingin menghapus notifikasi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: EdgeInsets.only(bottom: screenWidth * 0.03),
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: screenWidth * 0.06),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: screenWidth * 0.034,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.015),
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.03),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  borderRadius: 10,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.5,
                        height: 16,
                        borderRadius: 4,
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      ShimmerBox(
                        width: double.infinity,
                        height: 14,
                        borderRadius: 4,
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      ShimmerBox(
                        width: screenWidth * 0.6,
                        height: 14,
                        borderRadius: 4,
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      ShimmerBox(
                        width: screenWidth * 0.3,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(double screenWidth, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.15,
              color: AppColors.error.withOpacity(0.5),
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenWidth * 0.03,
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: screenWidth * 0.2,
              color: Colors.black26,
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              _showUnreadOnly
                  ? 'Tidak ada notifikasi belum dibaca'
                  : 'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.042,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              _showUnreadOnly
                  ? 'Semua notifikasi sudah dibaca'
                  : 'Notifikasi akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.036,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
