import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/profile_service.dart';
import '../../shared/widgets/google_pagination_bar.dart';

class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({super.key});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  StudentProfileData _data = StudentProfileData.empty();

  // Filters
  String _searchQuery = '';
  String _selectedSubject = 'Tất cả';
  String _dateFilter = 'all'; // all, today, 7days, 30days, custom
  DateTimeRange? _customDateRange;
  String _scoreFilter = 'all'; // all, high (>=8), medium (5-7.9), low (<5)
  String _sort = 'newest'; // newest, oldest, highest, lowest

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 1;

  static const List<String> _availableSubjects = [
    'Tất cả',
    'Toán',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Tiếng Anh',
    'Ngữ văn',
    'Lịch sử',
    'Địa lý',
    'Tin học',
    'GDCD',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final data = await ProfileService.fetchStudentData(
      userId: authProvider.user?.id,
      userEmail: authProvider.userEmail,
      userName: authProvider.userName,
    );
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  List<StudentTestHistoryData> get _filteredAndSortedItems {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var list = _data.recentTests.where((item) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchSubject = item.subject.toLowerCase().contains(q);
        if (!matchTitle && !matchSubject) return false;
      }

      // Subject filter
      if (_selectedSubject != 'Tất cả') {
        if (item.subject.toLowerCase() != _selectedSubject.toLowerCase()) {
          return false;
        }
      }

      // Date filter
      if (_dateFilter != 'all') {
        final submitted = item.submittedAt;
        if (submitted == null) {
          // If no parsed date, check date string or exclude
          if (_dateFilter != 'all') return false;
        } else {
          final testDate = DateTime(submitted.year, submitted.month, submitted.day);
          if (_dateFilter == 'today') {
            if (!testDate.isAtSameMomentAs(today)) return false;
          } else if (_dateFilter == '7days') {
            if (now.difference(submitted).inDays > 7) return false;
          } else if (_dateFilter == '30days') {
            if (now.difference(submitted).inDays > 30) return false;
          } else if (_dateFilter == 'custom' && _customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
            if (submitted.isBefore(start) || submitted.isAfter(end)) return false;
          }
        }
      }

      // Score filter
      if (_scoreFilter == 'high') {
        if (item.scoreValue < 8.0) return false;
      } else if (_scoreFilter == 'medium') {
        if (item.scoreValue < 5.0 || item.scoreValue >= 8.0) return false;
      } else if (_scoreFilter == 'low') {
        if (item.scoreValue >= 5.0) return false;
      }

      return true;
    }).toList();

    // Sort
    switch (_sort) {
      case 'oldest':
        list.sort((a, b) {
          if (a.submittedAt != null && b.submittedAt != null) {
            return a.submittedAt!.compareTo(b.submittedAt!);
          }
          return 0;
        });
        break;
      case 'highest':
        list.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
        break;
      case 'lowest':
        list.sort((a, b) => a.scoreValue.compareTo(b.scoreValue));
        break;
      case 'newest':
      default:
        list.sort((a, b) {
          if (a.submittedAt != null && b.submittedAt != null) {
            return b.submittedAt!.compareTo(a.submittedAt!);
          }
          return 0;
        });
        break;
    }

    return list;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedSubject = 'Tất cả';
      _dateFilter = 'all';
      _customDateRange = null;
      _scoreFilter = 'all';
      _sort = 'newest';
      _currentPage = 1;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _dateFilter = 'custom';
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredAndSortedItems;
    final totalPages = (filteredItems.length / _pageSize).ceil().clamp(1, 99999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _pageSize;
    final pageItems = filteredItems.skip(startIndex).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FE),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/profile');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
                          tooltip: 'Quay lại',
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '📊 Lịch Sử Làm Bài Thi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Metrics Row
                    Row(
                      children: [
                        _buildMetricCard(
                          'Tổng số bài đã làm',
                          '${_data.completedTestsCount} bài',
                          Icons.assignment_turned_in_outlined,
                          const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 14),
                        _buildMetricCard(
                          'Điểm trung bình',
                          '${_data.averageScore.toStringAsFixed(1)} / 10',
                          Icons.analytics_outlined,
                          const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 14),
                        _buildMetricCard(
                          'Điểm cao nhất',
                          '${_data.highestScore.toStringAsFixed(1)} / 10',
                          Icons.star_outline_rounded,
                          const Color(0xFFD97706),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Search Box
                    _buildSearchBox(),
                    const SizedBox(height: 24),

                    // Main Layout: Filter Panel + Results List
                    Flex(
                      direction: compact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Filter Panel
                        SizedBox(
                          width: compact ? double.infinity : 270,
                          child: _buildFilterPanel(),
                        ),
                        SizedBox(width: compact ? 0 : 28, height: compact ? 24 : 0),

                        // Right Content Panel
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(48.0),
                                    child: CircularProgressIndicator(color: AppTheme.primary),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status Summary Bar
                                    if (filteredItems.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.find_in_page_outlined, size: 18, color: AppTheme.textSecondary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Tìm thấy ${filteredItems.length} bài thi • Đang hiện ${startIndex + 1} - ${math.min(startIndex + _pageSize, filteredItems.length)} (Trang $_currentPage / $totalPages)',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Attempt Cards List
                                    if (pageItems.isEmpty)
                                      _buildEmptyState()
                                    else
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: pageItems.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          return _buildHistoryCard(pageItems[index]);
                                        },
                                      ),

                                    // Pagination Bar
                                    if (totalPages > 1) ...[
                                      const SizedBox(height: 24),
                                      GooglePaginationBar(
                                        currentPage: _currentPage,
                                        totalPages: totalPages,
                                        onPageChanged: (page) {
                                          setState(() => _currentPage = page);
                                          _scrollController.animateTo(
                                            0,
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeOutCubic,
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const Key('history-search-field'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm đề thi đã làm theo tên đề, môn học...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                  _currentPage = 1;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _currentPage = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ Lọc',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Đặt lại', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(height: 16),

          // 1. Môn thi
          const Text('Môn thi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableSubjects.map((sub) {
              final isSelected = _selectedSubject == sub;
              return ChoiceChip(
                label: Text(sub, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textMain)),
                selected: isSelected,
                selectedColor: AppTheme.primary,
                backgroundColor: const Color(0xFFF7F5FE),
                showCheckmark: false,
                onSelected: (val) {
                  setState(() {
                    _selectedSubject = sub;
                    _currentPage = 1;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 2. Thời gian nộp
          const Text('Thời gian nộp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildDateChip('all', 'Tất cả'),
              _buildDateChip('today', 'Hôm nay'),
              _buildDateChip('7days', '7 ngày qua'),
              _buildDateChip('30days', '30 ngày qua'),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _dateFilter == 'custom' ? AppTheme.primary.withValues(alpha: 0.1) : const Color(0xFFF7F5FE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _dateFilter == 'custom' ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range_outlined, size: 16, color: _dateFilter == 'custom' ? AppTheme.primary : AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _customDateRange != null && _dateFilter == 'custom'
                          ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}/${_customDateRange!.end.year}'
                          : 'Tùy chọn khoảng ngày...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _dateFilter == 'custom' ? FontWeight.bold : FontWeight.normal,
                        color: _dateFilter == 'custom' ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Điểm số
          const Text('Điểm số', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildScoreChip('all', 'Tất cả'),
              _buildScoreChip('high', '≥ 8.0 (Giỏi)'),
              _buildScoreChip('medium', '5.0 - 7.9 (Khá)'),
              _buildScoreChip('low', '< 5.0 (Cần cố gắng)'),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Sắp xếp
          const Text('Sắp xếp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sort,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                  DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất')),
                  DropdownMenuItem(value: 'highest', child: Text('Điểm cao nhất')),
                  DropdownMenuItem(value: 'lowest', child: Text('Điểm thấp nhất')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _sort = val;
                      _currentPage = 1;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String key, String label) {
    final isSelected = _dateFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textMain)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFFF7F5FE),
      showCheckmark: false,
      onSelected: (val) {
        setState(() {
          _dateFilter = key;
          _currentPage = 1;
        });
      },
    );
  }

  Widget _buildScoreChip(String key, String label) {
    final isSelected = _scoreFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textMain)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFFF7F5FE),
      showCheckmark: false,
      onSelected: (val) {
        setState(() {
          _scoreFilter = key;
          _currentPage = 1;
        });
      },
    );
  }

  Widget _buildHistoryCard(StudentTestHistoryData item) {
    Color pillBg;
    Color pillText;
    if (item.scoreValue >= 8.0) {
      pillBg = const Color(0xFFDCFCE7);
      pillText = const Color(0xFF166534);
    } else if (item.scoreValue >= 5.0) {
      pillBg = const Color(0xFFF0ECFF);
      pillText = AppTheme.primary;
    } else {
      pillBg = const Color(0xFFFFEDD5);
      pillText = const Color(0xFFC2410C);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBE6FC)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/result?attemptId=${Uri.encodeComponent(item.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(item.subjectIcon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.subject,
                            style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.date,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  item.score,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: pillText,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                key: Key('history-view-result-${item.id}'),
                onPressed: () => context.go('/result?attemptId=${Uri.encodeComponent(item.id)}'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Xem kết quả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'Không tìm thấy bài thi nào phù hợp với bộ lọc.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa bộ lọc & Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
