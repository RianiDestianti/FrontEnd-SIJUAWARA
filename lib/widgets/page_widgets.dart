import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/introduction.dart';

// ─── Layered circular image ───────────────────────────────────────────────────

class LayeredImage extends StatelessWidget {
  final String image;
  final double size;

  const LayeredImage({super.key, required this.image, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.07),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.07),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.25),
          ),
          child: Center(
            child: Image.asset(
              image,
              width: size * 0.6,
              height: size * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Description pill ─────────────────────────────────────────────────────────

class DescriptionBox extends StatelessWidget {
  final String description;
  final bool isWeb;
  final double screenWidth;

  const DescriptionBox({
    super.key,
    required this.description,
    required this.isWeb,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 32 : 20,
        vertical: isWeb ? 20 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF61B8FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF61B8FF).withOpacity(0.2),
        ),
      ),
      child: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: isWeb ? 18 : 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B7280),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Regular intro page ───────────────────────────────────────────────────────

class RegularPage extends StatelessWidget {
  final PageData pageData;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  const RegularPage({
    super.key,
    required this.pageData,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isWeb ? screenWidth * 0.1 : 24.0,
                  MediaQuery.of(context).padding.top + 20,
                  isWeb ? screenWidth * 0.1 : 24.0,
                  24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    ScaleTransition(
                      scale: scaleAnimation,
                      child: LayeredImage(
                        image: pageData.image!,
                        size: isWeb ? 400 : screenWidth * 0.85,
                      ),
                    ),
                    SizedBox(height: isWeb ? 60 : 40),
                    Text(
                      pageData.title,
                      style: GoogleFonts.poppins(
                        fontSize: isWeb ? 32 : screenWidth * 0.07,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isWeb ? 24 : 16),
                    DescriptionBox(
                      description: pageData.description,
                      isWeb: isWeb,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Final (login CTA) page ───────────────────────────────────────────────────

class FinalPage extends StatelessWidget {
  final PageData pageData;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  const FinalPage({
    super.key,
    required this.pageData,
    required this.scaleAnimation,
    required this.fadeAnimation,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Color(0xFF4A90E2), Color(0xFF1E6BB8), Color(0xFF0F4A8C)],
            stops: [0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? screenWidth * 0.1 : 24.0,
              vertical: 20.0,
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: scaleAnimation,
                      child: LayeredImage(
                        image: pageData.image!,
                        size: isWeb ? 400 : screenWidth * 0.7,
                      ),
                    ),
                    SizedBox(height: isWeb ? 60 : 40),
                    FadeTransition(
                      opacity: fadeAnimation,
                      child: Text(
                        pageData.title,
                        style: GoogleFonts.poppins(
                          fontSize: isWeb ? 36 : 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isWeb ? 32 : 20),
                    FadeTransition(
                      opacity: fadeAnimation,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 600 : double.infinity,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          pageData.description,
                          style: GoogleFonts.poppins(
                            fontSize: isWeb ? 18 : 14,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: isWeb ? 60 : 40),
                    const _SwipeUpIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeUpIndicator extends StatelessWidget {
  const _SwipeUpIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.keyboard_arrow_up, color: Colors.white.withOpacity(0.6), size: 28),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Icon(Icons.keyboard_arrow_up, color: Colors.white.withOpacity(0.9), size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Geser ke atas untuk masuk',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}