import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'webview_screen.dart';
import '../widgets/image_placeholder.dart';
import '../services/history_service.dart';
import '../services/reaction_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  String? selectedReaction;

  final List<Map<String, String>> reactionOptions = [
    {'emoji': '👍', 'label': 'Like'},
    {'emoji': '😮', 'label': 'Surprised'},
    {'emoji': '😢', 'label': 'Sad'},
  ];

  @override
  void initState() {
    super.initState();
    HistoryService.addToHistory(widget.article);
    selectedReaction = ReactionService.getReaction(widget.article['title'] ?? '');

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> toggleSpeech() async {
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      final title = widget.article['title'] ?? '';
      final description = widget.article['description'] ?? '';
      final textToRead = '$title. $description';

      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(0.48);
      await flutterTts.setPitch(1.0);

      setState(() {
        isSpeaking = true;
      });

      await flutterTts.speak(textToRead);
    }
  }

  void handleReaction(String emoji) {
    final title = widget.article['title'] ?? '';
    ReactionService.setReaction(title, emoji);
    setState(() {
      selectedReaction = ReactionService.getReaction(title);
    });
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(
                    '${article['title']}\n\nRead more: ${article['url']}',
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: article['imageUrl'] != null && article['imageUrl'] != ''
                  ? CachedNetworkImage(
                      imageUrl: article['imageUrl'],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const NewslyImagePlaceholder(height: 280, iconSize: 70),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : const NewslyImagePlaceholder(height: 280, iconSize: 70),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article['source'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: toggleSpeech,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSpeaking
                                ? Colors.deepOrange
                                : Colors.deepOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSpeaking ? Icons.stop_circle : Icons.volume_up,
                                size: 18,
                                color: isSpeaking ? Colors.white : Colors.deepOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isSpeaking ? 'Stop' : 'Listen',
                                style: TextStyle(
                                  color: isSpeaking ? Colors.white : Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    article['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        article['publishedAt'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    article['description'] ?? 'No description available.',
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // Reactions
                  const Text(
                    'How does this make you feel?',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: reactionOptions.map((option) {
                      final bool isSelected = selectedReaction == option['emoji'];
                      return GestureDetector(
                        onTap: () => handleReaction(option['emoji']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepOrange.withValues(alpha: 0.15)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.deepOrange : Colors.grey.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(option['emoji']!, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                option['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.deepOrange : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final url = article['url'];
                        if (url != null && url != '') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewScreen(
                                url: url,
                                title: article['source'] ?? 'Article',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Read Full Article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}