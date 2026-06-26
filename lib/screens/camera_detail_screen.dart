import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../services/camera_service.dart';
import '../models/camera_model.dart';
import '../core/di/injection.dart';
import '../core/router/app_routes.dart';
import '../features/camera/widgets/camera_history_section.dart';
import '../features/camera/widgets/camera_timeline_selector.dart';
import '../features/camera/widgets/camera_thumbnail_header.dart';
import '../features/camera/widgets/camera_delete_dialog.dart';
import '../features/camera/widgets/camera_calendar_dialog.dart';

class CameraDetailScreen extends StatefulWidget {
  final Camera camera;
  const CameraDetailScreen({super.key, required this.camera});

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  final CameraService _cameraService = CameraService();
  final ScrollController _listController = ScrollController();
  late String _currentCameraName;

  DateTime _selectedDate = DateTime.now();
  int? _selectedHour;
  int? _selectedMinute;
  List<String> _minuteFolders = [];
  int? _currentlyExpandedIndex;

  final Map<String, List<Map<String, dynamic>>> _loadedImagesCache = {};
  final Map<String, bool> _isLoadingMap = {};
  Timer? _autoRefreshTimer;

  final Set<String> _datesWithRecords = {};
  final Map<int, int> _hoursWithRecords = {};
  final Map<int, int> _minutesWithRecords = {};

