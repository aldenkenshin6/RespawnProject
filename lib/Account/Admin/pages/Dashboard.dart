import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalPosts = 0;
  int totalComments = 0;
  int totalLikes = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final postsSnapshot = await FirebaseFirestore.instance
        .collection("posts")
        .get();

    int postCount = postsSnapshot.docs.length;
    int commentCount = 0;
    int likeCount = 0;

    for (var post in postsSnapshot.docs) {
      // count likes
      List likes = post["likes"] ?? [];
      likeCount += likes.length;

      // count comments (subcollection)
      final commentsSnapshot = await post.reference
          .collection("comments")
          .get();
      commentCount += commentsSnapshot.docs.length;
    }

    setState(() {
      totalPosts = postCount;
      totalComments = commentCount;
      totalLikes = likeCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Statistics",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            // Pie Chart
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalPosts.toDouble(),
                      title: "Posts",
                      color: Colors.blue,
                    ),
                    PieChartSectionData(
                      value: totalComments.toDouble(),
                      title: "Comments",
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: totalLikes.toDouble(),
                      title: "Likes",
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bar Chart
            Expanded(
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: totalPosts.toDouble(),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: totalComments.toDouble(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: totalLikes.toDouble(),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
