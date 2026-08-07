import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class RoomPasswordScreen extends StatefulWidget {
  const RoomPasswordScreen({super.key});

  @override
  State<RoomPasswordScreen> createState() => _RoomPasswordScreenState();
}

class _RoomPasswordScreenState extends State<RoomPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu phòng thi.');
      return;
    }
    // Password validation belongs on the server; no room secret is stored in the app.
    context.go('/student_waiting_room');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Thi Nhanh', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)), actions: [IconButton(onPressed: () => context.go('/search'), icon: const Icon(Icons.close, color: AppTheme.textMain))]),
    body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Container(
      width: 560, padding: const EdgeInsets.all(48), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 28, offset: const Offset(0, 12))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 76, height: 76, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(Icons.lock_outline, color: Colors.white, size: 40)),
        const SizedBox(height: 28), Text('Yêu cầu mật khẩu', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 12), const Text('Phòng thi này được bảo vệ. Vui lòng nhập mật khẩu chính xác để tiếp tục.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 30),
        TextField(controller: _passwordController, obscureText: _obscure, onChanged: (_) { if (_error != null) setState(() => _error = null); }, onSubmitted: (_) => _submit(), decoration: InputDecoration(prefixIcon: const Icon(Icons.key_outlined), hintText: 'Nhập mật khẩu phòng thi', errorText: _error, suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
        const SizedBox(height: 22), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.arrow_forward), label: const Text('Xác nhận vào phòng'))), const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Quay lại'))),
      ]),
    ))),
  );
}
