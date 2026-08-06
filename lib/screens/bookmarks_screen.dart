import 'package:flutter/material.dart';
import '../widgets/news_card.dart';
import '../services/bookmark_service.dart';
import 'article_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final bookmarks = BookmarkService.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookmarks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: bookmarks.isEmpty
          ? const Center(
              child: Text(
                'No bookmarks yet.\nSave articles to see them here!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final news = bookmarks[index];
                return NewsCard(
                  title: news['title'],
                  description: news['description'],
                  imageUrl: news['imageUrl'],
                  source: news['source'],
                  publishedAt: news['publishedAt'],
                  isBookmarked: true,
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