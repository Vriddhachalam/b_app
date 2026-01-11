// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';

void main() {
  runApp(const DevotionalSongsApp());
}

class DevotionalSongsApp extends StatelessWidget {
  const DevotionalSongsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devotional Songs',
      theme: ThemeData(
        primaryColor: const Color(0xFF0A4A6E),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A4A6E),
          elevation: 0,
        ),
      ),
      home: const SongsListPage(),
    );
  }
}

// Model class for Song
class Song {
  final String songId;
  final String title;
  final String title2;
  final String lyrics;
  final String meaning;
  final String language;
  final String deity;
  final String raga;
  final String beat;
  final String tempo;
  final String level;
  final List<String> audioLink;
  final List<String> videoLink;
  final String url;
  final String referenceGentsPitch;
  final String referenceLadiesPitch;
  final String notesRange;
  final String songTags;
  final List<String> goldenVoice;

  Song({
    required this.songId,
    required this.title,
    required this.title2,
    required this.lyrics,
    required this.meaning,
    required this.language,
    required this.deity,
    required this.raga,
    required this.beat,
    required this.tempo,
    required this.level,
    required this.audioLink,
    required this.videoLink,
    required this.url,
    required this.referenceGentsPitch,
    required this.referenceLadiesPitch,
    required this.notesRange,
    required this.songTags,
    required this.goldenVoice,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      songId: json['song_id'] ?? '',
      title: json['title'] ?? '',
      title2: json['title2'] ?? '',
      lyrics: json['lyrics'] ?? '',
      meaning: json['meaning'] ?? '',
      language: json['language'] ?? '',
      deity: json['deity'] ?? '',
      raga: json['raga'] ?? '',
      beat: json['beat'] ?? '',
      tempo: json['tempo'] ?? '',
      level: json['level'] ?? '',
      audioLink: List<String>.from(json['audio_link'] ?? []),
      videoLink: List<String>.from(json['video_link'] ?? []),
      url: json['url'] ?? '',
      referenceGentsPitch:
          json['Reference Gents Pitch'] ?? json['reference_gents_pitch'] ?? '',
      referenceLadiesPitch:
          json['Reference Ladies Pitch'] ??
          json['reference_ladies_pitch'] ??
          '',
      notesRange: json['Notes Range'] ?? json['notes_range'] ?? '',
      songTags: json['songtags'] ?? json['Song Tags'] ?? '',
      goldenVoice: List<String>.from(json['golden_voice'] ?? []),
    );
  }
}

// Main Songs List Page
class SongsListPage extends StatefulWidget {
  const SongsListPage({Key? key}) : super(key: key);

  @override
  State<SongsListPage> createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  // ===== Global Bottom Player State =====
  Song? _currentSong;
  html.AudioElement? _globalAudio;
  Duration _globalDuration = Duration.zero;
  Duration _globalPosition = Duration.zero;

  List<Song> allSongs = [];
  List<Song> filteredSongs = [];
  List<Song> paginatedSongs = [];

  final TextEditingController _searchController = TextEditingController();
  String selectedDeity = 'All';
  String selectedLevel = 'All';
  String selectedTempo = 'All';
  String selectedBeat = 'All';
  String selectedLanguage = 'All';
  String selectedRaga = 'All';

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> itemsPerPageOptions = [5, 10, 15, 20, 25];

  // Dynamic filter options
  List<String> deityOptions = ['All'];
  List<String> levelOptions = ['All'];
  List<String> tempoOptions = ['All'];
  List<String> beatOptions = ['All'];
  List<String> languageOptions = ['All'];
  List<String> ragaOptions = ['All'];

  @override
  void initState() {
    super.initState();
    loadSongs();
    _searchController.addListener(_filterSongs);
  }

  Future<void> loadSongs() async {
    try {
      // Load from assets
      final String jsonString = await rootBundle.loadString(
        'sairhythms_full_songs.json',
      );

      final List<dynamic> items = jsonDecode(jsonString);

      allSongs = items.map((json) => Song.fromJson(json)).toList();
      filteredSongs = List.from(allSongs);

      // Extract unique filter values from data
      _extractFilterOptions();

      // Apply pagination
      _updatePagination();

      setState(() {});
    } catch (e) {
      print('Error loading songs: $e');
    }
  }

