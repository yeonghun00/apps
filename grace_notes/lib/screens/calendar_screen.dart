import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/sermon_note.dart';
import '../models/devotion_note.dart';
import '../services/storage_service.dart';
import 'sermon_note_detail_screen.dart';
import 'devotion_note_detail_screen.dart';
import 'sermon_note_form_screen.dart';
import 'devotion_note_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<SermonNote> _sermonNotes = [];
  List<DevotionNote> _devotionNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadNotes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotes();
    }
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always reload when widget updates (e.g., when MainScreen refreshes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sermonNotes = await StorageService.getSermonNotes();
      final devotionNotes = await StorageService.getDevotionNotes();

      setState(() {
        _sermonNotes = sermonNotes;
        _devotionNotes = devotionNotes;
        _isLoading = false;
      });

      // Force update the selected events with fresh data
      final newEvents = _getEventsForDay(_selectedDay!);
      _selectedEvents.value = List.from(newEvents);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final events = <dynamic>[];

    // Add sermon notes for this day
    for (final note in _sermonNotes) {
      if (isSameDay(note.date, day)) {
        events.add(note);
      }
    }

    // Add devotion notes for this day
    for (final note in _devotionNotes) {
      if (isSameDay(note.date, day)) {
        events.add(note);
      }
    }

    return events;
  }

  bool _hasEventsForDay(DateTime day) {
    return _getEventsForDay(day).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: const Text(
          '캘린더',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                const SizedBox(height: 8),
                Expanded(
                  child: ValueListenableBuilder<List<dynamic>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      return _buildEventsList(value);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: TableCalendar<dynamic>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _selectedEvents.value = _getEventsForDay(selectedDay);
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(
            color: AppTheme.softGray,
          ),
          holidayTextStyle: const TextStyle(
            color: AppTheme.softGray,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryPurple,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.sageGreen.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerDecoration: const BoxDecoration(
            color: AppTheme.mint,
            shape: BoxShape.circle,
          ),
          markersAlignment: Alignment.bottomCenter,
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.primaryPurple,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          formatButtonTextStyle: TextStyle(
            color: AppTheme.white,
            fontSize: 12,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppTheme.primaryPurple,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppTheme.primaryPurple,
          ),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;

            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  Color color = AppTheme.mint;
                  if (event is SermonNote) {
                    color = AppTheme.primaryPurple;
                  } else if (event is DevotionNote) {
                    color = AppTheme.sageGreen;
                  }

                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsList(List<dynamic> events) {
    if (events.isEmpty) {
      return SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lavender.withValues(alpha: 0.15),
                AppTheme.cream.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lavender.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lavender.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lavender.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 32,
                  color: AppTheme.lavender,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                DateFormat('M월 d일').format(_selectedDay!),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이 날엔 아직 기록이 없어요 💜',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.softGray,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SermonNoteFormScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadNotes(); // Refresh calendar data
                        }
                      },
                      icon: const Icon(Icons.church, size: 18),
                      label: const Text(
                        '설교노트',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lavender,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.lavender.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DevotionNoteFormScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadNotes(); // Refresh calendar data
                        }
                      },
                      icon: const Icon(Icons.auto_stories, size: 18),
                      label: const Text(
                        '큐티노트',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sageGreen,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.sageGreen.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('events_${events.length}_${events.hashCode}'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        if (event is SermonNote) {
          return _buildSermonNoteCard(event);
        } else if (event is DevotionNote) {
          return _buildDevotionNoteCard(event);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSermonNoteCard(SermonNote note) {
    return GestureDetector(
      key: ValueKey(
          'sermon_${note.id}_${note.updatedAt.millisecondsSinceEpoch}'),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SermonNoteDetailScreen(note: note),
          ),
        );
        // Always refresh calendar when returning from detail screen
        _loadNotes();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.church,
                      color: AppTheme.primaryPurple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isNotEmpty ? note.title : '제목 없음',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${note.church} • ${note.preacher}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.softGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.softGray,
                    size: 14,
                  ),
                ],
              ),
              if (note.scriptureReference.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sageGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.scriptureReference,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.sageGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (note.personalReflection.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.personalReflection,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevotionNoteCard(DevotionNote note) {
    return GestureDetector(
      key: ValueKey(
          'devotion_${note.id}_${note.updatedAt.millisecondsSinceEpoch}'),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DevotionNoteDetailScreen(note: note),
          ),
        );
        // Always refresh calendar when returning from detail screen
        _loadNotes();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.sageGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: AppTheme.sageGreen,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title.isNotEmpty
                              ? note.title
                              : (note.scriptureReference.isNotEmpty
                                  ? note.scriptureReference
                                  : '큐티노트'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '큐티 • ${DateFormat('HH:mm').format(note.date)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.softGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.softGray,
                    size: 14,
                  ),
                ],
              ),
              if (note.scriptureReference.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sageGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.scriptureReference,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.sageGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (note.application.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.application,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
