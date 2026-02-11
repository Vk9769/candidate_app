import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:candidate_app/screens/candidate_actions_page.dart';
import 'package:fl_chart/fl_chart.dart';

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

  late TransformationController _transformationController;
  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;

  String candidateName = "Candidate";
  String candidateEmail = "candidate@example.com";
  String candidateVoterId = "VOTER0000";

  double minX = 0;
  double maxX = 6;
  double minY = 0;
  double maxY = 4000;

  double _getNiceInterval(double range) {
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

  /// 🟢 Total voters vote casted
  final List<FlSpot> totalVotingData = [
    FlSpot(0, 400),
    FlSpot(1, 900),
    FlSpot(2, 1500),
    FlSpot(3, 2100),
    FlSpot(4, 2700),
    FlSpot(5, 3100),
    FlSpot(6, 3500),
  ];

  /// 🟠 Our voters vote casted
  final List<FlSpot> ourVotingData = [
    FlSpot(0, 200),
    FlSpot(1, 450),
    FlSpot(2, 900),
    FlSpot(3, 1300),
    FlSpot(4, 1700),
    FlSpot(5, 2100),
    FlSpot(6, 2500),
  ];

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_updateYAxis);
    _loadCandidateData();
    _loadDummyDashboardData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
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
      polls = 12; // dummy polling booths
      votesCasted = 3500; // dummy votes casted
      votesPending = 1200; // dummy votes pending
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
    final Color primary = Theme.of(context).colorScheme.primary;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : IgnorePointer(
            ignoring: false,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // KPI Grid
                  GridView(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        title: 'Polling Booths',
                        value: polls.toString(),
                        icon: Icons.how_to_vote,
                        color: primary,
                        background: Colors.white,
                      ),
                      StatCard(
                        title: 'Votes Casted',
                        value: formatNumber(votesCasted),
                        icon: Icons.done_all,
                        color: Colors.green,
                        background: Colors.white,
                      ),
                      StatCard(
                        title: 'Votes Pending',
                        value: formatNumber(votesPending),
                        icon: Icons.pending_actions,
                        color: Colors.redAccent,
                        background: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Voting Status Card
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
                              Icon(Icons.how_to_reg, color: Colors.blueAccent),
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
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildVotingGraph(),
                ],
              ),
            ),
          );
  }

  void _updateYAxis() {
    final matrix = _transformationController.value;

    final scaleX = matrix.getMaxScaleOnAxis();

    final translationX = matrix.row0[3]; // REAL PAN POSITION

    // Total range
    const double totalRange = 6;

    // Visible range after zoom
    double visibleRange = totalRange / scaleX;

    // Calculate left boundary from translation
    double newMinX = (-translationX / scaleX).clamp(
      0.0,
      totalRange - visibleRange,
    );

    double newMaxX = newMinX + visibleRange;

    final visibleSpots = [
      ...totalVotingData,
      ...ourVotingData,
    ].where((e) => e.x >= newMinX && e.x <= newMaxX);

    if (visibleSpots.isEmpty) return;

    double localMinY = visibleSpots
        .map((e) => e.y)
        .reduce((a, b) => a < b ? a : b);

    double localMaxY = visibleSpots
        .map((e) => e.y)
        .reduce((a, b) => a > b ? a : b);

    if (newMinX == minX &&
        newMaxX == maxX &&
        localMinY == minY &&
        localMaxY == maxY) {
      return;
    }

    setState(() {
      minX = newMinX;
      maxX = newMaxX;

      double padding = (localMaxY - localMinY) * 0.1;

      double interval = _getNiceInterval(localMaxY - localMinY);

      minY = ((localMinY - padding) / interval).floor() * interval;
      minY = minY < 0 ? 0 : minY;

      maxY = ((localMaxY + padding) / interval).ceil() * interval;
    });
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
            /// ⭐ PRO HEADER
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

                const Column(
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
              ],
            ),

            const SizedBox(height: 26),

            AspectRatio(
              aspectRatio: 1.4,
              child: LineChart(
                transformationConfig: FlTransformationConfig(
                  scaleAxis: FlScaleAxis.horizontal,
                  minScale: 1.0,
                  maxScale: 20,
                  panEnabled: _isPanEnabled,
                  scaleEnabled: _isScaleEnabled,
                  transformationController: _transformationController,
                ),
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.25),

                        strokeWidth: 1,
                        dashArray: [6, 6],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.25),

                        strokeWidth: 1,
                        dashArray: [6, 6],
                      );
                    },
                  ),

                  borderData: FlBorderData(show: false),

                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((e) {
                          return LineTooltipItem(
                            "${e.y.toInt()} votes",
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
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
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const times = [
                            "10:00",
                            "10:05",
                            "10:10",
                            "10:15",
                            "10:20",
                            "10:25",
                            "10:30",
                          ];

                          if (value.toInt() < times.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                times[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    /// TOTAL VOTES (AUTO GREEN INTENSITY)
                    LineChartBarData(
                      spots: totalVotingData,
                      isCurved: true,
                      barWidth: 3,

                      /// COLOR BASED ON TOTAL VOTES VALUE
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

                    /// OUR VOTES (AUTO ORANGE INTENSITY)
                    LineChartBarData(
                      spots: ourVotingData,
                      isCurved: true,
                      barWidth: 3,

                      /// COLOR BASED ON PERFORMANCE
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
                duration: Duration.zero,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                /// TOTAL VOTERS
                Expanded(
                  child: _graphStat(
                    "Total Voters",
                    formatNumber(totalVoters),
                    Colors.blue,
                    Icons.people,
                  ),
                ),

                const SizedBox(width: 12),

                /// TOTAL VOTES CASTED
                Expanded(
                  child: _graphStat(
                    "Votes Casted",
                    formatNumber(votesCasted),
                    Colors.green,
                    Icons.done_all,
                  ),
                ),

                const SizedBox(width: 12),

                /// OUR VOTES
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

            /// ⭐ WINNING CHANCE ANALYTICS
            Center(child: _buildWinningChance()),
          ],
        ),
      ),
    );
  }

  Widget _buildWinningChance() {
    /// 🔥 CALCULATE WINNING %
    double winningPercent = 0;

    if (votesCasted > 0) {
      winningPercent = (ourVotesCasted / votesCasted) * 100;
    }

    /// COLOR LOGIC (Election style)
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

        /// 🔥 PROGRESS INDICATOR (Professional look)
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
    return Scaffold(
      drawer: _currentIndex == 0 ? _buildDrawer(context) : null,
      appBar: _buildAppBar(),

      body: _getBody(),
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

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: SingleChildScrollView(
              controller: scrollController,
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
      ),
    );
  }
}

// Voting Status Card
class _VotingStatusCard extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
    );
  }
}

// KPI Card
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBadge(icon: icon, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
