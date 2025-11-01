import 'package:flutter/material.dart';
import 'dart:ui';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Danh sách thành phố với ảnh - UPDATED URLs
  final List<Map<String, String>> _popularCities = [
    {
      'name': 'Ho Chi Minh',
      'country': 'Vietnam',
      'image': 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400&q=80',
    },
    {
      'name': 'Hanoi',
      'country': 'Vietnam',
      'image': 'https://hoanghamobile.com/tin-tuc/wp-content/uploads/2024/04/anh-ha-noi.jpg',
    },
    {
      'name': 'Da Nang',
      'country': 'Vietnam',
      'image': 'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20%C4%91%E1%BA%B9p%20%C4%91%C3%A0%20n%E1%BA%B5ng/anh-dep-da-nang-thumb.jpg',
    },
    {
      'name': 'Nha Trang',
      'country': 'Vietnam',
      'image': 'https://xaviahotel.com/vnt_upload/news/11_2017/nha-trang_1.jpg',
    },
    {
      'name': 'Can Tho',
      'country': 'Vietnam',
      'image': 'https://ezcloud.vn/wp-content/uploads/2023/07/dia-diem-check-in-can-tho.webp',
    },
    {
      'name': 'Hue',
      'country': 'Vietnam',
      'image': 'https://cdn-media.sforum.vn/storage/app/media/ctvseo_MH/%E1%BA%A3nh%20%C4%91%E1%BA%B9p%20Hu%E1%BA%BF/anh-dep-hue-1.jpg',
    },
    {
      'name': 'Tokyo',
      'country': 'Japan',
      'image': 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400&q=80',
    },
    {
      'name': 'New York',
      'country': 'USA',
      'image': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=400&q=80',
    },
    {
      'name': 'London',
      'country': 'UK',
      'image': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&q=80',
    },
    {
      'name': 'Paris',
      'country': 'France',
      'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400&q=80',
    },
    {
      'name': 'Seoul',
      'country': 'South Korea',
      'image': 'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=400&q=80',
    },
    {
      'name': 'Bangkok',
      'country': 'Thailand',
      'image': 'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=400&q=80',
    },
  ];

  Color _getGradientColor() {
    final hour = DateTime.now().hour;
    if (hour >= 18 || hour < 6) {
      return const Color(0xFF1a237e);
    }
    return const Color(0xFF4A90E2);
  }

  void _selectCity(String cityName) {
    // Debug print
    print('🌍 Selected city: $cityName');

    // Navigate back với city name
    Navigator.pop(context, cityName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getGradientColor(),
              const Color(0xFF5B8FE3),
              const Color(0xFF9B59B6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _buildCityGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              print('🔙 Back button pressed');
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Tìm thành phố',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thành phố...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  print('🔍 Search submitted: $value');
                  _selectCity(value);
                }
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _popularCities.length,
        itemBuilder: (context, index) {
          return _buildCityCard(_popularCities[index]);
        },
      ),
    );
  }

  Widget _buildCityCard(Map<String, String> city) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('👆 Card tapped: ${city['name']}');
          _selectCity(city['name']!);
        },
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.purple.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.network(
                  city['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Image error for ${city['name']}: $error');
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withValues(alpha: 0.5),
                            Colors.purple.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        size: 50,
                        color: Colors.white70,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withValues(alpha: 0.3),
                            Colors.purple.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // City info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        city['country']!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}