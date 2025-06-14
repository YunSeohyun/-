import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:knowme_frontend/features/posts/controllers/post_controller.dart';
import 'package:knowme_frontend/features/posts/models/contests_model.dart';
import 'package:knowme_frontend/features/posts/widgets/post_grid.dart';
import 'package:knowme_frontend/features/posts/widgets/post_tab_bar.dart';
import 'package:knowme_frontend/features/posts/widgets/filter_row_widget.dart';
import 'package:knowme_frontend/shared/widgets/base_scaffold.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen>
    with SingleTickerProviderStateMixin {
  final List<String> tabTitles = ['채용', '인턴', '대외활동', '교육/강연', '공모전'];
  late TabController _tabController;

  // View에서 직접 생성하지 않고 routes에서 주입된 컨트롤러 사용
  late PostController _postController;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 주입받기
    _postController = Get.find<PostController>();

    // Get.arguments에서 tabIndex를 받아옴
    int initialIndex = 0; // 기본값

    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args.containsKey('tabIndex') && args['tabIndex'] is int) {
        initialIndex = args['tabIndex'];
        // PostController의 현재 탭 인덱스도 업데이트
        _postController.currentTabIndex.value = initialIndex;
      }
    }

    _tabController = TabController(
      length: tabTitles.length,
      vsync: this,
      initialIndex: initialIndex, // arguments에서 받아온 인덱스로 설정
    );

    // TabBar와 PageView 연결
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // PageController는 postController 내부에 있으므로 접근하여 사용
        _postController.changeTab(_tabController.index);
      }
    });

    // PostController의 pageController도 해당 페이지로 이동시킴
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postController.pageController.jumpToPage(initialIndex);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // PageController는 PostController에서 관리하므로 여기서 dispose할 필요 없음
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 0, // '공고' 탭 인덱스
      backgroundColor: const Color(0xFFEEEFF0), // 배경색을 #EEEFF0로 변경
      body: Column(
        children: [
          // 상단 고정 영역
          PostTabBar(
            tabController: _tabController,
            tabTitles: tabTitles,
          ),

          // 필터 행 위젯
          FilterRowWidget(
            tabController: _tabController,
          ),

          // 스크롤 가능한 콘텐츠 영역
          Expanded(
            child: PageView.builder(
              // 직접 생성하지 않고 PostController의 pageController 사용
              controller: _postController.pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
                // PageView에서의 페이지 변경을 컨트롤러에 알림
                _postController.onPageChanged(index);
              },
              itemCount: tabTitles.length,
              itemBuilder: (context, index) {
                // GetX를 사용하여 상태 변화 감지 및 UI 업데이트
                return Obx(() {
                  List<Contest> filteredContests =
                      _postController.getFilteredContentsByTabIndex(index);
                  return PostGrid(contests: filteredContests);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