  void _extractFilterOptions() {
    Set<String> deities = {};
    Set<String> levels = {};
    Set<String> tempos = {};
    Set<String> beats = {};
    Set<String> languages = {};
    Set<String> ragas = {};

    for (var song in allSongs) {
      // Split comma-separated values and add each distinct value
      _addSplitValues(deities, song.deity);
      _addSplitValues(levels, song.level);
      _addSplitValues(tempos, song.tempo);
      _addSplitValues(beats, song.beat);
      _addSplitValues(languages, song.language);
      _addSplitValues(ragas, song.raga);
    }

    // Convert to sorted lists with 'All' at the beginning
    deityOptions = [
      'All',
      ...deities.where((s) => s.isNotEmpty).toList()..sort(),
    ];
    levelOptions = [
      'All',
      ...levels.where((s) => s.isNotEmpty).toList()..sort(),
    ];
    tempoOptions = [
      'All',
      ...tempos.where((s) => s.isNotEmpty).toList()..sort(),
    ];
    beatOptions = ['All', ...beats.where((s) => s.isNotEmpty).toList()..sort()];
    languageOptions = [
      'All',
      ...languages.where((s) => s.isNotEmpty).toList()..sort(),
    ];
    ragaOptions = ['All', ...ragas.where((s) => s.isNotEmpty).toList()..sort()];
  }

