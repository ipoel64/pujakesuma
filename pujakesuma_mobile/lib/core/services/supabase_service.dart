import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Authentication
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  // User Profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  // Database operations - Keluarga
  static Future<Map<String, dynamic>> uploadKeluarga(Map<String, dynamic> keluargaData) async {
    return await client.from('keluarga').insert(keluargaData).select().single();
  }

  // Database operations - Individu
  static Future<void> uploadIndividu(Map<String, dynamic> individuData) async {
    await client.from('individu').insert(individuData);
  }

  // Storage uploads
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      await client.storage.from(bucket).upload(path, file);
      final String publicUrl = client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  // Chat Rooms & Messages
  static Future<List<Map<String, dynamic>>> getChatRooms() async {
    final List<dynamic> data = await client
        .from('chat_rooms')
        .select('*, chat_participants!inner(*)')
        .eq('chat_participants.user_id', currentUser?.id ?? '');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getChatMessages(String roomId) async {
    final List<dynamic> data = await client
        .from('chat_messages')
        .select('*')
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> sendChatMessage({
    required String roomId,
    required String content,
    String? attachmentUrl,
  }) async {
    if (currentUser == null) return;
    await client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': currentUser!.id,
      'content': content,
      'attachment_url': attachmentUrl,
    });
  }
}
