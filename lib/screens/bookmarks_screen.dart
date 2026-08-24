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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: Colors.deepOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Bookmarks',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.deepOrange.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        Icons.bookmark_border_rounded,
                        size: 42,
                        color: Colors.deepOrange.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No bookmarks yet',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon on any article to save it here for later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${bookmarks.length} saved ${bookmarks.length == 1 ? 'article' : 'articles'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Swipe to remove',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Icon(
                            Icons.swipe_left_rounded,
                            size: 15,
                            color: Colors.grey[500],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 20),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final news = bookmarks[index];
                      return Dismissible(
                        key: Key(news['title'] ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() {
                            BookmarkService.toggleBookmark(news);
                          });
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        child: NewsCard(
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}