  void _addSplitValues(Set<String> set, String value) {
    if (value.isEmpty) return;

    // Split by comma, trim whitespace, and add to set
    value.split(',').forEach((item) {
      final trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        set.add(trimmed);
      }
    });
  }

  bool _containsValue(String fieldValue, String selectedValue) {
    if (selectedValue == 'All') return true;
    if (fieldValue.isEmpty) return false; // Don't match if field is empty

    // Split by comma and check if any value matches (case-insensitive)
    final values = fieldValue.split(',').map((s) => s.trim().toLowerCase());
    return values.contains(selectedValue.toLowerCase());
  }

  void _filterSongs() {
    setState(() {
      filteredSongs = allSongs.where((song) {
        final matchesSearch =
            song.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            song.lyrics.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        // Use _containsValue for SQL-like IN clause matching
        final matchesDeity = _containsValue(song.deity, selectedDeity);
        final matchesLevel = _containsValue(song.level, selectedLevel);
        final matchesTempo = _containsValue(song.tempo, selectedTempo);
        final matchesBeat = _containsValue(song.beat, selectedBeat);
        final matchesLanguage = _containsValue(song.language, selectedLanguage);
        final matchesRaga = _containsValue(song.raga, selectedRaga);

        return matchesSearch &&
            matchesDeity &&
            matchesLevel &&
            matchesTempo &&
            matchesBeat &&
            matchesLanguage &&
            matchesRaga;
      }).toList();

      // Reset to page 1 and update pagination
      currentPage = 1;
      _updatePagination();
    });
  }

  void _updatePagination() {
    totalPages = (filteredSongs.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    // Calculate start and end indices
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredSongs.length);

    // Get paginated songs
    paginatedSongs = filteredSongs.sublist(startIndex, endIndex);
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages) return;
    setState(() {
      currentPage = page;
      _updatePagination();
    });
  }

  void _changeItemsPerPage(int? value) {
    if (value == null) return;
    setState(() {
      itemsPerPage = value;
      currentPage = 1;
      _updatePagination();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      selectedDeity = 'All';
      selectedLevel = 'All';
      selectedTempo = 'All';
      selectedBeat = 'All';
      selectedLanguage = 'All';
      selectedRaga = 'All';
      filteredSongs = allSongs;
      currentPage = 1;
      _updatePagination();
    });
  }

  void _playSongGlobally(Song song) {
    _globalAudio?.pause();

    if (song.audioLink.isEmpty || song.audioLink.first.trim().isEmpty) {
      return;
    }

    final url = song.audioLink.first;

    _globalAudio = html.AudioElement(url)
      ..volume = 1.0
      ..onLoadedMetadata.listen((_) {
        setState(() {
          _globalDuration = Duration(seconds: _globalAudio!.duration.toInt());
        });
      })
      ..onTimeUpdate.listen((_) {
        setState(() {
          _globalPosition = Duration(
            seconds: _globalAudio!.currentTime.toInt(),
          );
        });
      })
      ..onEnded.listen((_) {
        setState(() {
          _globalPosition = Duration.zero;
          _currentSong = null;
        });
      });

    _globalAudio!.play();

    setState(() {
      _currentSong = song;
    });
  }

  void _seekGlobal(double seconds) {
    if (_globalAudio == null) return;
    _globalAudio!.currentTime = seconds;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Devotional Songs'),
            centerTitle: true,
          ),
          body: isMobile
              ? _buildSongsList()
              : Row(
                  children: [
                    Container(
                      width: 300,
                      color: Colors.white,
                      child: _buildFilterSidebar(),
                    ),
                    Expanded(child: _buildSongsList()),
                  ],
                ),
        ),

        if (_currentSong != null)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPlayer()),
      ],
    );
  }

  Widget _buildBottomPlayer() {
    final isPlaying = _globalAudio != null && !_globalAudio!.paused;

    return Material(
      elevation: 12,
      color: Colors.white,
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Song title + Play/Pause
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentSong!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (_globalAudio == null) return;

                    if (_globalAudio!.paused) {
                      _globalAudio!.play();
                    } else {
                      _globalAudio!.pause();
                    }

                    setState(() {});
                  },
                ),
              ],
            ),

            // Timeline + time labels
            Row(
              children: [
                // Current time
                Text(
                  _formatTime(_globalPosition),
                  style: const TextStyle(fontSize: 12),
                ),

                // Slider
                Expanded(
                  child: Slider(
                    value: _globalPosition.inSeconds.toDouble(),
                    min: 0,
                    max: _globalDuration.inSeconds > 0
                        ? _globalDuration.inSeconds.toDouble()
                        : 1,
                    onChanged: (value) {
                      _seekGlobal(value);
                    },
                  ),
                ),

                // Total duration
                Text(
                  _formatTime(_globalDuration),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildFilterSidebar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Devotional Songs',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Search Box
          _buildFilterSection(
            'Lyrics',
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search lyrics...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),

          // Deity Dropdown
          _buildFilterSection(
            'Deity',
            _buildDropdown(
              selectedDeity,
              deityOptions,
              (value) => setState(() {
                selectedDeity = value!;
                _filterSongs();
              }),
            ),
          ),

          // Level Dropdown
          _buildFilterSection(
            'Level',
            _buildDropdown(
              selectedLevel,
              levelOptions,
              (value) => setState(() {
                selectedLevel = value!;
                _filterSongs();
              }),
            ),
          ),

          // Tempo Dropdown
          _buildFilterSection(
            'Tempo',
            _buildDropdown(
              selectedTempo,
              tempoOptions,
              (value) => setState(() {
                selectedTempo = value!;
                _filterSongs();
              }),
            ),
          ),

          // Beat Dropdown
          _buildFilterSection(
            'Beat',
            _buildDropdown(
              selectedBeat,
              beatOptions,
              (value) => setState(() {
                selectedBeat = value!;
                _filterSongs();
              }),
            ),
          ),

          // Raga Dropdown
          _buildFilterSection(
            'Raga',
            _buildDropdown(
              selectedRaga,
              ragaOptions,
              (value) => setState(() {
                selectedRaga = value!;
                _filterSongs();
              }),
            ),
          ),

          // Language Dropdown
          _buildFilterSection(
            'Language',
            _buildDropdown(
              selectedLanguage,
              languageOptions,
              (value) => setState(() {
                selectedLanguage = value!;
                _filterSongs();
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _filterSongs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (!isMobile)
                      const SizedBox(
                        width: 50,
                        child: Text(
                          'No.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Expanded(
                      child: Text(
                        'Song Title',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isMobile)
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share search results'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pagination controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Items per page selector
                    Row(
                      children: [
                        Text(
                          'Show: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButton<int>(
                            value: itemsPerPage,
                            underline: const SizedBox(),
                            items: itemsPerPageOptions.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: _changeItemsPerPage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'of ${filteredSongs.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    // Page navigation
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.first_page),
                          onPressed: currentPage > 1
                              ? () => _changePage(1)
                              : null,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 1
                              ? () => _changePage(currentPage - 1)
                              : null,
                          iconSize: 20,
                        ),
                        Text(
                          'Page $currentPage of $totalPages',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentPage < totalPages
                              ? () => _changePage(currentPage + 1)
                              : null,
                          iconSize: 20,
                        ),
                        IconButton(
                          icon: const Icon(Icons.last_page),
                          onPressed: currentPage < totalPages
                              ? () => _changePage(totalPages)
                              : null,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Songs List
          Expanded(
            child: ListView.builder(
              itemCount: paginatedSongs.length,
              itemBuilder: (context, index) {
                // Calculate actual song number based on page
                final actualIndex =
                    (currentPage - 1) * itemsPerPage + index + 1;
                return SongCard(
                  key: ValueKey(paginatedSongs[index].songId), // or unique URL
                  song: paginatedSongs[index],
                  index: actualIndex,
                  onPlay: _playSongGlobally,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Song Card Widget
class SongCard extends StatefulWidget {
  final Song song;
  final int index;
  final void Function(Song song)? onPlay;

  const SongCard({
    Key? key,
    required this.song,
    required this.index,
    this.onPlay,
  }) : super(key: key);

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  html.AudioElement? _audioElement;
  static html.AudioElement? _currentlyPlaying;
  bool isPlaying = false;
  bool showVolumeSlider = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  double volume = 1.0; // 0.0 to 1.0
  bool _isSoundCloud(String url) {
    return url.contains('soundcloud.com');
  }

  bool _isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  bool _isSpotify(String url) {
    return url.contains('spotify.com');
  }

  bool _isRaagaBox(String url) {
    return url.contains('raagabox.com');
  }

  @override
  void initState() {
    super.initState();

    final links = widget.song.audioLink;

    // 🔒 HARD GUARD — prevents this crash forever
    if (links.isEmpty || links.first.trim().isEmpty) {
      return;
    }

    final url = links.first;

    // Only prepare native audio (MP3 / S3)
    if (!_isSoundCloud(url) &&
        !_isYouTube(url) &&
        !_isSpotify(url) &&
        !_isRaagaBox(url)) {
      _audioElement = html.AudioElement(url);
      _audioElement!.volume = volume;

      _audioElement!.onLoadedMetadata.listen((_) {
        if (mounted) {
          setState(() {
            duration = Duration(seconds: _audioElement!.duration.toInt());
          });
        }
      });

      _audioElement!.onTimeUpdate.listen((_) {
        if (mounted) {
          setState(() {
            position = Duration(seconds: _audioElement!.currentTime.toInt());
          });
        }
      });

      _audioElement!.onPlay.listen((_) {
        if (mounted) setState(() => isPlaying = true);
      });

      _audioElement!.onPause.listen((_) {
        if (mounted) setState(() => isPlaying = false);
      });

      _audioElement!.onEnded.listen((_) {
        if (mounted) {
          setState(() {
            isPlaying = false;
            position = Duration.zero;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    if (_currentlyPlaying == _audioElement) {
      _currentlyPlaying = null;
    }
    _audioElement?.pause();
    _audioElement = null;
    super.dispose();
  }

  void _togglePlayPause() {
    if (_audioElement == null) return;

    try {
      if (isPlaying) {
        _audioElement!.pause();
      } else {
        if (_currentlyPlaying != null && _currentlyPlaying != _audioElement) {
          _currentlyPlaying!.pause();
        }

        _audioElement!.play();
        _currentlyPlaying = _audioElement;
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Error playing audio: $e'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
    }
  }

  void _seekTo(double value) {
    if (_audioElement == null) return;
    _audioElement!.currentTime = value;
  }

  void _setVolume(double value) {
    if (_audioElement == null) return;
    setState(() {
      volume = value;
      _audioElement!.volume = value;
    });
  }

  void _openInNewTab() {
    if (widget.song.audioLink.isEmpty) return;
    final audioUrl = widget.song.audioLink.first;
    html.window.open(audioUrl, '_blank');
  }

  IconData _getVolumeIcon() {
    if (volume == 0) {
      return Icons.volume_off;
    } else if (volume < 0.5) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildBadge(String label, Color color) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildBadges() {
    List<Widget> badges = [];

    // Split comma-separated values and create badges
    void addBadges(String value, Color color, String prefix) {
      if (value.isEmpty) return;
      value.split(',').forEach((item) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) {
          badges.add(_buildBadge('$prefix: $trimmed', color));
        }
      });
    }

    // Add single value badge (for non-comma-separated fields)
    void addSingleBadge(String value, Color color, String prefix) {
      if (value.trim().isNotEmpty) {
        badges.add(_buildBadge('$prefix: ${value.trim()}', color));
      }
    }

    // Add badges for different attributes with different colors
    addBadges(widget.song.deity, Colors.orange, 'Deity');
    addBadges(widget.song.language, Colors.blue, 'Lang');
    addBadges(widget.song.level, Colors.green, 'Level');
    addBadges(widget.song.tempo, Colors.purple, 'Tempo');
    addBadges(widget.song.raga, Colors.teal, 'Raga');
    addBadges(widget.song.beat, Colors.red, 'Beat');

    // Add pitch and range badges
    addSingleBadge(
      widget.song.referenceGentsPitch,
      Colors.indigo,
      'Gents Pitch',
    );
    addSingleBadge(
      widget.song.referenceLadiesPitch,
      Colors.pink,
      'Ladies Pitch',
    );
    addSingleBadge(widget.song.notesRange, Colors.deepOrange, 'Notes Range');

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index Number
            SizedBox(
              width: 50,
              child: Text(
                '${widget.index}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Song Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with play button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.song.title2.isNotEmpty
                              ? widget.song.title2
                              : widget.song.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      if (widget.song.audioLink.isNotEmpty)
                        const Icon(
                          Icons.play_circle_filled,
                          color: Colors.red,
                          size: 24,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Lyrics
                  Text(
                    widget.song.lyrics,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Badges/Tags
                  Wrap(children: _buildBadges()),

                  const SizedBox(height: 12),

                  // Audio Player
                  if (widget.song.audioLink.isNotEmpty &&
                      widget.song.audioLink.first.trim().isNotEmpty)
                    Builder(
                      builder: (context) {
                        final url = widget.song.audioLink.first;

                        if (_isSoundCloud(url)) {
                          return _buildSoundCloudPlayer(url);
                        } else if (_isYouTube(url)) {
                          return _buildYouTubePlayer(url, widget.index);
                        } else if (_isSpotify(url)) {
                          return _buildSpotifyPlayer(url, widget.index);
                        } else if (_isRaagaBox(url)) {
                          return _buildRaagaBoxPlayer(url, widget.index);
                        } else {
                          // ONLY S3 / MP3 comes here
                          return _buildNativeAudioPlayer();
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAudioPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.blue[700],
                ),
                onPressed: () {
                  widget.onPlay?.call(widget.song);
                },
              ),
              Text(
                _formatDuration(position),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Expanded(
                child: Slider(
                  value: position.inSeconds.toDouble(),
                  max: duration.inSeconds.toDouble() > 0
                      ? duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: _seekTo,
                  activeColor: Colors.blue[700],
                  inactiveColor: Colors.grey[400],
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              // Volume button that toggles slider
              IconButton(
                icon: Icon(_getVolumeIcon(), color: Colors.grey[700], size: 20),
                tooltip: 'Volume',
                onPressed: () {
                  setState(() {
                    showVolumeSlider = !showVolumeSlider;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.open_in_new,
                  color: Colors.grey[700],
                  size: 20,
                ),
                tooltip: 'Open in new tab',
                onPressed: _openInNewTab,
              ),
            ],
          ),
          // Volume slider row (shown when toggled)
          if (showVolumeSlider)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.volume_down, size: 16, color: Colors.grey[700]),
                  Expanded(
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(volume * 100).round()}%',
                      onChanged: _setVolume,
                      activeColor: Colors.blue[700],
                      inactiveColor: Colors.grey[400],
                    ),
                  ),
                  Icon(Icons.volume_up, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${(volume * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoundCloudPlayer(String url) {
    final embedUrl =
        'https://w.soundcloud.com/player/?url=${Uri.encodeComponent(url)}';

    final viewType = 'soundcloud-${widget.index}';

    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = embedUrl
          ..style.border = 'none'
          ..width = '100%'
          ..height = '120';

        return iframe;
      });
    }

    return SizedBox(height: 120, child: HtmlElementView(viewType: viewType));
  }
}

// Add this new widget class to your main.dart file

class PianoKeyboardWidget extends StatelessWidget {
  final String noteRange;
  final String label;
  final Color highlightColor;

  const PianoKeyboardWidget({
    Key? key,
    required this.noteRange,
    required this.label,
    this.highlightColor = Colors.blue,
  }) : super(key: key);

  // Piano keys spanning 2 octaves (C3 to B4)
  static const List<String> allNotes = [
    'C3',
    'C#3',
    'D3',
    'D#3',
    'E3',
    'F3',
    'F#3',
    'G3',
    'G#3',
    'A3',
    'A#3',
    'B3',
    'C4',
    'C#4',
    'D4',
    'D#4',
    'E4',
    'F4',
    'F#4',
    'G4',
    'G#4',
    'A4',
    'A#4',
    'B4',
  ];

  bool _isBlackKey(String note) {
    return note.contains('#');
  }

  List<String> _parseRange(String range) {
    if (range.isEmpty) return [];

    // Handle formats like "C3-G4", "C3 to G4", "C3,G4", etc.
    final cleaned = range.replaceAll(' ', '').toUpperCase();

    // Try different separators
    List<String> parts = [];
    if (cleaned.contains('-')) {
      parts = cleaned.split('-');
    } else if (cleaned.contains('TO')) {
      parts = cleaned.split('TO');
    } else if (cleaned.contains(',')) {
      parts = cleaned.split(',');
    } else {
      // Single note
      return [cleaned];
    }

    if (parts.length == 2) {
      final startNote = parts[0].trim();
      final endNote = parts[1].trim();

      final startIndex = allNotes.indexOf(startNote);
      final endIndex = allNotes.indexOf(endNote);

      if (startIndex != -1 && endIndex != -1) {
        return allNotes.sublist(startIndex, endIndex + 1);
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final highlightedNotes = _parseRange(noteRange);

    if (highlightedNotes.isEmpty && noteRange.isNotEmpty) {
      // If parsing failed, show text fallback
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: highlightColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: highlightColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.piano, size: 16, color: highlightColor),
            const SizedBox(width: 6),
            Text(
              '$label: $noteRange',
              style: TextStyle(
                color: highlightColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (highlightedNotes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.piano, size: 18, color: highlightColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                noteRange,
                style: TextStyle(
                  fontSize: 12,
                  color: highlightColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: Stack(
              children: [
                // White keys
                Row(
                  children: allNotes
                      .where((note) => !_isBlackKey(note))
                      .map((note) => _buildWhiteKey(note, highlightedNotes))
                      .toList(),
                ),
                // Black keys (positioned absolutely)
                ...allNotes
                    .asMap()
                    .entries
                    .where((entry) => _isBlackKey(entry.value))
                    .map(
                      (entry) => _buildBlackKey(
                        entry.value,
                        entry.key,
                        highlightedNotes,
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteKey(String note, List<String> highlighted) {
    final isHighlighted = highlighted.contains(note);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
        decoration: BoxDecoration(
          color: isHighlighted ? highlightColor.withOpacity(0.3) : Colors.white,
          border: Border.all(
            color: isHighlighted ? highlightColor : Colors.grey[400]!,
            width: isHighlighted ? 2 : 1,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 8,
                  color: isHighlighted ? highlightColor : Colors.grey[600],
                  fontWeight: isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlackKey(String note, int index, List<String> highlighted) {
    final isHighlighted = highlighted.contains(note);

    // Calculate position based on white key positions
    final whiteKeysBefore = allNotes
        .sublist(0, index)
        .where((n) => !_isBlackKey(n))
        .length;
    final whiteKeyWidth = 20.0; // Approximate, will be flexible

    return Positioned(
      left: (whiteKeysBefore * whiteKeyWidth) - 6,
      top: 0,
      child: Container(
        width: 12,
        height: 50,
        decoration: BoxDecoration(
          color: isHighlighted ? highlightColor.withOpacity(0.8) : Colors.black,
          border: Border.all(
            color: isHighlighted ? highlightColor : Colors.grey[800]!,
            width: isHighlighted ? 2 : 1,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(2),
          ),
        ),
      ),
    );
  }
}

// Add this new widget for pitch display with key selection
class PitchSelectorWidget extends StatefulWidget {
  final String pitch;
  final String label;
  final Color color;

  const PitchSelectorWidget({
    Key? key,
    required this.pitch,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  State<PitchSelectorWidget> createState() => _PitchSelectorWidgetState();
}

class _PitchSelectorWidgetState extends State<PitchSelectorWidget> {
  String selectedKey = 'C';

  static const List<String> keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  String _transposeNote(String note, int semitones) {
    if (note.isEmpty) return note;

    // Extract base note and octave
    final match = RegExp(r'([A-G]#?)(\d)').firstMatch(note);
    if (match == null) return note;

    final baseNote = match.group(1)!;
    final octave = int.parse(match.group(2)!);

    final currentIndex = keys.indexOf(baseNote);
    if (currentIndex == -1) return note;

    int newIndex = (currentIndex + semitones) % 12;
    int octaveChange = (currentIndex + semitones) ~/ 12;

    if (newIndex < 0) {
      newIndex += 12;
      octaveChange -= 1;
    }

    final newOctave = octave + octaveChange;
    return '${keys[newIndex]}$newOctave';
  }

  String _transposePitch(String pitch, String fromKey, String toKey) {
    final fromIndex = keys.indexOf(fromKey);
    final toIndex = keys.indexOf(toKey);

    if (fromIndex == -1 || toIndex == -1) return pitch;

    int semitones = toIndex - fromIndex;

    // Handle range notation
    if (pitch.contains('-')) {
      final parts = pitch.split('-');
      final transposed1 = _transposeNote(parts[0].trim(), semitones);
      final transposed2 = _transposeNote(parts[1].trim(), semitones);
      return '$transposed1-$transposed2';
    }

    return _transposeNote(pitch, semitones);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pitch.isEmpty) return const SizedBox.shrink();

    final transposedPitch = _transposePitch(widget.pitch, 'C', selectedKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Key: ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: widget.color.withOpacity(0.3)),
              ),
              child: DropdownButton<String>(
                value: selectedKey,
                underline: const SizedBox(),
                isDense: true,
                items: keys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedKey = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PianoKeyboardWidget(
          noteRange: transposedPitch,
          label: widget.label,
          highlightColor: widget.color,
        ),
      ],
    );
  }
}

Widget _buildYouTubePlayer(String url, int index) {
  final videoId = Uri.parse(url).queryParameters['v'] ?? url.split('/').last;

  final embedUrl = 'https://www.youtube.com/embed/$videoId';

  final viewType = 'youtube-$index';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    return html.IFrameElement()
      ..src = embedUrl
      ..style.border = 'none'
      ..width = '100%'
      ..height = '200'
      ..allow = 'autoplay';
  });

  return SizedBox(height: 200, child: HtmlElementView(viewType: viewType));
}

Widget _buildSpotifyPlayer(String url, int index) {
  final embedUrl = url.replaceFirst(
    'open.spotify.com',
    'open.spotify.com/embed',
  );

  final viewType = 'spotify-$index';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    return html.IFrameElement()
      ..src = embedUrl
      ..style.border = 'none'
      ..width = '100%'
      ..height = '152';
  });

  return SizedBox(height: 152, child: HtmlElementView(viewType: viewType));
}

Widget _buildRaagaBoxPlayer(String url, int index) {
  final viewType = 'raagabox-$index';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    return html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..width = '100%'
      ..height = '200';
  });

  return SizedBox(height: 200, child: HtmlElementView(viewType: viewType));
}
