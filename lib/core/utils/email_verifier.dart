class EmailVerifier {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static const Set<String> _disposableDomains = {
    'yopmail.com',
    'mailinator.com',
    'tempmail.com',
    'tempmail.net',
    'tempmail.org',
    'guerrillamail.com',
    'dispostable.com',
    '10minutemail.com',
    'trashmail.com',
    'sharklasers.com',
    'getnada.com',
    'maildrop.cc',
    'fakeinbox.com',
    'throwawaymail.com',
    'byom.de',
    'crazymailing.com',
    'boun.cr',
    'mohmal.com',
    'burnermail.io',
  };

  /// Kiểm tra định dạng email và loại trừ tên miền email rác/tạm thời
  static Future<void> verifyEmail(String email) async {
    final cleanEmail = email.trim();

    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Địa chỉ Email không đúng định dạng (Ví dụ: name@gmail.com).');
    }

    final parts = cleanEmail.split('@');
    if (parts.length != 2) {
      throw Exception('Địa chỉ Email không hợp lệ.');
    }

    final domain = parts[1].toLowerCase();
    if (_disposableDomains.contains(domain)) {
      throw Exception('Vui lòng không sử dụng Email rác hoặc Email tạm thời.');
    }
  }
}
