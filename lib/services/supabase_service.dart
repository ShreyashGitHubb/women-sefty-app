import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  /// Initialize Supabase (Call this in main.dart)
  static Future<void> initialize({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
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
      print('Error creating review: $e');
      rethrow;
    }
  }

  /// Fetch all reviews with poster name via PostgREST join.
  /// Requires FK: reviews.user_id → profiles.id (run the SQL migration first).
  static Future<List<Map<String, dynamic>>> getReviews() async {
    try {
      final data = await client
          .from('reviews')
          .select('*, profiles(full_name)')  // FK join — shows poster name
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching reviews: $e');
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
        data: {'name': name, 'type': type},
      );

      if (response.user != null) {
        // Only attempt to create the profile if we have a live session.
        // When email confirmation is ON, signUp returns a user but NO session,
        // so any DB call will get 401. We skip it here — ensureProfileExists()
        // will create it after the user confirms their email and logs in.
        if (response.session != null) {
          try {
            await createProfile(
              response.user!.id,
              email,
              name,
              type: type,
              phone: phone,
              childEmail: childEmail,
              parentEmail: parentEmail,
            );
          } catch (profileError) {
            // Non-fatal — profile will be created on first login via ensureProfileExists()
            print('Profile creation deferred (no session yet): $profileError');
          }
        }
      }

      return response;
    } on AuthException catch (e) {
      // 429 rate limit: too many signup attempts
      if (e.statusCode == '429' || e.message.contains('rate limit') || e.message.contains('email')) {
        Fluttertoast.showToast(
          msg: 'Too many attempts. Please wait a few minutes before trying again.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.orange,
        );
      } else {
        Fluttertoast.showToast(msg: e.message);
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error signing up: $e');
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
      if (response.user == null) {
        // This case happens when email is not confirmed yet
        Fluttertoast.showToast(
          msg: 'Please confirm your email before logging in. Check your inbox.',
        );
        return null;
      }
      return response;
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error signing in: $e');
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
        'type': type ?? 'child',
        'phone': phone,
        'child_email': childEmail,
        'parent_email': parentEmail,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating profile: $e');
      rethrow;
    }
  }

  /// Called after a successful login to ensure the profile row exists.
  /// This handles users who signed up when email confirmation was ON —
  /// in that case createProfile was skipped (no session = 401), so we
  /// lazily create the profile here on their first actual login.
  static Future<void> ensureProfileExists() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final existing = await getProfile(user.id);
      if (existing == null) {
        // Profile missing — create it now that we have a valid session
        await client.from('profiles').upsert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.userMetadata?['name'] ?? '',
          'type': user.userMetadata?['type'] ?? 'child',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
        print('✅ Profile created on first login for ${user.id}');
      }
    } catch (e) {
      print('ensureProfileExists error (non-fatal): $e');
    }
  }

  /// Get Profile Data — uses maybeSingle() so it returns null instead of
  /// throwing PGRST116 (406) when the row doesn't exist yet.
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();   // ← was .single() which threw 406 when row missing
      return data;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  /// Update (or create) Profile Data.
  /// Uses upsert so it works even if the profile row was never created
  /// (fixes PGRST204 / 400 when PATCH matches 0 rows due to RLS or missing row).
  static Future<void> updateProfile({
    String? name,
    String? phone,
    String? childEmail,
    String? parentEmail,
    String? profilePic,
  }) async {
    final user = currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'You must be logged in to update your profile');
      return;
    }

    try {
      final updates = <String, dynamic>{
        'id': user.id,                                    // required for upsert
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null && name.isNotEmpty) updates['full_name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (childEmail != null) updates['child_email'] = childEmail;
      if (parentEmail != null) updates['parent_email'] = parentEmail;
      if (profilePic != null) updates['avatar_url'] = profilePic;

      // upsert = insert if not exists, update if exists — fixes the 400 PGRST204
      await client.from('profiles').upsert(updates, onConflict: 'id');
    } catch (e) {
      print('Error updating profile: $e');
      Fluttertoast.showToast(msg: 'Failed to update profile: $e');
      rethrow;
    }
  }

  static Future<void> addContact(String name, String mobile, String? email) async {
    final user = currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'You must be logged in to add contacts');
      return;
    }
    try {
      await client.from('contacts').insert({
        'user_id': user.id,
        'name': name,
        'mobile': mobile,
        'email': email,
      });
    } catch (e) {
      print('Error adding contact: $e');
      Fluttertoast.showToast(msg: 'Failed to add contact: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getContacts() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final data = await client
          .from('contacts')
          .select()
          .eq('user_id', user.id);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching contacts: $e');
      Fluttertoast.showToast(msg: 'Failed to load contacts');
      return [];
    }
  }

  static Future<void> deleteContact(String contactId) async {
    try {
      await client.from('contacts').delete().eq('id', contactId);
    } catch (e) {
      print('Error deleting contact: $e');
      Fluttertoast.showToast(msg: 'Failed to delete contact');
      rethrow;
    }
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
