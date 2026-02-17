import 'package:flutter/material.dart';
import 'package:map_app/services/supabase_service.dart';

class ViewReviews extends StatefulWidget {
  const ViewReviews({super.key});

  @override
  State<ViewReviews> createState() => _ViewReviewsState();
}

class _ViewReviewsState extends State<ViewReviews> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Reviews"),
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Text(
                "No reviews available.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              // Assuming Supabase query joined 'profiles' and returns it in 'profiles' key
              final profile = review['profiles']; 
              final name = profile != null ? profile['full_name'] : "Anonymous";
              final childEmail = profile != null ? profile['child_email'] : "";

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    name ?? "Anonymous",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(childEmail ?? "No Email"),
                      const SizedBox(height: 5),
                      Text(
                        review['review'] ?? "No Review Provided",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                       
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
