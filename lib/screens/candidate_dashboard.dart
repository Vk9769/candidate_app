import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:candidate_app/screens/candidate_actions_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'all_voting_status_page.dart';
import 'package:flutter/gestures.dart';

/// Utility to format large numbers
String formatNumber(int number) {
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(2)}B';
  } else if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(2)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  } else {
    return number.toString();
  }
}

class CandidateDashboard extends StatefulWidget {
  const CandidateDashboard({super.key});

  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  final ScrollController scrollController = ScrollController();

  int polls = 0;
  int votesCasted = 0;
  int votesPending = 0;
  bool isLoading = true;

  /// Graph summary values
  int totalVoters = 5000;
  int ourVotesCasted = 2500;

  int _currentIndex = 0;

  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;

  String candidateName = "Candidate";
  String candidateEmail = "candidate@example.com";
  String candidateVoterId = "VOTER0000";

  double minX = 0;
  double maxX = 1800;

  double totalTimelineSeconds = 1800;

  final DateTime graphStartTime = DateTime(2026, 1, 1, 9, 0); // 9:00 AM

  String _selectedRange = "30m";

  double? crosshairX;

  double _lastScale = 1.0;

  final GlobalKey _chartKey = GlobalKey();

  void _handleZoom(ScaleUpdateDetails details) {
    double zoomFactor = details.scale / _lastScale;
    _lastScale = details.scale;

    double range = maxX - minX;

    double newRange = (range / zoomFactor).clamp(60.0, totalTimelineSeconds);

    double focalPercent = details.localFocalPoint.dx / context.size!.width;

    double focalX = minX + range * focalPercent;

    double newMinX = focalX - newRange * focalPercent;
    double newMaxX = newMinX + newRange;

    newMinX = newMinX.clamp(0, totalTimelineSeconds - newRange);

    newMaxX = newMinX + newRange;

    setState(() {
      minX = newMinX;
      maxX = newMaxX;
    });
  }

  Future<void> _refreshGraph() async {
    // 🔥 OPTIONAL: show loading if you want
    // setState(() => isLoading = true);

    /// STEP 1 — Fetch new data from DB/API
    /// Replace this with your real API call later

    /// STEP 2 — Reset zoom view
    setState(() {
      minX = 0;
      maxX = 1800;

      minY = 0;
      maxY = 4000;

      crosshairX = null;
      _lastScale = 1.0;
    });
  }

  double minY = 0;
  double maxY = 4000;

