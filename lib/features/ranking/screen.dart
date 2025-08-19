import 'package:flutter/material.dart';
import '../../data/supabase/api_service.dart';
import '../../data/hive/hive_helper.dart';
import '../../theme/app_colors.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final SupabaseApi _apiService = SupabaseApi();
  final HiveHelper _hiveHelper = HiveHelper.instance;

  List<Map<String, dynamic>> _rankingList = [];
  Map<String, dynamic>? _userRanking;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadUserRanking();
    _loadRanking();
  }

  Future<void> _loadUserRanking() async {
    try {
      final userUUID = await _hiveHelper.getUserUUID();
      if (userUUID != null) {
        final ranking = await _apiService.getUserRanking(userUUID);
        setState(() {
          _userRanking = ranking;
        });
      }
    } catch (e) {
      print('사용자 랭킹 로드 실패: $e');
      // 사용자가 랭킹에 포함되지 않은 경우 (인벤토리가 비어있을 수 있음)
      setState(() {
        _userRanking = null;
      });
    }
  }

  Future<void> _loadRanking({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (refresh) {
        _currentOffset = 0;
        _hasMore = true;
      }

      final newRankings = await _apiService.getRanking(
        limit: _pageSize,
        offset: _currentOffset,
      );

      setState(() {
        if (refresh) {
          _rankingList = newRankings;
        } else {
          _rankingList.addAll(newRankings);
        }
        _currentOffset += _pageSize;

        // 더 정확한 끝 감지: 받아온 데이터가 요청한 페이지 크기보다 작으면 끝
        _hasMore = newRankings.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('랭킹 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 감지
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '랭킹',
          style: TextStyle(
            fontSize: isTablet ? 24.0 : 20.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRanking(refresh: true),
        child: Column(
          children: [
            // 사용자 자신의 랭킹 카드
            if (_userRanking != null) _buildUserRankingCard(),

            // 사용자가 랭킹에 포함되지 않은 경우 안내
            if (_userRanking == null) _buildNoRankingCard(),

            // 구분선
            const Divider(height: 1),

            // 전체 랭킹 리스트
            Expanded(
              child: _rankingList.isEmpty && !_isLoading
                  ? const Center(
                      child: Text('랭킹 데이터가 없습니다.'),
                    )
                  : ListView.builder(
                      itemCount: _rankingList.length +
                          (_hasMore || _isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _rankingList.length) {
                          if (_isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else if (_hasMore) {
                            // 스크롤 끝에 도달하면 자동으로 다음 페이지 로드
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _loadRanking();
                            });
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else {
                            // 더 이상 데이터가 없을 때 끝 메시지 표시
                            return Container(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '랭킹 끝에 도달했습니다',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '모든 랭킹을 확인하셨습니다! 🎉',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }

                        final ranking = _rankingList[index];
                        return _buildRankingItem(ranking, index + 1);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRankingCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.warningGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '아직 랭킹에 포함되지 않았습니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '조합 탭에서 재료를 획득해보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankingCard() {
    final rank = _userRanking!['rank'] as int;
    final user = _userRanking!['user'] as String;
    final ingredientCount = _userRanking!['ingredient_count'] as int;
    final lastAcquiredAt = _userRanking!['last_acquired_at'] as String;

    // 화면 크기 감지
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // 태블릿에서 크기 조정
    final margin = isTablet ? 24.0 : 16.0;
    final padding = isTablet ? 20.0 : 16.0;
    final rankSize = isTablet ? 60.0 : 50.0;
    final rankFontSize = isTablet ? 22.0 : 18.0;
    final userFontSize = isTablet ? 20.0 : 18.0;
    final infoFontSize = isTablet ? 16.0 : 14.0;
    final dateFontSize = isTablet ? 14.0 : 12.0;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 랭킹 순위
          Container(
            width: rankSize,
            height: rankSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rankFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user,
                  style: TextStyle(
                    fontSize: userFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryDark,
                  ),
                ),
                SizedBox(height: isTablet ? 6.0 : 4.0),
                Text(
                  '재료 $ingredientCount개 보유',
                  style: TextStyle(
                    fontSize: infoFontSize,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '마지막 획득: ${_formatDate(lastAcquiredAt)}',
                  style: TextStyle(
                    fontSize: dateFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 내 랭킹 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '내 랭킹',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> ranking, int index) {
    final rank = ranking['rank'] as int;
    final user = ranking['user'] as String;
    final ingredientCount = ranking['ingredient_count'] as int;
    final lastAcquiredAt = ranking['last_acquired_at'] as String;

    // 화면 크기 감지
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // 태블릿에서 크기 조정
    final margin = isTablet ? 24.0 : 16.0;
    final padding = isTablet ? 20.0 : 16.0;
    final rankSize = isTablet ? 50.0 : 40.0;
    final rankFontSize = isTablet ? 20.0 : 16.0;
    final userFontSize = isTablet ? 18.0 : 16.0;
    final infoFontSize = isTablet ? 16.0 : 14.0;
    final dateFontSize = isTablet ? 14.0 : 12.0;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: margin, vertical: isTablet ? 6.0 : 4.0),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 랭킹 순위
          Container(
            width: rankSize,
            height: rankSize,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rankFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: isTablet ? 20.0 : 16.0),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user,
                  style: TextStyle(
                    fontSize: userFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryDark,
                  ),
                ),
                SizedBox(height: isTablet ? 6.0 : 4.0),
                Text(
                  '재료 $ingredientCount개 보유',
                  style: TextStyle(
                    fontSize: infoFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '마지막 획득: ${_formatDate(lastAcquiredAt)}',
                  style: TextStyle(
                    fontSize: dateFontSize,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold; // 금메달
      case 2:
        return AppColors.silver; // 은메달
      case 3:
        return AppColors.bronze; // 동메달
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // 로컬 시간 그대로 사용 (이미 한국 시간으로 저장됨)
      return '${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
