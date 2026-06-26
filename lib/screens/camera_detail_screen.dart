import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_viewer_screen.dart';
import 'edit_camera_screen.dart';
import '../services/camera_service.dart';
import '../models/camera_model.dart';

class CameraDetailScreen extends StatefulWidget {
  final Camera camera;

  const CameraDetailScreen({
    super.key,
    required this.camera,
  });

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
  final Map<int, GlobalKey> _itemKeys = {};

  final Map<String, List<Map<String, dynamic>>> _loadedImagesCache = {};
  final Map<String, bool> _isLoadingMap = {};

  bool _hasThumbnailUpdated = false;
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


      if (_selectedHour != null) {
        _fetchAvailableMinutes();
      }
    });


    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _performAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _listController.dispose();
    super.dispose();
  }


  Future<void> _performAutoRefresh() async {
    if (!mounted) return;


    if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) return;


    if (_selectedHour != null) {
      await _fetchAvailableMinutes(isBackground: true);
    }


    if (_currentlyExpandedIndex != null && _selectedHour != null) {

      if (_currentlyExpandedIndex! < _minuteFolders.length) {
        final minuteString = _minuteFolders[_currentlyExpandedIndex!];
        final hourString = _selectedHour.toString().padLeft(2, '0');


        await _fetchImagesForMinute(hourString, minuteString, forceRefresh: true, isBackground: true);
      }
    }
  }


  Future<void> _fetchAvailableDates() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final result = await _cameraService.getHistoryStats(token, widget.camera.id.toString());

    if (result['items'] != null) {
      final List items = result['items'];
      if (mounted) {
        setState(() {
          _datesWithRecords.clear();
          for (var item in items) {
            if (item['date_raw'] != null) {
              _datesWithRecords.add(item['date_raw']);
            }
          }
        });
      }
    }
  }


  Future<void> _fetchAvailableHours() async {
    setState(() => _hoursWithRecords.clear());

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await _cameraService.getHistoryStats(
      token,
      widget.camera.id.toString(),
      date: dateStr
    );

    if (result['items'] != null) {
      final List items = result['items'];
      if (mounted) {
        setState(() {
          for (var item in items) {
            final h = int.tryParse(item['hour_raw']?.toString() ?? '');
            final c = int.tryParse(item['count']?.toString() ?? '0');
            if (h != null) {
              _hoursWithRecords[h] = c ?? 0;
            }
          }
        });
      }
    }
  }



  Future<void> _fetchAvailableMinutes({bool isBackground = false}) async {
    if (_selectedHour == null) return;


    if (!isBackground) {
       setState(() => _minutesWithRecords.clear());
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final hourStr = _selectedHour.toString().padLeft(2, '0');

    final result = await _cameraService.getHistoryStats(
      token,
      widget.camera.id.toString(),
      date: dateStr,
      hour: hourStr
    );

    if (result['items'] != null) {
      final List items = result['items'];
      if (mounted) {
        setState(() {

          if (isBackground) _minutesWithRecords.clear();

          for (var item in items) {
            final m = int.tryParse(item['minute_raw']?.toString() ?? '');
            final c = int.tryParse(item['count']?.toString() ?? '0');
            if (m != null) {
              _minutesWithRecords[m] = c ?? 0;
            }
          }
        });



        if (!isBackground) {
           _updateMinuteFoldersAndList();
        }
      }
    } else {
      if (!isBackground) _updateMinuteFoldersAndList();
    }
  }


  void _updateMinuteFoldersAndList() {
    if (_selectedHour == null) return;

    List<String> newFolders;

    if (_selectedMinute != null) {

      final minuteString = _selectedMinute!.toString().padLeft(2, '0');
      newFolders = [minuteString];


      _currentlyExpandedIndex = 0;
      _fetchImagesForMinute(_selectedHour.toString().padLeft(2, '0'), minuteString);
    } else {

      newFolders = List.generate(60, (m) => m.toString().padLeft(2, '0'));
      _currentlyExpandedIndex = null;
    }

    setState(() {
      _minuteFolders = newFolders;
      _itemKeys.clear();
    });
  }


  Future<void> _handleDateSelection() async {
    DateTime tempDate = _selectedDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _buildCustomCalendarDialog(ctx, tempDate),
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

  Widget _buildCustomCalendarDialog(BuildContext context, DateTime initialDate) {
    DateTime displayDate = initialDate;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        final daysInMonth = DateUtils.getDaysInMonth(displayDate.year, displayDate.month);
        final firstDayOfMonth = DateTime(displayDate.year, displayDate.month, 1);
        final int weekdayOffset = firstDayOfMonth.weekday - 1;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black;
        final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setDialogState(() => displayDate = DateTime(displayDate.year, displayDate.month - 1)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(displayDate),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setDialogState(() => displayDate = DateTime(displayDate.year, displayDate.month + 1)),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            height: 350,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg']
                      .map((d) => SizedBox(
                            width: 30,
                            child: Center(child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: subtitleColor, fontSize: 12)))
                          )).toList(),
                ),
                const SizedBox(height: 10),
                const Divider(),
                Expanded(
                  child: GridView.builder(
                    itemCount: daysInMonth + weekdayOffset,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                    itemBuilder: (context, index) {
                      if (index < weekdayOffset) return const SizedBox();

                      final day = index - weekdayOffset + 1;
                      final date = DateTime(displayDate.year, displayDate.month, day);
                      final dateKey = DateFormat('yyyy-MM-dd').format(date);

                      final hasRecord = _datesWithRecords.contains(dateKey);
                      final isSelected = DateUtils.isSameDay(date, _selectedDate);
                      final isToday = DateUtils.isSameDay(date, DateTime.now());

                      return InkWell(
                        onTap: () => Navigator.pop(context, date),
                        customBorder: const CircleBorder(),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Theme.of(context).primaryColor : (isToday ? Colors.blue.withOpacity(0.1) : null),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isToday ? Colors.blue : textColor),
                                  fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                              if (hasRecord)
                                Positioned(
                                  bottom: 6,
                                  child: Container(
                                    width: 5, height: 5,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 4),
                    Text("= Ada Rekaman", style: TextStyle(fontSize: 12, color: subtitleColor)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kamera'),
        content: Text('Apakah Anda yakin ingin menghapus kamera "$_currentCameraName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) _executeDelete();
  }

  Future<void> _executeDelete() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final result = await _cameraService.deleteCamera(token, widget.camera.id.toString());
      if (mounted) {
        if (result['success']) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    }
  }

  Future<void> _editCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCameraScreen(


          camera: Camera(
            id: widget.camera.id,
            name: _currentCameraName,
            groupName: widget.camera.groupName,
            isOnline: widget.camera.isOnline,
            description: widget.camera.description,
            deviceId: widget.camera.deviceId,
            groupId: widget.camera.groupId,
            thumbnailUrl: widget.camera.thumbnailUrl
          ),
        ),
      ),
    );

    if (result == true) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kamera diperbarui.")));
         Navigator.pop(context, true);
       }
    }
  }

  void _applyFilter() {
    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih jam terlebih dahulu.'), backgroundColor: Colors.orange),
      );
      return;
    }
    _updateMinuteFoldersAndList();
  }


  Future<void> _fetchImagesForMinute(String hour, String minute, {bool forceRefresh = false, bool isBackground = false}) async {
    final cacheKey = '$hour:$minute';



    if (!forceRefresh && (_loadedImagesCache.containsKey(cacheKey) || (_isLoadingMap[cacheKey] ?? false))) {
      return;
    }


    if (!isBackground) {
        setState(() => _isLoadingMap[cacheKey] = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final images = await _cameraService.getHistoryImages(
        token: token,
        cameraId: widget.camera.id.toString(),
        date: dateStr,
        hour: hour,
        minute: minute,
      );

      if (images.isNotEmpty) {
         final String latestImageUrl = images.first['url'];
         await prefs.setString('thumbnail_${widget.camera.id}', latestImageUrl);
         _hasThumbnailUpdated = true;
      }

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
          onPressed: () => Navigator.pop(context, _hasThumbnailUpdated),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editCamera();
              else if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Hapus')])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),

          Expanded(
            child: _selectedHour == null
                ? const Center(child: Text("Silakan pilih Jam terlebih dahulu untuk melihat rekaman.", style: TextStyle(color: Colors.grey)))
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Filter Perekaman", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildFilterRowResponsive(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Tampilkan Rekaman'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRowResponsive() {
    final dateBtn = OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 20),
      label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
      onPressed: _handleDateSelection,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      ),
    );

    final hourDrop = DropdownButtonFormField<int>(
      value: _selectedHour,
      isExpanded: true,
      hint: const Text('Jam'),
      menuMaxHeight: 300,
      items: List.generate(24, (i) {
        final count = _hoursWithRecords[i];
        final hasData = count != null && count > 0;
        return DropdownMenuItem(
          value: i,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(i.toString().padLeft(2, '0')),
              if (hasData)
                const Icon(Icons.circle, size: 8, color: Colors.green),
            ],
          ),
        );
      }),
      onChanged: (v) {
        setState(() {
          _selectedHour = v;
          _selectedMinute = null;
        });
        _fetchAvailableMinutes();
      },
      decoration: const InputDecoration(labelText: 'Jam', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
    );

    final minuteDrop = DropdownButtonFormField<int?>(
      value: _selectedMinute,
      isExpanded: true,
      hint: const Text('Menit'),
      menuMaxHeight: 300,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Semua')),
        ...List.generate(60, (i) {
          final count = _minutesWithRecords[i];
          final hasData = count != null && count > 0;
          return DropdownMenuItem(
            value: i,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i.toString().padLeft(2, '0')),
                if (hasData)
                  const Icon(Icons.circle, size: 8, color: Colors.green),
              ],
            ),
          );
        })
      ],
      onChanged: _selectedHour == null ? null : (v) {
        setState(() => _selectedMinute = v);
        _updateMinuteFoldersAndList();
      },
      decoration: const InputDecoration(labelText: 'Menit', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
    );

    return Column(
      children: [
        SizedBox(width: double.infinity, child: dateBtn),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: hourDrop),
            const SizedBox(width: 12),
            Expanded(child: minuteDrop),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      controller: _listController,
      itemCount: _minuteFolders.length,
      itemBuilder: (context, index) {
        final minuteString = _minuteFolders[index];
        final minuteInt = int.parse(minuteString);
        final hourString = _selectedHour.toString().padLeft(2, '0');

        final countInData = _minutesWithRecords[minuteInt];
        final hasData = countInData != null && countInData > 0;

        final key = _itemKeys.putIfAbsent(index, () => GlobalKey());
        final isExpanded = index == _currentlyExpandedIndex;
        final cacheKey = '$hourString:$minuteString';
        final images = _loadedImagesCache[cacheKey];
        final isLoading = _isLoadingMap[cacheKey] ?? false;

        final iconColor = hasData ? Colors.blue : Colors.grey;

        return ExpansionTile(
          key: key,
          leading: Icon(Icons.folder_outlined, color: iconColor),
          title: Text(
            'Pukul $hourString:$minuteString',
            style: TextStyle(fontWeight: hasData ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(
            images != null
                ? '${images.length} gambar dimuat'
                : (hasData ? '$countInData file tersedia' : '0 file'),
            style: TextStyle(
              fontSize: 12,
              color: hasData
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black54)
                  : Colors.grey
            ),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            if (expanded && hasData) {
              setState(() {
                _currentlyExpandedIndex = index;
                _fetchImagesForMinute(hourString, minuteString);
              });
            } else {
               setState(() => _currentlyExpandedIndex = null);
            }
          },
          children: [
            if (isLoading)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
            else if (images == null || images.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Tidak ada gambar yang dimuat.')))
            else
              _buildImageGrid(images, '$hourString:$minuteString')
          ],
        );
    });
  }

  Widget _buildImageGrid(List<Map<String, dynamic>> images, String titleTime) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageUrl = images[index]['url'];
        return GestureDetector(
          onTap: () {
            final allUrls = images.map((e) => e['url'] as String).toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewerScreen(
                  imageUrls: allUrls,
                  initialIndex: index,
                  title: titleTime,
                  cameraName: widget.camera.name,
                )
              )
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Hero(
              tag: imageUrl,
              child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
            ),
          ),
        );
    });
  }
}