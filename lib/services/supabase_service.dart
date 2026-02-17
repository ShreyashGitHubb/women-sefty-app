import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  /// Initialize Supabase (Call this in main.dart)
  static Future<void> initialize({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static Future<void> updateProfile({
    required String? name,
    required String? childEmail,
    required String? phone,
    required String? parentEmail,
    required String? profilePic,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final updates = {
      'full_name': name,
      'child_email': childEmail,
      'phone': phone,
      'parent_email': parentEmail,
      'avatar_url': profilePic, // Mapping profilepic to avatar_url or just profilepic if col exists
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Remove nulls if you only want to update detailed fields, but here we pass all.
    // If a field is null, we might not want to overwrite it with null unless intended.
    // For now, let's assume the UI passes current values if unchanged.
    
    await client.from('profiles').update(updates).eq('id', user.id);
  }

  // --- SOS Alerts ---

  static Future<void> createSOSAlert(String userId, String alertName, double lat, double long) async {
    try {
      await client.from('sos_alerts').insert({
        'user_id': userId,
        'alert_name': alertName,
        'lat': lat,
        'long': long,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error creating SOS alert: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getSOSAlerts() async {
    try {
      final data = await client
          .from('sos_alerts')
          .select('*, profiles(full_name)') // Assuming foreign key relation or just manual join if needed
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching SOS alerts: $e");
      return [];
    }
  }

  // --- Reviews ---

  static Future<void> createReview(String userId, String review) async {
    try {
      await client.from('reviews').insert({
        'user_id': userId,
        'review': review,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error creating review: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getReviews() async {
    try {
      final data = await client
          .from('reviews')
          .select('*, profiles(full_name, child_email, parent_email)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching reviews: $e");
      return [];
    }
  }

  // --- Admin User Management ---

  static Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching all profiles: $e");
      return [];
    }
  }

  static Future<void> deleteProfile(String userId) async {
    try {
      await client.from('profiles').delete().eq('id', userId);
      // Note: This only deletes from 'profiles'. 
      // To delete from auth.users requires a server-side function or admin API, 
      // which is not directly available in client logic without service key.
      // For now, we just remove the profile.
    } catch (e) {
      print("Error deleting profile: $e");
      throw e; 
    }
  }

  // --- Parent/Child Queries ---

  static Future<List<Map<String, dynamic>>> getChildren(String parentEmail) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('parent_email', parentEmail)
          .eq('type', 'child');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching children: $e");
      return [];
    }
  }

  // --- Authentication ---

  /// Sign Up with Email and Password
  static Future<AuthResponse?> signUp(String email, String password, String name, {String? type, String? phone, String? childEmail, String? parentEmail}) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'type': type}, // Store basic metadata
      );
      
      if (response.user != null) {
        // Create profile entry
        await createProfile(
          response.user!.id, 
          email, 
          name, 
          type: type, 
          phone: phone, 
          childEmail: childEmail, 
          parentEmail: parentEmail
        );
      }
      
      return response;
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error signing up: $e");
      return null;
    }
  }

  /// Sign In
  static Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: "Error signing in: $e");
      return null;
    }
  }

  /// Sign Out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get Current User
  static User? get currentUser => client.auth.currentUser;

  // --- Database (Profiles) ---

  /// Create Profile in 'profiles' table
  static Future<void> createProfile(String userId, String email, String name, {String? type, String? phone, String? childEmail, String? parentEmail}) async {
    try {
      await client.from('profiles').insert({
        'id': userId,
        'email': email,
        'full_name': name,
        'type': type,
        'phone': phone,
        'child_email': childEmail,
        'parent_email': parentEmail,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error creating profile: $e");
    }
  }

  /// Get Profile Data
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }
  // --- Contacts ---

  static Future<void> addContact(String name, String mobile, String? email) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('contacts').insert({
      'user_id': user.id,
      'name': name,
      'mobile': mobile,
      'email': email,
    });
  }

  static Future<List<Map<String, dynamic>>> getContacts() async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('contacts')
        .select()
        .eq('user_id', user.id);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> deleteContact(String contactId) async {
     await client.from('contacts').delete().eq('id', contactId);
  }

  // --- Chat ---

  static Stream<List<Map<String, dynamic>>> getMessages(String friendId) {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    String roomId = (user.id.compareTo(friendId) < 0) 
        ? '${user.id}_$friendId' 
        : '${friendId}_${user.id}';

    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((maps) => maps);
  }

  static Future<void> sendMessage(String friendId, String message, String type) async {
    final user = currentUser;
    if (user == null) return;
    
     String roomId = (user.id.compareTo(friendId) < 0) 
        ? '${user.id}_$friendId' 
        : '${friendId}_${user.id}';

    await client.from('messages').insert({
      'room_id': roomId,
      'sender_id': user.id,
      'receiver_id': friendId,
      'message': message,
      'type': type, 
    });
  }
}