  double _getNiceInterval(double range) {
    if (range <= 0) return 1;
    double roughStep = range / 5;

    if (roughStep <= 10) return 10;
    if (roughStep <= 50) return 50;
    if (roughStep <= 100) return 100;
    if (roughStep <= 250) return 250;
    if (roughStep <= 500) return 500;
    if (roughStep <= 1000) return 1000;
    if (roughStep <= 2500) return 2500;
    if (roughStep <= 5000) return 5000;

    return (roughStep / 1000).ceil() * 1000;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMPROVED: Much more granular interval steps so labels never crowd or gap
  // ─────────────────────────────────────────────────────────────────────────
  double _getTimeInterval() {
    double range = maxX - minX;

    // ultra zoom
    if (range <= 600) return 60; // every 1 min

    // 30 minute view
    if (range <= 1800) return 300; // every 5 min

    // 1 hour view
    if (range <= 3600) return 600; // every 10 min

    // 3 hour view
    if (range <= 10800) return 1800; // every 30 min

    // 5 hour view
    if (range <= 18000) return 3600; // every 1 hour

    return 3600;
  }

  void _changeGraphRange(String range) {
    setState(() {
      _selectedRange = range;

      switch (range) {
        case "5h":
          totalTimelineSeconds = 5 * 3600;
          break;

        case "3h":
          totalTimelineSeconds = 3 * 3600;
          break;

        case "1h":
          totalTimelineSeconds = 3600;
          break;

        case "30m":
        default:
          totalTimelineSeconds = 1800;
      }

      /// reset viewport
      minX = 0;
      maxX = totalTimelineSeconds;

      crosshairX = null;
      _lastScale = 1.0;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMPROVED: Smart time formatting based on visible range
  // ─────────────────────────────────────────────────────────────────────────
  String _formatTime(double seconds) {
    final DateTime actualTime = graphStartTime.add(
      Duration(seconds: seconds.toInt()),
    );

    final int hour = actualTime.hour;
    final int minute = actualTime.minute;

    return "$hour:${minute.toString().padLeft(2, '0')}";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEW: Decide whether a label should be shown at this value.
  // Skips every-other label when spacing gets tight to prevent overlap.
  // ─────────────────────────────────────────────────────────────────────────
  bool _shouldShowLabel(double value) {
    double interval = _getTimeInterval();
    double range = maxX - minX;

    // Always show if it aligns to the interval
    if ((value % interval).abs() > 0.5) return false;

    // On tight zooms show every label; on wide views thin them out
    if (range > 1200) {
      // Show only every 2nd interval label (i.e., every 10 min at 5-min intervals)
      double bigInterval = interval * 2;
      return (value % bigInterval).abs() < 0.5;
    }

    return true;
  }

  /// 🟢 Total voters vote casted
  final List<FlSpot> totalVotingData = [
    FlSpot(0, 400),
    FlSpot(300, 900),
    FlSpot(600, 1500),
    FlSpot(900, 2100),
    FlSpot(1200, 2700),
    FlSpot(1500, 3100),
    FlSpot(1800, 3500),
  ];

  /// 🟠 Our voters vote casted
  final List<FlSpot> ourVotingData = [
    FlSpot(0, 200),
    FlSpot(300, 450),
    FlSpot(600, 900),
    FlSpot(900, 1300),
    FlSpot(1200, 1700),
    FlSpot(1500, 2100),
    FlSpot(1800, 2500),
  ];

  @override
  void initState() {
    super.initState();
    _loadCandidateData();
    _loadDummyDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCandidateData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      candidateName = prefs.getString('candidate_name') ?? "Candidate";
      candidateEmail =
          prefs.getString('candidate_email') ?? "candidate@example.com";
      candidateVoterId = prefs.getString('candidate_voter_id') ?? "VOTER0000";
    });
  }

  void _loadDummyDashboardData() {
    setState(() {
      polls = 12;
      votesCasted = 3500;
      votesPending = 1200;
      isLoading = false;
    });
  }

  AppBar _buildAppBar() {
    String title = '';
    switch (_currentIndex) {
      case 0:
        title = 'Candidate Dashboard';
        break;
      case 1:
        title = 'Actions';
        break;
      case 2:
        title = 'Profile';
        break;
      default:
        title = 'Candidate Dashboard';
    }
    return AppBar(
      automaticallyImplyLeading: _currentIndex == 0,
      title: Text(title),
      backgroundColor: Colors.blue,
      centerTitle: true,
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _dashboardBody();
      case 1:
        return const CandidateActionsPage();
      case 2:
        return _profilePage();
      default:
        return _dashboardBody();
    }
  }

  Widget _dashboardBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;
    final Color primary = Theme.of(context).colorScheme.primary;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : IgnorePointer(
            ignoring: false,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 16),

                      isDesktop
                          ? Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Polling Booths',
                                    value: polls.toString(),
                                    icon: Icons.how_to_vote,
                                    color: primary,
                                    background: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildVotingStatusCardDesktop(),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: StatCard(
                                title: 'Polling Booths',
                                value: polls.toString(),
                                icon: Icons.how_to_vote,
                                color: primary,
                                background: Colors.white,
                              ),
                            ),

                      if (!isDesktop) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.how_to_reg,
                                      color: Colors.blueAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Voting Status",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _VotingStatusCard(
                                        title: "Votes Casted",
                                        value: formatNumber(votesCasted),
                                        color: Colors.green,
                                        icon: Icons.done_all,
                                        progress:
                                            votesCasted /
                                            (votesCasted + votesPending),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AllVotingStatusPage(
                                                    state: "Maharashtra",
                                                    district: "Mumbai",
                                                    city: "Mumbai City",
                                                    area: "Colaba",
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _VotingStatusCard(
                                        title: "Votes Pending",
                                        value: formatNumber(votesPending),
                                        color: Colors.redAccent,
                                        icon: Icons.pending_actions,
                                        progress:
                                            votesPending /
                                            (votesCasted + votesPending),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AllVotingStatusPage(
                                                    state: "Maharashtra",
                                                    district: "Mumbai",
                                                    city: "Mumbai City",
                                                    area: "Colaba",
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      _buildVotingGraph(),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildVotingStatusCardDesktop() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _VotingStatusCard(
                title: "Votes Casted",
                value: formatNumber(votesCasted),
                color: Colors.green,
                icon: Icons.done_all,
                progress: votesCasted / (votesCasted + votesPending),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VotingStatusCard(
                title: "Votes Pending",
                value: formatNumber(votesPending),
                color: Colors.redAccent,
                icon: Icons.pending_actions,
                progress: votesPending / (votesCasted + votesPending),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Text(
            candidateName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            candidateEmail,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            "Voter ID: $candidateVoterId",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingGraph() {
    final Color accent = Colors.blue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 18),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.trending_up, color: accent),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Live Voting Trend",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B2C5D),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Votes received every 5 minutes",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                /// 🔥 REFRESH BUTTON
                IconButton(
                  tooltip: "Refresh & Reset View",
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshGraph,
                ),
                PopupMenuButton<String>(
                  tooltip: "Select Time Range",

                  onSelected: (value) {
                    _changeGraphRange(value);
                  },

                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "5h", child: Text("5 Hour")),
                    const PopupMenuItem(value: "3h", child: Text("3 Hour")),
                    const PopupMenuItem(value: "1h", child: Text("1 Hour")),
                    const PopupMenuItem(value: "30m", child: Text("30 Minute")),
                  ],

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.withOpacity(.1),
                    ),
                    child: Row(
                      children: [
                        Text(_selectedRange),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            SizedBox(
              key: _chartKey,
              height: MediaQuery.of(context).size.width > 900 ? 420 : 280,

              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    double zoomFactor = pointerSignal.scrollDelta.dy > 0
                        ? 1.1 // zoom OUT
                        : 0.9; // zoom IN

                    double range = maxX - minX;

                    double newRange = (range * zoomFactor).clamp(
                      60.0,
                      totalTimelineSeconds,
                    );

                    double focalPercent =
                        pointerSignal.localPosition.dx / context.size!.width;

                    double focalX = minX + range * focalPercent;

                    double newMinX = focalX - newRange * focalPercent;
                    double newMaxX = newMinX + newRange;

                    newMinX = newMinX.clamp(0, totalTimelineSeconds - newRange);

                    newMaxX = newMinX + newRange;

                    setState(() {
                      minX = newMinX;
                      maxX = newMaxX;
                    });
                  }
                },

                onPointerHover: (event) {
                  final box =
                      _chartKey.currentContext!.findRenderObject() as RenderBox;

                  final local = box.globalToLocal(event.position);

                  double percent = local.dx / box.size.width;

                  double range = maxX - minX;

                  setState(() {
                    crosshairX = minX + (range * percent);
                  });
                },

                child: GestureDetector(
                  // MOBILE PINCH ZOOM
                  onScaleUpdate: _handleZoom,
                  onScaleEnd: (_) {
                    _lastScale = 1.0;
                  },

                  // DESKTOP + MOBILE DRAG PAN
                  onHorizontalDragUpdate: (details) {
                    double range = maxX - minX;

                    double movePercent =
                        details.delta.dx / MediaQuery.of(context).size.width;

                    double moveAmount = range * movePercent;

                    setState(() {
                      minX -= moveAmount;
                      maxX -= moveAmount;

                      minX = minX.clamp(0, totalTimelineSeconds - range);

                      maxX = minX + range;
                    });
                  },

                  child: LineChart(
                    LineChartData(
                      clipData: FlClipData.all(),

                      minX: minX,
                      maxX: maxX,

                      minY: minY,
                      maxY: maxY,

                      extraLinesData: ExtraLinesData(
                        verticalLines: crosshairX == null
                            ? []
                            : [
                                VerticalLine(
                                  x: crosshairX!,
                                  color: Colors.blue,
                                  strokeWidth: 1.5,
                                  dashArray: [4, 4],
                                ),
                              ],
                      ),

                      // ───────────────────────────────────────────────────────
                      // IMPROVED: Grid lines only at clean interval boundaries
                      // ───────────────────────────────────────────────────────
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                          dashArray: [6, 6],
                        ),
                        getDrawingVerticalLine: (value) {
                          double interval = _getTimeInterval();
                          // Only draw at main interval boundaries
                          if ((value % interval).abs() > 0.5) {
                            return FlLine(strokeWidth: 0);
                          }
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                            dashArray: [6, 6],
                          );
                        },
                      ),

                      borderData: FlBorderData(show: false),

                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,

                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.black87,

                          getTooltipItems: (spots) {
                            return spots.map((e) {
                              return LineTooltipItem(
                                "${e.y.toInt()} votes\n${_formatTime(e.x)}",
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),

                        // POINTER LINE
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: Colors.blue,
                                    strokeWidth: 1.5,
                                    dashArray: [4, 4],
                                  ),
                                  FlDotData(show: true),
                                );
                              }).toList();
                            },
                      ),

                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          drawBelowEverything: true,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _getNiceInterval(maxY - minY),
                            getTitlesWidget: (value, meta) {
                              final label = formatNumber(value.toInt());

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),

                        // ───────────────────────────────────────────────────
                        // IMPROVED: Smart X-axis labels with overflow guard
                        // ───────────────────────────────────────────────────
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            // Extra height so rotated/taller labels don't clip
                            reservedSize: 36,
                            interval: _getTimeInterval(),
                            getTitlesWidget: (value, meta) {
                              /// ✅ SHOW ONLY LABELS INSIDE CURRENT VIEWPORT
                              if (value < minX || value > maxX) {
                                return const SizedBox();
                              }

                              /// ✅ SHOW ONLY CLEAN INTERVAL VALUES
                              final double interval = _getTimeInterval();

                              if ((value % interval).abs() > 1) {
                                return const SizedBox();
                              }

                              final label = _formatTime(value);

                              final double range = maxX - minX;

                              /// Rotate labels when very zoomed in
                              final bool shouldRotate = range <= 60;

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: shouldRotate
                                    ? Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),

                      lineBarsData: [
                        /// TOTAL VOTES
                        LineChartBarData(
                          spots: totalVotingData,
                          isCurved: true,
                          barWidth: 3,
                          color: votesCasted >= ourVotesCasted
                              ? Colors.green
                              : Colors.green.shade300,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.25),
                                Colors.green.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        /// OUR VOTES
                        LineChartBarData(
                          spots: ourVotingData,
                          isCurved: true,
                          barWidth: 3,
                          color: ourVotesCasted >= (votesCasted * 0.5)
                              ? Colors.orange
                              : Colors.orange.shade300,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.25),
                                Colors.orange.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 120),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _graphStat(
                    "Total Voters",
                    formatNumber(totalVoters),
                    Colors.blue,
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _graphStat(
                    "Votes Casted",
                    formatNumber(votesCasted),
                    Colors.green,
                    Icons.done_all,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _graphStat(
                    "Our Votes",
                    formatNumber(ourVotesCasted),
                    Colors.orange,
                    Icons.how_to_vote,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(child: _buildWinningChance()),
          ],
        ),
      ),
    );
  }

  Widget _buildWinningChance() {
    double winningPercent = 0;
    if (votesCasted > 0) {
      winningPercent = (ourVotesCasted / votesCasted) * 100;
    }

    Color indicatorColor;
    if (winningPercent >= 60) {
      indicatorColor = Colors.green;
    } else if (winningPercent >= 40) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Column(
      children: [
        const Text(
          "Chance of Winning",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0B2C5D),
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: winningPercent / 100,
                strokeWidth: 10,
                backgroundColor: Colors.grey.withOpacity(.2),
                color: indicatorColor,
              ),
            ),
            Text(
              "${winningPercent.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: indicatorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          winningPercent >= 60
              ? "Strong Lead"
              : winningPercent >= 40
              ? "Competitive"
              : "Needs Push",
          style: TextStyle(fontWeight: FontWeight.w600, color: indicatorColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      drawer: !isDesktop
          ? (_currentIndex == 0 ? _buildDrawer(context) : null)
          : null,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 260, child: _buildDrawer(context)),
          Expanded(child: _getBody()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.blue,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Actions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    final drawerContent = ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(color: Colors.blue),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              Text(
                candidateName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                candidateEmail,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                "Voter ID: $candidateVoterId",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        ),
      ],
    );

    if (!isDesktop) {
      return Drawer(child: drawerContent);
    }
    return Container(color: Colors.white, child: drawerContent);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _VotingStatusCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final double progress;

  const _VotingStatusCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.progress = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: color,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              color: color,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 18),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _graphStat(String title, String value, Color color, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
