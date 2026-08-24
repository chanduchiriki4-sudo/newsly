import 'package:flutter/material.dart';
import '../widgets/news_card.dart';
import '../widgets/quote_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/breaking_news_banner.dart';
import '../widgets/trending_card.dart';
import '../widgets/info_strip_card.dart';
import '../services/news_service.dart';
import '../services/country_service.dart';
import '../services/bookmark_service.dart';
import '../services/quote_service.dart';
import '../services/preference_service.dart';
import '../services/city_service.dart';
import '../services/search_history_service.dart';
import '../services/wikipedia_service.dart';
import '../services/weather_service.dart';
import '../services/crypto_service.dart';
import '../services/stock_service.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> newsList = [];
  List<Map<String, dynamic>> trendingList = [];
  List<String> relatedSearches = [];
  Map<String, dynamic>? weatherData;
  List<Map<String, dynamic>> cryptoList = [];
  List<Map<String, dynamic>> stockList = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String errorMessage = '';
  bool isSearching = false;
  bool showSuggestions = false;
    String selectedCategory = 'general';
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
    loadWeather();
    loadCrypto();
    loadStocks();
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

  Future<void> loadWeather() async {
    try {
      final weather = await WeatherService.fetchCurrentWeather();
      if (mounted && weather != null) {
        setState(() {
          weatherData = weather;
        });
      }
    } catch (e) {
      // Weather is a bonus card — fail silently, don't disturb the feed.
    }
  }

  Future<void> loadCrypto() async {
    try {
      final crypto = await CryptoService.fetchTopCrypto();
      if (mounted && crypto.isNotEmpty) {
        setState(() {
          cryptoList = crypto;
        });
      }
    } catch (e) {
      // Crypto is a bonus card — fail silently.
    }
  }

  Future<void> loadStocks() async {
    try {
      final stocks = await StockService.fetchIndices();
      if (mounted && stocks.isNotEmpty) {
        setState(() {
          stockList = stocks;
        });
      }
    } catch (e) {
      // Bonus card — fail silently.
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

  List<Map<String, dynamic>> _reRankByRelevance(
    List<Map<String, dynamic>> articles,
    String query,
  ) {
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3)
        .toList();

    if (queryWords.isEmpty) return articles;

    int scoreFor(Map<String, dynamic> article) {
      final title = (article['title'] ?? '').toString().toLowerCase();
      int score = 0;
      for (final word in queryWords) {
        if (title.contains(word)) {
          score += 2;
          if (title.startsWith(word)) score += 1;
        }
      }
      return score;
    }

    final scored = articles.map((a) => MapEntry(a, scoreFor(a))).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  List<String> _extractRelatedTerms(
    List<Map<String, dynamic>> articles,
    String excludeQuery,
  ) {
    final excludeLower = excludeQuery.toLowerCase();
    final Map<String, int> phraseCounts = {};

    final properNounPattern =
        RegExp(r'\b([A-Z][a-zA-Z]*(?:\s+[A-Z][a-zA-Z]*){0,2})\b');

    for (final article in articles) {
      final title = (article['title'] ?? '').toString();
      final matches = properNounPattern.allMatches(title);
      for (final match in matches) {
        final phrase = match.group(0)!.trim();
        if (phrase.length < 3) continue;
        if (phrase.toLowerCase() == excludeLower) continue;
        if (excludeLower.contains(phrase.toLowerCase())) continue;
        phraseCounts[phrase] = (phraseCounts[phrase] ?? 0) + 1;
      }
    }

    final sorted = phraseCounts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(6).map((e) => e.key).toList();
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

    SearchHistoryService.addSearch(rawQuery.trim());

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

      // If results are thin, try Wikipedia to find a closely related term
      // (e.g. "ISRO" -> "Indian Space Research Organisation") and search
      // that too — broadens results without needing AI.
      if (news.length < 6) {
        final relatedTopics = await WikipediaService.fetchRelatedTopics(analyzed['query']!);
        final existingTitles = news.map((a) => a['title']).toSet();
        for (final topic in relatedTopics.take(2)) {
          if (topic.toLowerCase() == analyzed['query']!.toLowerCase()) continue;
          try {
            final extra = await NewsService.searchNews(
              topic,
              page: 1,
              sortBy: currentSortBy,
            );
            for (final article in extra) {
              if (!existingTitles.contains(article['title'])) {
                existingTitles.add(article['title']);
                news.add(article);
              }
            }
          } catch (_) {
            continue;
          }
        }
      }


      
               // Free-plan searches often return very few results for niche queries.
      // Pull additional pages (newest-first) and the other sort order too,
      // merging everything (deduped) so today's news appears first, followed
      // by slightly older articles — giving a fuller, richer result list.
      if (news.length < 8) {
        final existingTitles = news.map((a) => a['title']).toSet();

        Future<void> addMore(String sortBy, int page) async {
          try {
            final more = await NewsService.searchNews(
              analyzed['query']!,
              page: page,
              sortBy: sortBy,
            );
            for (final article in more) {
              if (!existingTitles.contains(article['title'])) {
                existingTitles.add(article['title']);
                news.add(article);
              }
            }
          } catch (_) {
            // ignore individual page failures
          }
        }

        final fallbackSort = currentSortBy == 'publishedAt' ? 'relevance' : 'publishedAt';
        await addMore(fallbackSort, 1);
        await addMore('publishedAt', 2);
        await addMore('publishedAt', 3);

        // Newest first, since we merged from multiple sources/pages.
        news.sort((a, b) {
          final dateA = DateTime.tryParse(a['publishedAt'] ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['publishedAt'] ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
      }

      if (news.isEmpty && analyzed['query'] != rawQuery.trim()) {
        news = await NewsService.searchNews(
          rawQuery.trim(),
          page: 1,
          sortBy: currentSortBy,
        );
      }
            final ranked = currentSortBy == 'relevance'
          ? _reRankByRelevance(news, rawQuery)
          : news;

      debugPrint('Search "$rawQuery" -> ${ranked.length} results, sortBy: $currentSortBy');

      setState(() {
        newsList = ranked;
        relatedSearches = _extractRelatedTerms(ranked, rawQuery);
        isLoading = false;
      });
        } catch (e) {
      debugPrint('Search Error: $e');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
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
            : Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF6B35), Color(0xFFE64A19)],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Newsly',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close_rounded : Icons.search_rounded),
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
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          if (!isSearching)
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide.none,
                      ),
                      elevation: isSelected ? 2 : 0,
                      shadowColor: Colors.deepOrange.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.white70
                                : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
    final recent = SearchHistoryService.recentSearches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, color: Colors.grey[600], size: 19),
                    const SizedBox(width: 6),
                    const Text(
                      'Recent Searches',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      SearchHistoryService.clearHistory();
                    });
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: recent.map((term) {
                return ActionChip(
                  label: Text(term),
                  avatar: Icon(Icons.history_rounded, size: 16, color: Colors.grey[600]),
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide.none,
                  ),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  onPressed: () {
                    searchController.text = term;
                    performSearch(term);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.deepOrange, size: 19),
              const SizedBox(width: 6),
              const Text(
                'Trending Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide.none,
                ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Trending Now',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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

    if (isSearching && relatedSearches.isNotEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: relatedSearches.length,
                itemBuilder: (context, index) {
                  final term = relatedSearches[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(term, style: const TextStyle(fontSize: 12.5)),
                      backgroundColor: Colors.deepOrange.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      onPressed: () => performSearch(term),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(child: buildNewsListView()),
        ],
      );
    }

    return buildNewsListView();
  }

  Widget buildNewsListView() {
    final todaysQuote = QuoteService.getTodaysQuote();
    final bool showInfoStrip =
        !isSearching && (weatherData != null || cryptoList.isNotEmpty);
    final bool showTrending = !isSearching && trendingList.isNotEmpty;
    final int infoOffset = showInfoStrip ? 1 : 0;
    final int trendingOffset = showTrending ? 1 : 0;
    final int baseOffset = 2 + infoOffset + trendingOffset;

    final int bannerIndex = 0;
    final int infoIndex = 1;
    final int quoteIndex = 1 + infoOffset;
    final int trendingIndex = 2 + infoOffset;

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
          if (index == bannerIndex) {
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

          if (showInfoStrip && index == infoIndex) {
            String? label;
            String? icon;
            if (weatherData != null) {
              final desc = WeatherService.describeWeatherCode(weatherData!['weatherCode']);
              label = desc['label'];
              icon = desc['icon'];
            }
            return InfoStripCard(
              temperature: weatherData?['temperature'],
              weatherLabel: label,
              weatherIcon: icon,
              cryptoList: cryptoList,
              stockList: stockList,
            );
          }

          if (index == quoteIndex) {
            return QuoteCard(
              quote: todaysQuote['quote']!,
              author: todaysQuote['author']!,
            );
          }

          if (showTrending && index == trendingIndex) {
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