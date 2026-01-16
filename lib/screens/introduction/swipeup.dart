import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipeUpButton extends StatelessWidget {
  final double swipeOffset;
  final Animation<double> swipeAnimation;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const SwipeUpButton({
    Key? key,
    required this.swipeOffset,
    required this.swipeAnimation,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: AnimatedBuilder(
        animation: swipeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, swipeOffset * (1 - swipeAnimation.value)),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      AnimatedOpacity(
                        opacity: swipeOffset < -20 ? 0.3 : 0.7,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 28,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: AnimatedOpacity(
                          opacity: swipeOffset < -20 ? 0.7 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mulai Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: swipeOffset < -30 ? 0.0 : 0.8,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Geser ke atas untuk melanjutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
