import 'package:flutter/material.dart';

class CandidateActionsPage extends StatefulWidget {
  const CandidateActionsPage({super.key});

  @override
  State<CandidateActionsPage> createState() => _CandidateActionsPageState();
}

class _CandidateActionsPageState extends State<CandidateActionsPage> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F9FF), Color(0xFFEAF2FF)],
        ),
      ),

      child: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // ✅ HEADER TITLE
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Candidate Dashboard",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B2C5D),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: 40,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.withOpacity(0)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Manage your campaign actions",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),

              const SizedBox(height: 30),
            ],
          ),

          _buildActionCard(
            0,
            Icons.admin_panel_settings,
            "Add Super Agent",
            "Create senior polling agent",
            Colors.deepOrange,
            () {},
          ),

          const SizedBox(height: 16),

          _buildActionCard(
            1,
            Icons.manage_accounts,
            "Manage Super Agent",
            "Edit and manage agents",
            Colors.blueGrey,
            () {},
          ),

          const SizedBox(height: 16),

          _buildActionCard(
            2,
            Icons.person_add,
            "Add Agent",
            "Register new agent",
            Colors.purple,
            () {},
          ),

          const SizedBox(height: 16),

          _buildActionCard(
            3,
            Icons.group,
            "Manage Agent",
            "View and edit agents",
            Colors.pink,
            () {},
          ),

          const SizedBox(height: 16),

          _buildActionCard(
            4,
            Icons.people,
            "View Voters",
            "Access voter records",
            Colors.green,
            () {},
          ),

          const SizedBox(height: 16),

          _buildActionCard(
            5,
            Icons.location_city,
            "Polling Booths",
            "View booth locations",
            Colors.teal,
            () {},
          ),
        ],
      ),
    );
  }

  // ================= ACTION CARD UI =================

  Widget _buildActionCard(
    int index,
    IconData icon,
    String title,
    String subtitle,
    Color accentColor,
    VoidCallback onTap,
  ) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),

      child: GestureDetector(
        onTap: onTap,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          transform: Matrix4.identity()..translate(0.0, isHovered ? -4.0 : 0.0),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: isHovered
                  ? accentColor.withOpacity(0.5)
                  : Colors.blueGrey.withOpacity(0.25),
              width: isHovered ? 1.5 : 1,
            ),

            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF1F6FF)],
            ),

            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(isHovered ? 0.25 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON BOX
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.2),
                        accentColor.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B2C5D),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Access",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 16, color: accentColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
