import 'package:flutter/material.dart';
import '../widgets/news_card.dart';
import '../widgets/quote_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/breaking_news_banner.dart';
import '../widgets/trending_card.dart';
import '../services/news_service.dart';
import '../services/country_service.dart';
import '../services/bookmark_service.dart';
import '../services/quote_service.dart';
import '../services/preference_service.dart';
import '../services/city_service.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> newsList = [];
  List<Map<String, dynamic>> trendingList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String errorMessage = '';
  bool isSearching = false;
  bool showSuggestions = false;
  String selectedCategory = 'foryou';
  String lastSearchQuery = '';
  String currentSortBy = 'relevance';

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const String _startupsQuery =
      '"startup funding" OR "seed round" OR "raises funding" OR unicorn OR "new invention" OR "product launch"';

  final List<String> trendingSearches = [
    'Cricket',
    'Elections',
    'Stock Market',
    'Bollywood',
    'Technology',
    'Cyclone',
    'ISRO',
    'Budget 2026',
  ];

  final List<String> recencyKeywords = [
    'latest', 'today', 'now', 'breaking', 'recent',
    'newest', 'update', 'this week', 'currently',
  ];

  // Built fresh each time so the "My City" chip only appears once a city
  // has actually been set in Settings.
  List<Map<String, dynamic>> get categories {
    final list = <Map<String, dynamic>>[
      {'label': 'For You', 'value': 'foryou', 'icon': Icons.star_rounded},
      {'label': 'General', 'value': 'general', 'icon': Icons.public},
      {'label': 'Sports', 'value': 'sports', 'icon': Icons.sports_cricket},
      {'label': 'Technology', 'value': 'technology', 'icon': Icons.memory},
      {'label': 'Business', 'value': 'business', 'icon': Icons.business_center},
      {'label': 'Startups', 'value': 'startups', 'icon': Icons.rocket_launch},
      {'label': 'Health', 'value': 'health', 'icon': Icons.favorite},
      {'label': 'Science', 'value': 'science', 'icon': Icons.science},
      {'label': 'Entertainment', 'value': 'entertainment', 'icon': Icons.movie},
    ];

    if (CityService.hasCity) {
      list.add({
        'label': CityService.selectedCity,
        'value': 'mycity',
        'icon': Icons.location_city,
      });
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    loadNews();
    loadTrending();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 300) {
      loadMoreNews();
    }
  }

  Future<void> loadTrending() async {
    try {
      final trending = await NewsService.fetchTrending();
      if (mounted) {
        setState(() {
          trendingList = trending;
        });
      }
    } catch (e) {
      // Trending is a bonus section — fail silently, don't disturb the feed.
    }
  }

  Map<String, String> _analyzeQuery(String rawQuery) {
    String lower = rawQuery.toLowerCase();
    bool wantsLatest = recencyKeywords.any((k) => lower.contains(k));

    String cleaned = lower;
    for (final k in recencyKeywords) {
      cleaned = cleaned.replaceAll(k, '');
    }
    cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleaned.isEmpty) cleaned = rawQuery.trim();

    return {
      'query': cleaned,
      'sortBy': wantsLatest ? 'publishedAt' : 'relevance',
    };
  }

  Future<void> loadNews() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      isSearching = false;
      showSuggestions = false;
      currentPage = 1;
      hasMore = true;
    });

    try {
      List<Map<String, dynamic>> news;

      if (selectedCategory == 'foryou') {
        final topCategories = PreferenceService.topCategories(count: 3);
        news = await NewsService.fetchForYou(topCategories);
      } else if (selectedCategory == 'startups') {
        news = await NewsService.searchNews(
          _startupsQuery,
          page: 1,
          sortBy: 'publishedAt',
        );
      } else if (selectedCategory == 'mycity' && CityService.hasCity) {
        news = await NewsService.searchNews(
          CityService.selectedCity,
          page: 1,
          sortBy: 'publishedAt',
        );
      } else {
        news = await NewsService.fetchTopHeadlines(
          category: selectedCategory,
          country: CountryService.selectedCountry,
          page: 1,
        );
      }

      setState(() {
        newsList = news;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error Loading News: $e');
      setState(() {
        errorMessage = 'Failed to load news. Please check your internet connection.';
        isLoading = false;
      });
    }
  }

  Future<void> performSearch(String rawQuery) async {
    if (rawQuery.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
      isSearching = true;
      showSuggestions = false;
      lastSearchQuery = rawQuery;
      currentPage = 1;
      hasMore = true;
    });

    final analyzed = _analyzeQuery(rawQuery);
    currentSortBy = analyzed['sortBy']!;

    try {
      var news = await NewsService.searchNews(
        analyzed['query']!,
        page: 1,
        sortBy: currentSortBy,
      );

      if (news.isEmpty && currentSortBy != 'publishedAt') {
        currentSortBy = 'publishedAt';
        news = await NewsService.searchNews(
          analyzed['query']!,
          page: 1,
          sortBy: currentSortBy,
        );
      }

      if (news.isEmpty && analyzed['query'] != rawQuery.trim()) {
        news = await NewsService.searchNews(
          rawQuery.trim(),
          page: 1,
          sortBy: currentSortBy,
        );
      }

      setState(() {
        newsList = news;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Search failed. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> retryCurrent() async {
    if (isSearching && lastSearchQuery.isNotEmpty) {
      await performSearch(lastSearchQuery);
    } else {
      await loadNews();
      loadTrending();
    }
  }

  Future<void> loadMoreNews() async {
    if (isLoadingMore || !hasMore || isLoading) return;

    // "For You" is a merged, deduplicated feed without page-based pagination.
    if (selectedCategory == 'foryou') return;

    setState(() {
      isLoadingMore = true;
    });

    final nextPage = currentPage + 1;

    try {
      List<Map<String, dynamic>> moreNews;

      if (isSearching && lastSearchQuery.isNotEmpty) {
        final analyzed = _analyzeQuery(lastSearchQuery);
        moreNews = await NewsService.searchNews(
          analyzed['query']!,
          page: nextPage,
          sortBy: currentSortBy,
        );
      } else if (selectedCategory == 'startups') {
        moreNews = await NewsService.searchNews(
          _startupsQuery,
          page: nextPage,
          sortBy: 'publishedAt',
        );
      } else if (selectedCategory == 'mycity' && CityService.hasCity) {
        moreNews = await NewsService.searchNews(
          CityService.selectedCity,
          page: nextPage,
          sortBy: 'publishedAt',
        );
      } else {
        moreNews = await NewsService.fetchTopHeadlines(
          category: selectedCategory,
          country: CountryService.selectedCountry,
          page: nextPage,
        );
      }

      final existingTitles = newsList.map((n) => n['title']).toSet();
      final newUniqueNews =
          moreNews.where((n) => !existingTitles.contains(n['title'])).toList();

      setState(() {
        if (newUniqueNews.isEmpty) {
          hasMore = false;
        } else {
          newsList.addAll(newUniqueNews);
          currentPage = nextPage;
        }
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        hasMore = false;
        isLoadingMore = false;
      });
    }
  }

  void selectCategory(String category) {
    if (category != 'foryou' && category != 'mycity') {
      PreferenceService.recordCategoryView(category);
    }
    setState(() {
      selectedCategory = category;
      searchController.clear();
    });
    loadNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search news...',
                  border: InputBorder.none,
                ),
                onSubmitted: performSearch,
              )
            : const Text('Newsly'),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (isSearching) {
                searchController.clear();
                loadNews();
              } else {
                setState(() {
                  isSearching = true;
                  showSuggestions = true;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isSearching)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final bool isSelected = selectedCategory == cat['value'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat['label']),
                      avatar: Icon(
                        cat['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : Colors.deepOrange,
                      ),
                      selected: isSelected,
                      selectedColor: Colors.deepOrange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => selectCategory(cat['value']),
                    ),
                  );
                },
              ),
            ),
          Expanded(child: showSuggestions ? buildSuggestions() : buildBody()),
        ],
      ),
    );
  }

  Widget buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Searches',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: trendingSearches.map((term) {
              return ActionChip(
                label: Text(term),
                avatar: const Icon(Icons.trending_up, size: 16, color: Colors.deepOrange),
                backgroundColor: Colors.deepOrange.withValues(alpha: 0.08),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                onPressed: () {
                  searchController.text = term;
                  performSearch(term);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildTrendingSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 20),
                const SizedBox(width: 6),
                const Text(
                  'Trending Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trendingList.length,
              itemBuilder: (context, index) {
                final item = trendingList[index];
                return TrendingCard(
                  title: item['title'] ?? '',
                  imageUrl: item['imageUrl'] ?? '',
                  source: item['source'] ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(article: item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        itemCount: 5,
        itemBuilder: (context, index) => const ShimmerCard(),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: retryCurrent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (newsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'No results for "$lastSearchQuery"'
                    : 'No news available.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isSearching) ...[
                const SizedBox(height: 8),
                const Text(
                  'Try different or simpler keywords.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final todaysQuote = QuoteService.getTodaysQuote();

    final bool showTrending = !isSearching && trendingList.isNotEmpty;
    final int trendingOffset = showTrending ? 1 : 0;
    final int baseOffset = 2 + trendingOffset;

    return RefreshIndicator(
      onRefresh: retryCurrent,
      color: Colors.deepOrange,
      backgroundColor: Theme.of(context).cardColor,
      strokeWidth: 3,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        itemCount: newsList.length + baseOffset + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return BreakingNewsBanner(
              title: newsList[0]['title'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailScreen(article: newsList[0]),
                  ),
                );
              },
            );
          }

          if (index == 1) {
            return QuoteCard(
              quote: todaysQuote['quote']!,
              author: todaysQuote['author']!,
            );
          }

          if (showTrending && index == 2) {
            return buildTrendingSection();
          }

          if (index == newsList.length + baseOffset) {
            if (isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                ),
              );
            }
            if (!hasMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "You're all caught up 👍",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final news = newsList[index - baseOffset];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: NewsCard(
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
            ),
          );
        },
      ),
    );
  }
}