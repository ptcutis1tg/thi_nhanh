import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TakingExamScreen extends StatefulWidget {
  const TakingExamScreen({super.key});

  @override
  State<TakingExamScreen> createState() => _TakingExamScreenState();
}

class _TakingExamScreenState extends State<TakingExamScreen> {
  int _currentQuestionIndex = 4; // Mocking question 5
  String? _selectedOption;

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: const Text('Bạn có chắc muốn thoát? Kết quả bài thi sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildMinimalAppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildQuestionArea(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildLeaderboardSidebar(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMinimalAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, // Hide default back button
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.edit_square, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Thi Nhanh', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Row(
            children: [
              Icon(Icons.timer, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('29:45', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
          label: const Text('Thoát', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.border, height: 1),
      ),
    );
  }

  Widget _buildQuestionArea() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Câu hỏi ${_currentQuestionIndex + 1}/20',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.flag_outlined, size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 4),
                  Text('Đánh dấu để xem lại', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Cho hàm số y = f(x) liên tục trên ℝ và có bảng biến thiên như hình dưới đây. Khẳng định nào sau đây là đúng?',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            alignment: Alignment.center,
            child: const Text('Mock Image Placeholder', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 4,
              children: [
                _buildOptionTile('A', 'Hàm số đạt cực đại tại x = 0'),
                _buildOptionTile('B', 'Hàm số có giá trị cực tiểu bằng -2'),
                _buildOptionTile('C', 'Hàm số đồng biến trên khoảng (-∞; -1)'),
                _buildOptionTile('D', 'Hàm số nghịch biến trên khoảng (-1; 1)'),
              ],
            ),
          ),
          
          const Divider(height: 32, color: AppTheme.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _currentQuestionIndex > 0
                    ? () {
                        setState(() {
                          _currentQuestionIndex--;
                          _selectedOption = null;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Câu trước'),
              ),
              _buildPagination(),
              ElevatedButton.icon(
                onPressed: _currentQuestionIndex < 19
                    ? () {
                        setState(() {
                          _currentQuestionIndex++;
                          _selectedOption = null;
                        });
                      }
                    : () {
                        // Giả lập nộp bài nếu đang ở câu cuối cùng
                        Navigator.pushReplacementNamed(context, '/result');
                      },
                icon: Icon(_currentQuestionIndex < 19 ? Icons.chevron_right : Icons.send),
                label: Text(_currentQuestionIndex < 19 ? 'Câu sau' : 'Nộp bài'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentQuestionIndex < 19 ? null : AppTheme.success,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String value, String text) {
    final isSelected = _selectedOption == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = value;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: 2),
                color: isSelected ? AppTheme.primary : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: isSelected ? const Icon(Icons.circle, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(
              '$value.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      children: [
        _buildPageNumber('1', isAnswered: true, isCurrent: _currentQuestionIndex == 0),
        _buildPageNumber('2', isAnswered: true, isCurrent: _currentQuestionIndex == 1),
        _buildPageNumber('3', isAnswered: true, isCurrent: _currentQuestionIndex == 2),
        _buildPageNumber('4', isAnswered: true, isCurrent: _currentQuestionIndex == 3),
        if (_currentQuestionIndex > 3 && _currentQuestionIndex < 19)
          _buildPageNumber('${_currentQuestionIndex + 1}', isCurrent: true),
        if (_currentQuestionIndex <= 3) _buildPageNumber('5', isCurrent: _currentQuestionIndex == 4),
        if (_currentQuestionIndex <= 4) _buildPageNumber('6'),
        const SizedBox(width: 8),
        const Text('...'),
      ],
    );
  }

  Widget _buildPageNumber(String number, {bool isAnswered = false, bool isCurrent = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCurrent ? Colors.white : (isAnswered ? AppTheme.primary : Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(color: isCurrent ? AppTheme.primary : (isAnswered ? AppTheme.primary : AppTheme.border), width: isCurrent ? 2 : 1),
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          color: isCurrent ? AppTheme.primary : (isAnswered ? Colors.white : AppTheme.textSecondary),
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLeaderboardSidebar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange),
              SizedBox(width: 8),
              Text('Bảng xếp hạng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: Text('LIVE', style: TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.border),
          _buildRankItem(1, 'Nguyễn Văn A', 17, 20, color: Colors.amber),
          _buildRankItem(2, 'Trần Thị B', 16, 20, color: Colors.blueGrey),
          _buildRankItem(3, 'Lê Hoàng C', 15, 20, color: Colors.brown),
          _buildRankItem(4, 'Phạm D', 14, 20),
          _buildRankItem(5, 'Hoàng E', 13, 20),
          const Divider(height: 32, color: AppTheme.border),
          _buildRankItem(42, 'Bạn (Tôi)', 5, 20, color: AppTheme.primary, isSelf: true),
        ],
      ),
    );
  }

  Widget _buildRankItem(int rank, String name, int score, int total, {Color color = AppTheme.border, bool isSelf = false}) {
    final progress = score / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelf ? AppTheme.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelf ? Border.all(color: AppTheme.primary.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(fontWeight: FontWeight.bold, color: color != AppTheme.border ? color : AppTheme.textSecondary),
              ),
            ),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: isSelf ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(color != AppTheme.border ? color : AppTheme.primary.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$score/$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