  @override
  void initState() {
    super.initState();
    _currentCameraName = widget.camera.name;
    final now = DateTime.now();
    _selectedHour = now.hour;
    _selectedMinute = now.minute;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailableDates();
      _fetchAvailableHours();
      if (_selectedHour != null) _fetchAvailableMinutes();
    });

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _performAutoRefresh(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _performAutoRefresh() async {
    if (!mounted || !DateUtils.isSameDay(_selectedDate, DateTime.now())) return;
    if (_selectedHour != null) await _fetchAvailableMinutes(isBackground: true);
    if (_currentlyExpandedIndex != null && _selectedHour != null) {
      if (_currentlyExpandedIndex! < _minuteFolders.length) {
        await _fetchImagesForMinute(
          _selectedHour.toString().padLeft(2, '0'),
          _minuteFolders[_currentlyExpandedIndex!],
          forceRefresh: true,
          isBackground: true,
        );
      }
    }
  }

  Future<void> _fetchAvailableDates() async {
    final token = await AppLocator.instance.sessionService.getAccessToken();
    if (token == null) return;
    final result = await _cameraService.getHistoryStats(
      token,
      widget.camera.id.toString(),
    );
    if (result['items'] != null && mounted) {
      setState(() {
        _datesWithRecords.clear();
        for (var item in result['items']) {
          if (item['date_raw'] != null) _datesWithRecords.add(item['date_raw']);
        }
      });
    }
  }

  Future<void> _fetchAvailableHours() async {
    setState(() => _hoursWithRecords.clear());
    final token = await AppLocator.instance.sessionService.getAccessToken();
    if (token == null) return;
    final result = await _cameraService.getHistoryStats(
      token,
      widget.camera.id.toString(),
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    if (result['items'] != null && mounted) {
      setState(() {
        for (var item in result['items']) {
          final h = int.tryParse(item['hour_raw']?.toString() ?? '');
          if (h != null)
            _hoursWithRecords[h] =
                int.tryParse(item['count']?.toString() ?? '0') ?? 0;
        }
      });
    }
  }

  Future<void> _fetchAvailableMinutes({bool isBackground = false}) async {
    if (_selectedHour == null) return;
    if (!isBackground) setState(() => _minutesWithRecords.clear());
    final token = await AppLocator.instance.sessionService.getAccessToken();
    if (token == null) return;
    final result = await _cameraService.getHistoryStats(
      token,
      widget.camera.id.toString(),
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      hour: _selectedHour.toString().padLeft(2, '0'),
    );
    if (result['items'] != null && mounted) {
      setState(() {
        if (isBackground) _minutesWithRecords.clear();
        for (var item in result['items']) {
          final m = int.tryParse(item['minute_raw']?.toString() ?? '');
          if (m != null)
            _minutesWithRecords[m] =
                int.tryParse(item['count']?.toString() ?? '0') ?? 0;
        }
      });
      if (!isBackground) _updateMinuteFoldersAndList();
    } else if (!isBackground) {
      _updateMinuteFoldersAndList();
    }
  }

  void _updateMinuteFoldersAndList() {
    if (_selectedHour == null) return;
    if (_selectedMinute != null) {
      final minuteString = _selectedMinute!.toString().padLeft(2, '0');
      _minuteFolders = [minuteString];
      _currentlyExpandedIndex = 0;
      _fetchImagesForMinute(
        _selectedHour.toString().padLeft(2, '0'),
        minuteString,
      );
    } else {
      _minuteFolders = List.generate(60, (m) => m.toString().padLeft(2, '0'));
      _currentlyExpandedIndex = null;
    }
    setState(() {});
  }

  Future<void> _handleDateSelection() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => CameraCalendarDialog(
        initialDate: _selectedDate,
        datesWithRecords: _datesWithRecords,
      ),
    );
    if (picked != null && !DateUtils.isSameDay(picked, _selectedDate)) {
      setState(() {
        _selectedDate = picked;
        _loadedImagesCache.clear();
        _selectedHour = null;
        _selectedMinute = null;
        _minuteFolders = [];
        _hoursWithRecords.clear();
        _minutesWithRecords.clear();
      });
      _fetchAvailableHours();
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CameraDeleteDialog(cameraName: _currentCameraName),
    );
    if (confirm == true) _executeDelete();
  }

  Future<void> _executeDelete() async {
    final token = await AppLocator.instance.sessionService.getAccessToken();
    if (token != null) {
      final result = await _cameraService.deleteCamera(
        token,
        widget.camera.id.toString(),
      );
      if (mounted) {
        if (result['success']) {
          context.pop();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  void _editCamera() {
    context.go(
      AppRoutes.editCamera,
      extra: {
        'camera': Camera(
          id: widget.camera.id,
          name: _currentCameraName,
          groupName: widget.camera.groupName,
          isOnline: widget.camera.isOnline,
          description: widget.camera.description,
          deviceId: widget.camera.deviceId,
          groupId: widget.camera.groupId,
          thumbnailUrl: widget.camera.thumbnailUrl,
        ),
      },
    );
  }

  void _applyFilter() {
    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih jam terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _updateMinuteFoldersAndList();
  }

  Future<void> _fetchImagesForMinute(
    String hour,
    String minute, {
    bool forceRefresh = false,
    bool isBackground = false,
  }) async {
    final cacheKey = '$hour:$minute';
    if (!forceRefresh &&
        (_loadedImagesCache.containsKey(cacheKey) ||
            (_isLoadingMap[cacheKey] ?? false)))
      return;
    if (!isBackground) setState(() => _isLoadingMap[cacheKey] = true);
    final token = await AppLocator.instance.sessionService.getAccessToken();
    if (token != null) {
      final images = await _cameraService.getHistoryImages(
        token: token,
        cameraId: widget.camera.id.toString(),
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        hour: hour,
        minute: minute,
      );
      if (mounted) {
        setState(() {
          _loadedImagesCache[cacheKey] = images;
          _isLoadingMap[cacheKey] = false;
        });
      }
    } else {
      setState(() => _isLoadingMap[cacheKey] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCameraName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) =>
                val == 'edit' ? _editCamera() : _confirmDelete(),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          CameraThumbnailHeader(camera: widget.camera),
          CameraTimelineSelector(
            selectedDate: _selectedDate,
            selectedHour: _selectedHour,
            selectedMinute: _selectedMinute,
            hoursWithRecords: _hoursWithRecords,
            minutesWithRecords: _minutesWithRecords,
            onDateTap: _handleDateSelection,
            onHourChanged: (v) {
              setState(() {
                _selectedHour = v;
                _selectedMinute = null;
              });
              _fetchAvailableMinutes();
            },
            onMinuteChanged: (v) {
              setState(() => _selectedMinute = v);
              _updateMinuteFoldersAndList();
            },
            onApply: _applyFilter,
          ),
          Expanded(
            child: _selectedHour == null
                ? const Center(
                    child: Text(
                      "Silakan pilih Jam terlebih dahulu untuk melihat rekaman.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : CameraHistorySection(
                    controller: _listController,
                    minuteFolders: _minuteFolders,
                    selectedHour: _selectedHour!,
                    minutesWithRecords: _minutesWithRecords,
                    currentlyExpandedIndex: _currentlyExpandedIndex,
                    loadedImagesCache: _loadedImagesCache,
                    isLoadingMap: _isLoadingMap,
                    cameraName: widget.camera.name,
                    onExpansionChanged: (index, expanded) {
                      if (expanded) {
                        setState(() {
                          _currentlyExpandedIndex = index;
                          _fetchImagesForMinute(
                            _selectedHour!.toString().padLeft(2, '0'),
                            _minuteFolders[index],
                          );
                        });
                      } else {
                        setState(() => _currentlyExpandedIndex = null);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
