import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/theme/app_colors.dart';
import '../screens/auth/login_screen.dart';

class BottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isGuest;

  const BottomBar({super.key, required this.currentIndex, required this.onTap, this.isGuest = false});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.grey900 : Colors.white;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.08);

    final inactiveIconColor = Colors.grey;
    final activeColor = AppColors.primary;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
        height: 64 + bottomInset,
        child: CustomPaint(
          painter: CurvePainter(
            color: bgColor,
            shadowColor: shadowColor,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Icons and Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        index: 0,
                        lottiePath: 'assets/Home Icon.json',
                        label: 'Home',
                        isSelected: widget.currentIndex == 0,
                        activeColor: activeColor,
                        inactiveColor: inactiveIconColor,
                        onTap: () => widget.onTap(0),
                      ),
                      _NavItem(
                        index: 1,
                        lottiePath: 'assets/shopping cart.json',
                        label: 'Explore',
                        isSelected: widget.currentIndex == 1,
                        activeColor: activeColor,
                        inactiveColor: inactiveIconColor,
                        onTap: () => widget.onTap(1),
                      ),
                      if (widget.isGuest)
                        const _JoinButton()
                      else ...[
                        _NavItem(
                          index: 2,
                          lottiePath: 'assets/calender.json',
                          label: 'Bookings',
                          isSelected: widget.currentIndex == 2,
                          activeColor: activeColor,
                          inactiveColor: inactiveIconColor,
                          onTap: () => widget.onTap(2),
                        ),
                        _NavItem(
                          index: 3,
                          lottiePath: 'assets/user icon.json',
                          label: 'Profile',
                          isSelected: widget.currentIndex == 3,
                          activeColor: activeColor,
                          inactiveColor: inactiveIconColor,
                          onTap: () => widget.onTap(3),
                        ),
                      ],
                    ],
                  ),
                ],
                ),
              );
            },
          ),
        ),
      );
  }
}

class _NavItem extends StatefulWidget {
  final int index;
  final String lottiePath;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.lottiePath,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                widget.isSelected
                    ? widget.activeColor
                    : widget.inactiveColor,
                BlendMode.srcATop,
              ),
              child: Lottie.asset(
                widget.lottiePath,
                controller: _ctrl,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  _ctrl.duration = composition.duration;
                  if (widget.isSelected) _ctrl.forward(from: 0.0);
                },
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected ? widget.activeColor : widget.inactiveColor,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatefulWidget {
  const _JoinButton();

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, b, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) {
            _ctrl.reverse();
            _onTap();
          },
          onTapCancel: () => _ctrl.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Join Hirebuddy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  CurvePainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();

    // Flat bottom — flush with screen edge
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawShadow(path, shadowColor, 8.0, false);
    canvas.drawPath(path, paint);

    var borderPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CurvePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
