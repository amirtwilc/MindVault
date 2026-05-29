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
import '../providers/reminder_provider.dart';
import '../providers/jots_provider.dart';
import '../providers/ai_search_provider.dart'
    show aiHistoryIsolationProvider, aiSearchHistoryProvider;
import '../providers/widget_sync_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/pin_setup_screen.dart';
import '../screens/auth/pin_entry_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/all_notes_screen.dart';
import '../screens/home/jots_screen.dart';
import '../screens/home/jot_reminder_resolver_screen.dart';
import '../screens/home/spark_digest_resolver_screen.dart';
import '../screens/home/notes_list_screen.dart';
import '../screens/home/note_editor_screen.dart';
import '../screens/home/search_screen.dart';
import '../screens/home/ai_search_history_screen.dart';
import '../screens/home/settings_screen.dart';
import '../screens/widget/widget_category_notes_screen.dart';
import '../screens/widget/widget_compose_screen.dart';
import '../screens/widget/widget_jot_compose_screen.dart';
import '../screens/widget/widget_note_view_screen.dart';
import '../screens/widget/widget_search_screen.dart';
import '../screens/home/reminder_note_resolver_screen.dart';
import '../widgets/app_walkthrough_overlay.dart';
import '../widgets/mindvault_nav_icons.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      if (state.uri.scheme == 'mindvault' &&
          state.uri.host == 'reminder' &&
          state.uri.path == '/note') {
        final noteId = state.uri.queryParameters['id'];
        if (noteId != null && noteId.isNotEmpty) {
          return Uri(
            path: '/reminder-note',
            queryParameters: {'id': noteId},
          ).toString();
        }
      }
      if (state.uri.scheme == 'mindvault' &&
          state.uri.host == 'jot' &&
          state.uri.path == '/reminder') {
        final jotId = state.uri.queryParameters['id'];
        if (jotId != null && jotId.isNotEmpty) {
          return Uri(
            path: '/jot-reminder',
            queryParameters: {'id': jotId},
          ).toString();
        }
      }
      if (state.uri.scheme == 'mindvault' && state.uri.host == 'spark-digest') {
        return '/spark-digest';
      }

      final authState = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = authState?.session != null ||
          Supabase.instance.client.auth.currentSession != null;
      final isPasswordRecovery =
          authState?.event == AuthChangeEvent.passwordRecovery;

      final location = state.uri.path;

      if (location == '/splash') return null;

      if (!isLoggedIn) {
        if (location == '/reminder-note') return null;
        if (location == '/jot-reminder') return null;
        if (location == '/spark-digest') return null;
        if (location != '/auth') return '/auth';
        return null;
      }

      if (isPasswordRecovery) {
        if (location != '/auth') return '/auth';
        return null;
      }

      final encryptionState = ref.read(encryptionReadyProvider);
      if (encryptionState.isLoading) return null;
      final encryptionReady = encryptionState.valueOrNull ?? false;

      if (!encryptionReady && location != '/pin-setup') {
        if (location == '/reminder-note') return null;
        if (location == '/jot-reminder') return null;
        if (location == '/spark-digest') return null;
        return '/pin-setup';
      }

      if (encryptionReady &&
          (location == '/auth' || location == '/pin-setup')) {
        return '/home/archive';
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
        redirect: (_, state) => Uri(
          path: '/new-memory',
          queryParameters: state.uri.queryParameters,
        ).toString(),
      ),
      GoRoute(
        path: '/new-memory',
        builder: (_, state) => WidgetComposeScreen(
          initialCategoryId: state.uri.queryParameters['categoryId'],
        ),
      ),
      GoRoute(
        path: '/new-jot',
        redirect: (_, __) => '/new-spark',
      ),
      GoRoute(
        path: '/new-spark',
        builder: (_, __) => const WidgetJotComposeScreen(),
      ),
      // Deep link from home widget note row tap
      GoRoute(
        path: '/view-note',
        redirect: (_, state) => Uri(
          path: '/view-memory',
          queryParameters: state.uri.queryParameters,
        ).toString(),
      ),
      GoRoute(
        path: '/view-memory',
        builder: (_, state) => WidgetNoteViewScreen(
          noteId: state.uri.queryParameters['id'] ?? '',
          initialTitle: state.uri.queryParameters['title'],
        ),
      ),
      // Deep link from categories widget category row tap
      GoRoute(
        path: '/category-notes',
        redirect: (_, state) => Uri(
          path: '/cluster-memories',
          queryParameters: state.uri.queryParameters,
        ).toString(),
      ),
      GoRoute(
        path: '/cluster-memories',
        builder: (_, state) => WidgetCategoryNotesScreen(
          categoryId: state.uri.queryParameters['categoryId'] ?? '',
          initialName: state.uri.queryParameters['name'],
        ),
      ),
      // Deep link from home widget search button
      GoRoute(
        path: '/widget-search',
        redirect: (_, __) => '/widget-recall',
      ),
      GoRoute(
        path: '/widget-recall',
        builder: (_, __) => const WidgetSearchScreen(),
      ),
      GoRoute(
        path: '/reminder-note',
        builder: (_, state) => ReminderNoteResolverScreen(
          noteId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/jot-reminder',
        builder: (_, state) => JotReminderResolverScreen(
          jotId: state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/spark-digest',
        builder: (_, __) => const SparkDigestResolverScreen(),
      ),
      // Note editor — outside shell so bottom nav is hidden while editing
      GoRoute(
        path: '/home/clusters/:categoryId/edit',
        builder: (_, state) => NoteEditorScreen(
          categoryId: state.pathParameters['categoryId']!,
          returnToAllNotesOnBack:
              state.uri.queryParameters['fromReminder'] == 'true',
        ),
      ),
      GoRoute(
        path: '/home/clusters/:categoryId/edit/:noteId',
        builder: (_, state) => NoteEditorScreen(
          categoryId: state.pathParameters['categoryId']!,
          noteId: state.pathParameters['noteId'],
          returnToAllNotesOnBack:
              state.uri.queryParameters['fromReminder'] == 'true',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home/clusters',
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
            path: '/home/archive',
            builder: (_, __) => const AllNotesScreen(),
          ),
          GoRoute(
            path: '/home/sparks',
            builder: (_, state) => JotsScreen(
              highlightJotId: state.uri.queryParameters['highlight'],
            ),
          ),
          GoRoute(
            path: '/home/recall',
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
          GoRoute(
            path: '/home/all-notes',
            redirect: (_, __) => '/home/archive',
          ),
          GoRoute(
            path: '/home/jots',
            redirect: (_, state) => Uri(
              path: '/home/sparks',
              queryParameters: state.uri.queryParameters,
            ).toString(),
          ),
          GoRoute(
            path: '/home/categories',
            redirect: (_, __) => '/home/clusters',
          ),
          GoRoute(
            path: '/home/categories/:categoryId',
            redirect: (_, state) =>
                '/home/clusters/${state.pathParameters['categoryId']}',
          ),
          GoRoute(
            path: '/home/categories/:categoryId/edit',
            redirect: (_, state) => Uri(
              path: '/home/clusters/${state.pathParameters['categoryId']}/edit',
              queryParameters: state.uri.queryParameters,
            ).toString(),
          ),
          GoRoute(
            path: '/home/categories/:categoryId/edit/:noteId',
            redirect: (_, state) => Uri(
              path:
                  '/home/clusters/${state.pathParameters['categoryId']}/edit/${state.pathParameters['noteId']}',
              queryParameters: state.uri.queryParameters,
            ).toString(),
          ),
          GoRoute(
            path: '/home/search',
            redirect: (_, __) => '/home/recall',
          ),
          GoRoute(
            path: '/home/search/history',
            redirect: (_, __) => '/home/recall/history',
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
  late final Map<WalkthroughTarget, GlobalKey> _walkthroughTargetKeys;
  int _currentPage = 0;
  int? _programmaticTargetPage;

  Future<void> _syncPendingOps() async {
    await ref.read(categoriesProvider.notifier).syncPendingCategoryOps();
    await ref.read(noteRepositoryProvider)?.syncPendingOps();
    await ref.read(reminderRepositoryProvider)?.syncPendingOps();
    await ref.read(jotRepositoryProvider)?.syncPendingOps();
  }

  void _refreshOnResume() {
    ref.invalidate(allNotesProvider);
    ref.invalidate(notesByCategoryProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(aiSearchHistoryProvider);
    ref.invalidate(unhandledJotsProvider);
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
    _walkthroughTargetKeys = {
      WalkthroughTarget.archive: GlobalKey(debugLabel: 'walkthrough_archive'),
      WalkthroughTarget.sparks: GlobalKey(debugLabel: 'walkthrough_sparks'),
      WalkthroughTarget.clusters: GlobalKey(debugLabel: 'walkthrough_clusters'),
      WalkthroughTarget.recall: GlobalKey(debugLabel: 'walkthrough_recall'),
    };
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
      location.startsWith('/home/clusters/') ||
      location.startsWith('/home/categories/');

  bool _isJotsPage(String location) =>
      location.startsWith('/home/sparks') || location.startsWith('/home/jots');

  bool _isSearchSubPage(String location) =>
      location.startsWith('/home/recall/') ||
      location.startsWith('/home/search/');

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final bottomNavLabelStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 11);

    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOnline = prev?.valueOrNull ?? true;
      final isOnline = next.valueOrNull ?? true;
      if (isOnline && !wasOnline) _syncPendingOps();
    });
    ref.watch(widgetSyncProvider);
    ref.watch(aiHistoryIsolationProvider);
    ref.watch(reminderStartupProvider);

    final location = GoRouterState.of(context).uri.path;
    return Stack(
      children: [
        Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (page) {
              if (_programmaticTargetPage != null) {
                if (page == _programmaticTargetPage) {
                  _programmaticTargetPage = null;
                }
                return;
              }
              setState(() => _currentPage = page);
              _navigate(context, page);
            },
            children: [
              const AllNotesScreen(),
              _isJotsPage(location) ? widget.child : const JotsScreen(),
              _isCategoriesSubPage(location)
                  ? widget.child
                  : const HomeScreen(),
              _isSearchSubPage(location) ? widget.child : const SearchScreen(),
              const SettingsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            labelTextStyle:
                WidgetStatePropertyAll<TextStyle?>(bottomNavLabelStyle),
            destinations: [
              NavigationDestination(
                key: _walkthroughTargetKeys[WalkthroughTarget.archive],
                icon: const MindVaultNavIcon(
                  kind: MindVaultNavIconKind.archive,
                ),
                label: l.navAllNotes,
              ),
              NavigationDestination(
                key: _walkthroughTargetKeys[WalkthroughTarget.sparks],
                icon: const MindVaultNavIcon(
                  kind: MindVaultNavIconKind.sparks,
                ),
                label: l.navJots,
              ),
              NavigationDestination(
                key: _walkthroughTargetKeys[WalkthroughTarget.clusters],
                icon: const MindVaultNavIcon(
                  kind: MindVaultNavIconKind.clusters,
                ),
                label: l.navCategories,
              ),
              NavigationDestination(
                key: _walkthroughTargetKeys[WalkthroughTarget.recall],
                icon: const Icon(Icons.search),
                label: l.navSearch,
              ),
              NavigationDestination(
                  icon: const Icon(Icons.settings), label: l.navSettings),
            ],
            selectedIndex: _currentPage,
            onDestinationSelected: _selectPage,
          ),
        ),
        AppWalkthroughOverlay(
          targetKeys: _walkthroughTargetKeys,
          onNavigateToSection: (page) => _selectPage(page, animate: false),
        ),
      ],
    );
  }

  void _selectPage(int index, {bool animate = true}) {
    setState(() => _currentPage = index);
    _navigate(context, index);
    _programmaticTargetPage = index;
    if (!_pageController.hasClients) return;
    if (!animate) {
      _pageController.jumpToPage(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _programmaticTargetPage = null;
      });
      return;
    }
    _pageController
        .animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )
        .then((_) {
      if (mounted) _programmaticTargetPage = null;
    });
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home/sparks') ||
        location.startsWith('/home/jots')) {
      return 1;
    }
    if (location.startsWith('/home/clusters') ||
        location.startsWith('/home/categories')) {
      return 2;
    }
    if (location.startsWith('/home/recall') ||
        location.startsWith('/home/search')) {
      return 3;
    }
    if (location.startsWith('/home/settings')) return 4;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/archive');
      case 1:
        context.go('/home/sparks');
      case 2:
        context.go('/home/clusters');
      case 3:
        context.go('/home/recall');
      case 4:
        context.go('/home/settings');
    }
  }
}
