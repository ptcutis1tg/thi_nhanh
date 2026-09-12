import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/developer_mode_service.dart';

class DeveloperLogOverlay extends StatelessWidget {
  const DeveloperLogOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    DeveloperModeService? service;
    try {
      service = context.watch<DeveloperModeService>();
    } catch (_) {
      service = null;
    }

    if (service == null || !service.isDevModeActive) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      right: 20,
      child: Material(
        type: MaterialType.transparency,
        child: service.isExpanded ? _buildExpandedConsole(context, service) : _buildCollapsedBadge(context, service),
      ),
    );
  }

  Widget _buildCollapsedBadge(BuildContext context, DeveloperModeService service) {
    final logCount = service.logs.length;
    final isVerbose = service.level == DevModeLevel.verbose;

    return InkWell(
      onTap: () => service.setExpanded(true),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isVerbose ? const Color(0xFF06B6D4) : const Color(0xFFEF4444),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pest_control,
              color: isVerbose ? const Color(0xFF06B6D4) : const Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Dev ($logCount)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedConsole(BuildContext context, DeveloperModeService service) {
    final media = MediaQuery.of(context);
    final mediaWidth = media.size.width;
    final mediaHeight = media.size.height;
    final isVerbose = service.level == DevModeLevel.verbose;

    final double targetWidth = mediaWidth > 420 ? 380.0 : (mediaWidth - 32.0);
    final double targetHeight = (mediaHeight - 40.0) < 340.0 ? (mediaHeight - 40.0) : 340.0;

    return Container(
      width: targetWidth,
      height: targetHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pest_control,
                        size: 16,
                        color: isVerbose ? const Color(0xFF06B6D4) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Dev Console',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isVerbose ? const Color(0xFF06B6D4) : const Color(0xFFEF4444)).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isVerbose ? 'VERBOSE' : 'STANDARD',
                          style: TextStyle(
                            color: isVerbose ? const Color(0xFF06B6D4) : const Color(0xFFEF4444),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionBtn(
                        icon: Icons.copy_all,
                        tooltip: 'Sao chép tất cả log',
                        onPressed: () {
                          final allLogs = service.logs.map((e) => e.formattedText).join('\n\n---\n\n');
                          Clipboard.setData(ClipboardData(text: allLogs));
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép tất cả log vào clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildActionBtn(
                        icon: Icons.delete_outline,
                        tooltip: 'Xóa tất cả log',
                        onPressed: () => service.clearLogs(),
                      ),
                      const SizedBox(width: 4),
                      _buildActionBtn(
                        icon: Icons.remove,
                        tooltip: 'Thu nhỏ',
                        onPressed: () => service.setExpanded(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body content
          Expanded(
            child: service.logs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Chưa có log lỗi nào được ghi nhận.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: service.logs.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B), height: 16),
                    itemBuilder: (context, index) {
                      final log = service.logs[index];
                      return _buildLogItem(context, log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Icon(icon, size: 16, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, DevLogEntry log) {
    final isError = log.level == DevLogLevel.error;
    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isError
                            ? const Color(0xFFEF4444).withOpacity(0.2)
                            : const Color(0xFF06B6D4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isError ? 'ERROR' : 'DEBUG',
                        style: TextStyle(
                          color: isError ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Tooltip(
                    message: 'Sao chép log này',
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: log.formattedText));
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép log lỗi vào clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Center(
                        child: Icon(Icons.copy, size: 13, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          log.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (log.details != null && log.details!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            log.details!.trim(),
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 11.5,
            ),
          ),
        ],
        if (log.stackTrace != null && log.stackTrace!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF020617), // Slate 950
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                log.stackTrace!.trim(),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
