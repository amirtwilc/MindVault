import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/encryption_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/ai_search_provider.dart' show aiHistoryIsolationProvider, aiSearchHistoryProvider;
import '../providers/widget_sync_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/pin_setup_screen.dart';
import '../screens/auth/pin_entry_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/all_notes_screen.dart';
import '../screens/home/notes_list_screen.dart';
import '../screens/home/note_editor_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/home/ai_search_history_screen.dart';
import '../screens/home/settings_screen.dart';
import '../screens/widget/widget_category_notes_screen.dart';
import '../screens/widget/widget_compose_screen.dart';
import '../screens/widget/widget_note_view_screen.dart';
import '../screens/widget/widget_search_screen.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = authState?.session != null ||
          Supabase.instance.client.auth.currentSession != null;

      final location = state.uri.path;

      if (location == '/splash') return null;

      if (!isLoggedIn) {
        if (location != '/auth') return '/auth';
        return null;
      }

      final encryptionState = ref.read(encryptionReadyProvider);
      if (encryptionState.isLoading) return null;
      final encryptionReady = encryptionState.valueOrNull ?? false;

      if (!encryptionReady && location != '/pin-setup') {
        return '/pin-setup';
      }

      if (encryptionReady && (location == '/auth' || location == '/pin-setup')) {
        return '/home/all-notes';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (_, __) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/pin-entry',
        builder: (_, __) => const PinEntryScreen(),
      ),
      // Deep link from home widget "New Note" button
      GoRoute(
        path: '/new-note',
        builder: (_, state) => WidgetComposeScreen(
          initialCategoryId: state.uri.queryParameters['categoryId'],
        ),
      ),
      // Deep link from home widget note row tap
      GoRoute(
        path: '/view-note',
        builder: (_, state) => WidgetNoteViewScreen(
          noteId: state.uri.queryParameters['id'] ?? '',
          initialTitle: state.uri.queryParameters['title'],
        ),
      ),
      // Deep link from categories widget category row tap
      GoRoute(
        path: '/category-notes',
        builder: (_, state) => WidgetCategoryNotesScreen(
          categoryId: state.uri.queryParameters['categoryId'] ?? '',
          initialName: state.uri.queryParameters['name'],
        ),
      ),
      // Deep link from home widget search button
      GoRoute(
        path: '/widget-search',
        builder: (_, __) => const WidgetSearchScreen(),
      ),
      // Note editor — outside shell so bottom nav is hidden while editing
      GoRoute(
        path: '/home/categories/:categoryId/edit',
        builder: (_, state) => NoteEditorScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/home/categories/:categoryId/edit/:noteId',
        builder: (_, state) => NoteEditorScreen(
          categoryId: state.pathParameters['categoryId']!,
          noteId: state.pathParameters['noteId'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home/categories',
            builder: (_, __) => const HomeScreen(),
            routes: [
              GoRoute(
                path: ':categoryId',
                builder: (_, state) => NotesListScreen(
                  categoryId: state.pathParameters['categoryId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/home/all-notes',
            builder: (_, __) => const AllNotesScreen(),
          ),
          GoRoute(
            path: '/home/search',
            builder: (_, __) => const SearchScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (_, __) => const AiSearchHistoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/home/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  final Ref _ref;
  _AuthListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(encryptionReadyProvider, (_, __) => notifyListeners());
  }
}

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _currentPage = 0;
  int? _programmaticTargetPage;

  Future<void> _syncPendingOps() async {
    await ref.read(categoriesProvider.notifier).syncPendingCategoryOps();
    await ref.read(noteRepositoryProvider)?.syncPendingOps();
  }

  void _refreshOnResume() {
    ref.invalidate(allNotesProvider);
    ref.invalidate(notesByCategoryProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(aiSearchHistoryProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOnResume();
      _syncPendingOps();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPendingOps();
      ref.read(analyticsServiceProvider).track('session_started');
      final initial = _selectedIndex(context);
      if (initial != 0 && _pageController.hasClients) {
        _programmaticTargetPage = initial;
        setState(() => _currentPage = initial);
        _pageController.jumpToPage(initial);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _programmaticTargetPage = null;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeIndex = _selectedIndex(context);
    if (routeIndex != _currentPage) {
      _programmaticTargetPage = routeIndex;
      setState(() => _currentPage = routeIndex);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(routeIndex);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _programmaticTargetPage = null;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isCategoriesSubPage(String location) =>
      location.startsWith('/home/categories/');

  bool _isSearchSubPage(String location) =>
      location.startsWith('/home/search/');

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOnline = prev?.valueOrNull ?? true;
      final isOnline = next.valueOrNull ?? true;
      if (isOnline && !wasOnline) _syncPendingOps();
    });

    ref.watch(widgetSyncProvider);
    ref.watch(aiHistoryIsolationProvider);

    final location = GoRouterState.of(context).uri.path;
    final l = AppStrings.of(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          if (_programmaticTargetPage != null) {
            if (page == _programmaticTargetPage) _programmaticTargetPage = null;
            return;
          }
          setState(() => _currentPage = page);
          _navigate(context, page);
        },
        children: [
          const AllNotesScreen(),
          _isCategoriesSubPage(location) ? widget.child : const HomeScreen(),
          _isSearchSubPage(location) ? widget.child : const SearchScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: const Icon(Icons.notes), label: l.navAllNotes),
          NavigationDestination(icon: const Icon(Icons.grid_view), label: l.navCategories),
          NavigationDestination(icon: const Icon(Icons.search), label: l.navSearch),
          NavigationDestination(icon: const Icon(Icons.settings), label: l.navSettings),
        ],
        selectedIndex: _currentPage,
        onDestinationSelected: (i) {
          setState(() => _currentPage = i);
          _navigate(context, i);
          _programmaticTargetPage = i;
          _pageController
              .animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              )
              .then((_) {
            if (mounted) _programmaticTargetPage = null;
          });
        },
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home/categories')) return 1;
    if (location.startsWith('/home/search')) return 2;
    if (location.startsWith('/home/settings')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home/all-notes');
      case 1: context.go('/home/categories');
      case 2: context.go('/home/search');
      case 3: context.go('/home/settings');
    }
  }
}
