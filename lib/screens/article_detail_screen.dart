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
  // GNews truncates content with a "[123 chars]" suffix — strip that off
  // so it doesn't look like a rendering glitch.
  String get _expandedContent {
    final raw = widget.article['content'] ?? '';
    final cleaned = raw.replaceAll(RegExp(r'\s*\[\d+\s*chars\]\s*$'), '').trim();
    return cleaned.isNotEmpty ? cleaned : (widget.article['description'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 19),
                    onPressed: () {
                      Share.share(
                        '${article['title']}\n\nRead more: ${article['url']}',
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  article['imageUrl'] != null && article['imageUrl'] != ''
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
                  // Subtle bottom gradient so the status bar icons and back
                  // button stay legible over bright images.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: toggleSpeech,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
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
                                    isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                                    size: 17,
                                    color: isSpeaking ? Colors.white : Colors.deepOrange,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isSpeaking ? 'Stop' : 'Listen',
                                    style: TextStyle(
                                      color: isSpeaking ? Colors.white : Colors.deepOrange,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        article['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.32,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            article['publishedAt'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _expandedContent.isNotEmpty
                            ? _expandedContent
                            : 'No description available.',
                        style: const TextStyle(fontSize: 15.5, height: 1.65),
                      ),
                      const SizedBox(height: 26),

                      // Reactions
                      Text(
                        'How does this make you feel?',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: reactionOptions.map((option) {
                          final bool isSelected = selectedReaction == option['emoji'];
                          return GestureDetector(
                            onTap: () => handleReaction(option['emoji']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepOrange.withValues(alpha: 0.12)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.grey.withValues(alpha: 0.06)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepOrange
                                      : Colors.transparent,
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(option['emoji']!, style: const TextStyle(fontSize: 17)),
                                  const SizedBox(width: 6),
                                  Text(
                                    option['label']!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.deepOrange
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),
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
                          icon: const Icon(Icons.open_in_new_rounded, size: 19),
                          label: const Text(
                            'Read Full Article',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}