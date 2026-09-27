import 'package:supabase_flutter/supabase_flutter.dart';

enum AiNavigationAction { goHome, none }

class AiNavigationService {
  AiNavigationService(this._client);

  final SupabaseClient _client;

  Future<AiNavigationAction> interpret(String command) async {
    final normalizedCommand = command.trim();
    if (normalizedCommand.isEmpty) return AiNavigationAction.none;

    final response = await _client.functions.invoke(
      'ai-navigation',
      body: {'command': normalizedCommand},
    );

    final data = response.data;
    if (data is Map && data['action'] == 'go_home') {
      return AiNavigationAction.goHome;
    }

    return AiNavigationAction.none;
  }
}
