import 'package:flutter/material.dart';
import '../widgets/news_card.dart';
import '../services/history_service.dart';
import '../services/bookmark_service.dart';
import 'article_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Reading History?'),
        content: const Text('This will remove all your reading history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        HistoryService.clearHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = HistoryService.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reading History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: confirmClear,
            ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'No reading history yet.\nArticles you open will show up here!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final news = history[index];
                return NewsCard(
                  title: news['title'],
                  description: news['description'],
                  imageUrl: news['imageUrl'],
                  source: news['source'],
                  publishedAt: news['publishedAt'],
                  isBookmarked: BookmarkService.isBookmarked(news['title']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(article: news),
                      ),
                    );
                  },
                  onBookmark: () {
                    setState(() {
                      BookmarkService.toggleBookmark(news);
                    });
                  },
                );
              },
            ),
    );
  }
}