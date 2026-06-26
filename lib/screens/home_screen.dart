import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/camera_service.dart';
import '../config/app_colors.dart';
import '../models/camera_model.dart';
import '../utils/toast_utils.dart';
import '../core/di/providers.dart';
import '../core/router/app_routes.dart';
import '../features/dashboard/providers/dashboard_provider.dart';

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
  static final Map<int, String> _thumbnailCache = {};

  List<CameraGroup> _allCameraGroups = [];
  List<CameraGroup> _filteredCameraGroups = [];

  bool _isDeleting = false;

  Timer? _statusRefreshTimer;

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchCamerasFromApi(isSilent: true);
  }

  Timer? _thumbnailRefreshTimer;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

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
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCameraGroups = List.from(_allCameraGroups);
      } else {
        _filteredCameraGroups = [];

        for (var group in _allCameraGroups) {
          bool groupMatch = group.name.toLowerCase().contains(query);

          List<Camera> matchingCameras = group.cameras.where((cam) {
            final nameMatch = cam.name.toLowerCase().contains(query);
            final descMatch =
                cam.description != null &&
                cam.description!.toLowerCase().contains(query);
            return nameMatch || descMatch;
          }).toList();

          if (groupMatch || matchingCameras.isNotEmpty) {
            _filteredCameraGroups.add(
              CameraGroup(
                id: group.id,
                name: group.name,
                cameras: groupMatch ? group.cameras : matchingCameras,
                isExpanded: true,
              ),
            );
          }
        }
      }
    });
  }

  Future<void> _refreshThumbnails() async {
    final sessionService = ref.read(sessionServiceProvider);
    final token = await sessionService.getAccessToken();
    if (token == null) return;

    for (var group in _allCameraGroups) {
      for (int i = 0; i < group.cameras.length; i++) {
        final cam = group.cameras[i];

        try {
          final newUrl = await _cameraService.getLatestImage(
            token,
            cam.id.toString(),
          );

          if (newUrl != null && mounted) {
            _thumbnailCache[cam.id] = newUrl;

            setState(() {
              group.cameras[i] = Camera(
                id: cam.id,
                name: cam.name,
                isOnline: cam.isOnline,
                groupName: cam.groupName,
                groupId: cam.groupId,
                deviceId: cam.deviceId,
                description: cam.description,
                thumbnailUrl: newUrl,
              );
            });
          }
        } catch (e) {}
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

  void _showGroupMenu(BuildContext context, CameraGroup group) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Grup'),
              onTap: () {
                context.pop();
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
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Hapus Grup',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                context.pop();
                _showDeleteConfirmationDialog(group);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(CameraGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Grup'),
          content: Text(
            'Hapus grup "${group.name}"?\n'
            'Kamera akan dipindahkan ke "Tanpa Grup".',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => context.pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                context.pop();
                _deleteGroupProcess(group);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showCameraOptions(BuildContext context, Camera camera) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Kamera'),
              onTap: () {
                context.pop();
                context.go(AppRoutes.editCamera, extra: {'camera': camera});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Hapus Kamera',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                context.pop();
                _confirmDeleteCamera(camera);
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCamera(Camera camera) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kamera'),
        content: Text('Hapus kamera "${camera.name}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              context.pop();
              _deleteCameraProcess(camera);
            },
            child: const Text('Hapus'),
          ),
        ],
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
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari kamera atau grup...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              )
            : const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _searchController.clear();
                setState(() {
                  _isSearching = false;
                  _filteredCameraGroups = List.from(_allCameraGroups);
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
              _allCameraGroups = dashboardState.groups;
              final query = _searchController.text.toLowerCase();
              if (query.isEmpty) {
                _filteredCameraGroups = _allCameraGroups;
              } else {
                _filteredCameraGroups = dashboardState.filteredGroups;
              }

              if (_filteredCameraGroups.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _filteredCameraGroups.length,
                  itemBuilder: (context, index) {
                    final group = _filteredCameraGroups[index];

                    if (group.name == 'Tanpa Grup' || group.id == null) {
                      return _buildUngroupedSection(group);
                    }
                    return _buildGroupCard(group, forceExpanded: _isSearching);
                  },
                ),
              );
            },
            loading: () {
              if (_allCameraGroups.isNotEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _filteredCameraGroups.length,
                    itemBuilder: (context, index) {
                      final group = _filteredCameraGroups[index];

                      if (group.name == 'Tanpa Grup' || group.id == null) {
                        return _buildUngroupedSection(group);
                      }
                      return _buildGroupCard(
                        group,
                        forceExpanded: _isSearching,
                      );
                    },
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
            error: (err, stack) {
              if (_allCameraGroups.isNotEmpty) {
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _filteredCameraGroups.length,
                    itemBuilder: (context, index) {
                      final group = _filteredCameraGroups[index];

                      if (group.name == 'Tanpa Grup' || group.id == null) {
                        return _buildUngroupedSection(group);
                      }
                      return _buildGroupCard(
                        group,
                        forceExpanded: _isSearching,
                      );
                    },
                  ),
                );
              }
              return Center(child: Text(err.toString()));
            },
          ),
          // Delete-in-progress overlay
          if (_isDeleting)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? 'Tidak ada kamera yang cocok.'
                : 'Tidak ada kamera ditemukan.',
            style: const TextStyle(color: Colors.grey),
          ),
          if (!_isSearching) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchCamerasFromApi,
              child: const Text('Refresh'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUngroupedSection(CameraGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.cameras.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 8.0),
            child: Text(
              "Kamera Lainnya",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildCameraGrid(group.cameras),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildGroupCard(CameraGroup group, {bool forceExpanded = false}) {
    final isExpanded = forceExpanded || group.isExpanded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildGroupHeader(group),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: _buildCameraList(group.cameras),
            secondChild: _buildCameraGrid(group.cameras),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
          if (!forceExpanded)
            InkWell(
              onTap: () => setState(() => group.isExpanded = !group.isExpanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.grey.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.isExpanded
                          ? 'Tutup (Fold)'
                          : 'Lihat Semua (${group.cameras.length} Total)',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      group.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(CameraGroup group) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 4.0),
      color: Theme.of(context).cardTheme.color?.withAlpha(40),
      child: Row(
        children: [
          Icon(Icons.folder_open, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showGroupMenu(context, group),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraGrid(List<Camera> cameras) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2,
      ),
      itemCount: cameras.length,
      itemBuilder: (context, index) => _buildCameraCard(cameras[index]),
    );
  }

  Widget _buildCameraList(List<Camera> cameras) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cameras.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: _buildCameraCard(cameras[index], isHorizontal: true),
        ),
      ),
    );
  }

  Widget _buildCameraCard(Camera camera, {bool isHorizontal = false}) {
    final double? cardWidth = isHorizontal ? 160 : null;
    final Color statusColor = camera.isOnline
        ? AppColors.success
        : AppColors.danger;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.go(AppRoutes.cameraDetail, extra: {'camera': camera});
          },
          onLongPress: () => _showCameraOptions(context, camera),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Theme.of(context).cardTheme.color?.withAlpha(40),
                child:
                    (camera.thumbnailUrl != null &&
                        camera.thumbnailUrl!.isNotEmpty)
                    ? Image.network(
                        camera.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (ctx, err, stack) => Center(
                          child: Icon(
                            Icons.videocam_off,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.videocam,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Text(
                  camera.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
