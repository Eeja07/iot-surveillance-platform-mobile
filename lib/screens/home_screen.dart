import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/camera_service.dart';
import '../models/camera_model.dart';
import '../utils/toast_utils.dart';
import '../core/di/providers.dart';
import '../core/router/app_routes.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
import '../features/dashboard/widgets/camera_group_card.dart';
import '../features/dashboard/widgets/camera_tile.dart';
import '../features/dashboard/widgets/dashboard_loading.dart';
import '../features/dashboard/widgets/dashboard_error.dart';
import '../features/dashboard/widgets/dashboard_empty.dart';
import '../features/dashboard/widgets/dashboard_search_bar.dart';
import '../features/dashboard/widgets/dashboard_header.dart';
import '../features/dashboard/widgets/dashboard_dialogs.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final ValueNotifier<bool>? refreshNotifier;

  const HomeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.refreshNotifier,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CameraService _cameraService = CameraService();

  bool _isDeleting = false;
  Timer? _statusRefreshTimer;
  Timer? _thumbnailRefreshTimer;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchCamerasFromApi(isSilent: true);
  }

  @override
  void initState() {
    super.initState();
    _fetchCamerasFromApi();
    widget.refreshNotifier?.addListener(_handleRefreshSignal);

    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchCamerasFromApi(isSilent: true);
      }
    });

    _thumbnailRefreshTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) {
      if (mounted) {
        _refreshThumbnails();
      }
    });

    Future.delayed(const Duration(seconds: 2), () => _refreshThumbnails());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    _thumbnailRefreshTimer?.cancel();
    widget.refreshNotifier?.removeListener(_handleRefreshSignal);
    _searchController.dispose();
    super.dispose();
  }

  void _handleRefreshSignal() {
    _fetchCamerasFromApi();
    _refreshThumbnails();
  }

  void _onSearchChanged() {
    ref.read(dashboardProvider.notifier).setSearch(_searchController.text);
  }

  Future<void> _refreshThumbnails() async {
    final sessionService = ref.read(sessionServiceProvider);
    final token = await sessionService.getAccessToken();
    if (token == null) return;

    final groups = ref.read(dashboardProvider).valueOrNull?.groups ?? [];
    for (var group in groups) {
      for (var cam in group.cameras) {
        try {
          final newUrl = await _cameraService.getLatestImage(
            token,
            cam.id.toString(),
          );
          if (newUrl != null && mounted) {
            ref
                .read(dashboardProvider.notifier)
                .updateThumbnail(cam.id as int, newUrl);
          }
        } catch (e) {
          // Ignored
        }
      }
    }
  }

  Future<void> _fetchCamerasFromApi({bool isSilent = false}) async {
    try {
      await ref.read(dashboardProvider.notifier).refresh(isSilent: isSilent);
    } catch (e) {
      if (!isSilent && e.toString().contains('UNAUTHORIZED')) {
        _forceLogout();
      }
    }
  }

  void _forceLogout() async {
    final sessionService = ref.read(sessionServiceProvider);
    await sessionService.clearSession();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _refreshData() async {
    await _fetchCamerasFromApi();
    _refreshThumbnails();
  }

  void _deleteGroupProcess(CameraGroup group) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final sessionService = ref.read(sessionServiceProvider);
    final token = await sessionService.getAccessToken();

    if (token != null) {
      final result = await _cameraService.deleteGroupApi(token, group.name);

      if (mounted) {
        context.pop();
        if (result['success']) {
          ToastUtils.show(context, result['message'], isError: false);
          _fetchCamerasFromApi();
        } else {
          ToastUtils.show(context, result['message'], isError: true);
        }
      }
    }
  }

  void _deleteCameraProcess(Camera camera) async {
    setState(() => _isDeleting = true);
    final sessionService = ref.read(sessionServiceProvider);
    final token = await sessionService.getAccessToken();

    if (token != null) {
      final result = await _cameraService.deleteCamera(
        token,
        camera.id.toString(),
      );

      if (mounted) {
        setState(() => _isDeleting = false);
        if (result['success']) {
          ToastUtils.show(context, result['message'], isError: false);
          _fetchCamerasFromApi();
        } else {
          ToastUtils.show(context, result['message'], isError: true);
        }
      }
    } else {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildCameraListContent(List<CameraGroup> groups) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];

          if (group.name == 'Tanpa Grup' || group.id == null) {
            return _buildUngroupedSection(group);
          }
          return CameraGroupCard(
            group: group,
            forceExpanded: _isSearching,
            onToggleExpanded: () =>
                setState(() => group.isExpanded = !group.isExpanded),
            onMenuPressed: () {
              DashboardDialogs.showGroupMenu(
                context: context,
                group: group,
                onEdit: () {
                  context.go(
                    AppRoutes.editGroup,
                    extra: {
                      'group': group,
                      'onSave': (bool shouldRefresh) {
                        if (shouldRefresh) _fetchCamerasFromApi();
                      },
                    },
                  );
                },
                onDelete: () {
                  DashboardDialogs.showDeleteGroupConfirmation(
                    context: context,
                    group: group,
                    onConfirm: () => _deleteGroupProcess(group),
                  );
                },
              );
            },
            onCameraLongPress: (camera) {
              DashboardDialogs.showCameraOptions(
                context: context,
                camera: camera,
                onEdit: () {
                  context.go(AppRoutes.editCamera, extra: {'camera': camera});
                },
                onDelete: () {
                  DashboardDialogs.showDeleteCameraConfirmation(
                    context: context,
                    camera: camera,
                    onConfirm: () => _deleteCameraProcess(camera),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? DashboardSearchBar(controller: _searchController, autofocus: true)
            : const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _searchController.clear();
                ref.read(dashboardProvider.notifier).clearSearch();
                setState(() {
                  _isSearching = false;
                });
              } else {
                setState(() {
                  _isSearching = true;
                });
              }
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              ),
              onPressed: widget.toggleTheme,
              tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          dashboardAsync.when(
            data: (dashboardState) {
              final groups = dashboardState.filteredGroups;

              if (groups.isEmpty) {
                return DashboardEmpty(
                  isSearching: _isSearching,
                  onRefresh: _refreshData,
                );
              }

              return _buildCameraListContent(groups);
            },
            loading: () {
              final currentGroups =
                  dashboardAsync.valueOrNull?.filteredGroups ?? [];
              if (currentGroups.isNotEmpty) {
                return _buildCameraListContent(currentGroups);
              }
              return const DashboardLoading();
            },
            error: (err, stack) {
              final currentGroups =
                  dashboardAsync.valueOrNull?.filteredGroups ?? [];
              if (currentGroups.isNotEmpty) {
                return _buildCameraListContent(currentGroups);
              }
              return DashboardError(
                error: err.toString(),
                onRetry: _refreshData,
              );
            },
          ),
          if (_isDeleting)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: DashboardLoading(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUngroupedSection(CameraGroup group) {
    if (group.cameras.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const DashboardHeader(title: "Kamera Lainnya"),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
          ),
          itemCount: group.cameras.length,
          itemBuilder: (context, index) {
            final camera = group.cameras[index];
            return CameraTile(
              camera: camera,
              onLongPress: () {
                DashboardDialogs.showCameraOptions(
                  context: context,
                  camera: camera,
                  onEdit: () {
                    context.go(AppRoutes.editCamera, extra: {'camera': camera});
                  },
                  onDelete: () {
                    DashboardDialogs.showDeleteCameraConfirmation(
                      context: context,
                      camera: camera,
                      onConfirm: () => _deleteCameraProcess(camera),
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
