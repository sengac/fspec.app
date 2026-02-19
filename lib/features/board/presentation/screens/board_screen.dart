/// Feature: spec/features/kanban-board-view.feature
///
/// Kanban Board screen - displays fspec workflow columns with work units.
/// Supports horizontal swipe between columns and pull-to-refresh.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/board_data.dart';
import '../../data/providers/board_providers.dart';
import '../widgets/board_column.dart';

/// Kanban Board screen widget
///
/// Displays 7 workflow columns (Backlog, Specifying, Testing, Implementing,
/// Validating, Done, Blocked) with work unit cards. Supports:
/// - Horizontal swipe navigation between columns
/// - Vertical scroll within columns
/// - Pull-to-refresh to reload data
/// - Connection lost banner with retry
class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({
    super.key,
    required this.instanceId,
  });

  final String instanceId;

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(boardProvider(widget.instanceId).notifier).refresh();
  }

  void _onRetry() {
    ref.read(boardProvider(widget.instanceId).notifier).retry();
  }

  void _onWorkUnitTap(WorkUnit workUnit) {
    context.push('/work-unit/${widget.instanceId}/${workUnit.id}');
  }

  void _onStartSession() {
    // Generate a new session ID
    final sessionId = const Uuid().v4();
    context.push('/stream/${widget.instanceId}/$sessionId');
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(boardProvider(widget.instanceId));
    final notifier = ref.watch(boardProvider(widget.instanceId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onStartSession,
        icon: const Icon(Icons.chat),
        label: const Text('Chat'),
      ),
      body: Column(
        children: [
          // Connection lost banner
          if (notifier.isConnectionLost)
            Container(
              key: const Key('connection_lost_banner'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection lost',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          // Board content
          Expanded(
            child: boardAsync.when(
              data: (boardData) => _BoardContent(
                boardData: boardData,
                pageController: _pageController,
                currentPage: _currentPage,
                onPageChanged: _onPageChanged,
                onRefresh: _onRefresh,
                onWorkUnitTap: _onWorkUnitTap,
              ),
              loading: () => const Center(
                key: Key('board_loading'),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load board',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardContent extends StatelessWidget {
  const _BoardContent({
    required this.boardData,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onRefresh,
    required this.onWorkUnitTap,
  });

  final BoardData boardData;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onRefresh;
  final void Function(WorkUnit) onWorkUnitTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page indicators
        _PageIndicators(
          currentPage: currentPage,
          pageCount: boardColumnInfos.length,
        ),
        // Board columns with PageView
        Expanded(
          child: RefreshIndicator(
            key: const Key('board_refresh_indicator'),
            onRefresh: onRefresh,
            child: PageView.builder(
              key: const Key('board_page_view'),
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: boardColumnInfos.length,
              itemBuilder: (context, index) {
                final columnInfo = boardColumnInfos[index];
                final workUnits = columnInfo.getWorkUnits(boardData.columns);
                return BoardColumn(
                  columnInfo: columnInfo,
                  workUnits: workUnits,
                  onWorkUnitTap: onWorkUnitTap,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('page_indicators'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          return Container(
            key: Key('page_indicator_$index'),
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
