// lib/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'cache_service.dart';
import 'constants.dart';

/// Screen cài đặt
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    final temperatureUnit = ref.watch(temperatureUnitProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Giao diện
          const _SectionHeader(title: 'GIAO DIỆN'),
          Card(
            child: SwitchListTile(
              secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Chế độ tối'),
              subtitle: Text(isDarkMode ? 'Đang bật' : 'Đang tắt'),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(darkModeProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section: Đơn vị
          const _SectionHeader(title: 'ĐƠN VỊ'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.thermostat),
              title: const Text('Đơn vị nhiệt độ'),
              subtitle: Text('Hiện tại: $temperatureUnit'),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '°C', label: Text('°C')),
                  ButtonSegment(value: '°F', label: Text('°F')),
                ],
                selected: {temperatureUnit},
                onSelectionChanged: (Set<String> selected) {
                  ref.read(temperatureUnitProvider.notifier).setUnit(selected.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Thông báo
          const _SectionHeader(title: 'THÔNG BÁO'),
          Card(
            child: SwitchListTile(
              secondary: Icon(notificationsEnabled ? Icons.notifications_active : Icons.notifications_off),
              title: const Text('Thông báo thời tiết'),
              subtitle: Text(notificationsEnabled ? 'Đang bật' : 'Đang tắt'),
              value: notificationsEnabled,
              onChanged: (value) {
                ref.read(notificationsProvider.notifier).toggle();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section: Cache
          const _SectionHeader(title: 'BỘ NHỚ CACHE'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Xóa cache'),
                  subtitle: const Text('Xóa dữ liệu thời tiết đã lưu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa cache'),
                        content: const Text('Bạn có chắc muốn xóa toàn bộ cache?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await CacheService().clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa cache thành công')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Thông tin
          const _SectionHeader(title: 'THÔNG TIN'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Phiên bản'),
                  subtitle: Text(APP_VERSION),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Về ứng dụng'),
                  subtitle: const Text(APP_NAME),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: APP_NAME,
                      applicationVersion: APP_VERSION,
                      applicationIcon: const Icon(Icons.cloud, size: 48),
                      children: [
                        const Text('Ứng dụng thời tiết với Riverpod'),
                        const Text('Developed with ❤️ in Vietnam'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget header cho section
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
