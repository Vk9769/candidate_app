import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/login_page.dart';

class Slide {
  final String image;
  final String title;
  final String description;

  Slide({required this.image, required this.title, required this.description});
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  bool _hover = false;

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  /// ================= CANDIDATE SLIDES =================
  final List<Slide> slides = [
    Slide(
      image: 'assets/home1.png',
      title: 'Welcome Candidate',
      description: 'Your personal dashboard for\nmonitoring election progress.',
    ),
    Slide(
      image: 'assets/home2.png',
      title: 'Track Your Performance',
      description:
          'View voting statistics, booth details,\nand agent activities in real time.',
    ),
    Slide(
      image: 'assets/home3.png',
      title: 'Manage & Engage',
      description:
          'Oversee super agents, agents,\nvoters and stay updated on results.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _bgAnimation = Tween<double>(
      begin: -40,
      end: 40,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _bgController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void nextSlide() {
    if (_currentIndex < slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget buildSlide(Slide slide, double sw, double sh) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(slide.image, width: sw * 0.55, height: sw * 0.55),
        SizedBox(height: sh * 0.04),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: sw * 0.07, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: sh * 0.015),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: sw * 0.045, color: Colors.black87),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWeb = width >= 900;

    return Scaffold(
      body: isWeb
          ? Stack(children: [_buildAnimatedFlagBackground(), _buildWebHero()])
          : _buildMobileSlider(),
    );
  }

  // ================= MOBILE =================
  Widget _buildMobileSlider() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
                child: buildSlide(slides[i], sw, sh),
              );
            },
          ),

          // DOT INDICATOR
          Positioned(
            bottom: sh * 0.12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentIndex == index ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.blue
                        : Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          // NEXT / LOGIN
          Positioned(
            left: sw * .06,
            right: sw * .06,
            bottom: sh * .04,
            child: SizedBox(
              height: sh * .065,
              child: ElevatedButton(
                onPressed: nextSlide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentIndex == slides.length - 1
                      ? "Login as Admin"
                      : "Next",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= WEB BACKGROUND =================
  Widget _buildAnimatedFlagBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/india_bg.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ================= WEB HERO =================
  Widget _buildWebHero() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 80),
        child: Row(
          children: [
            // LEFT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Candidate Dashboard",
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Monitor your election progress,\n"
                    "track voting statistics, and\n"
                    "manage your agents.\n\n"
                    "Stay informed. Stay ahead.",
                    style: TextStyle(fontSize: 20, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 80),

            // RIGHT IMAGE + CTA
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/home3.png", height: 420),
                  const SizedBox(height: 40),
                  MouseRegion(
                    onEnter: (_) => setState(() => _hover = true),
                    onExit: (_) => setState(() => _hover = false),
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _goToLogin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            if (_hover)
                              BoxShadow(
                                color: Colors.blue.withOpacity(.35),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                          ],
                        ),
                        child: const Text(
                          "Login as Candidate",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
