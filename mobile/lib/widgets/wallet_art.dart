import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/ui.dart';

/// A small, scalable wallet illustration built from Flutter shapes.
class WalletArt extends StatelessWidget {
  final double size;
  const WalletArt({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FittedBox(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 6,
              top: 14,
              child: Container(
                width: 146,
                height: 138,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 38,
              top: 32,
              child: Transform.rotate(
                angle: -.2,
                child: Container(
                  width: 96,
                  height: 66,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDBAD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFEEDB),
                      width: 3,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 20,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B56E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 63,
              child: Transform.rotate(
                angle: -.07,
                child: Container(
                  width: 126,
                  height: 83,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF891AC), Color(0xFFE44D7A)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFFFB7CC),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: .18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 17, top: 19),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFFDFE8),
                        size: 23,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 88,
              child: Container(
                width: 44,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCFDD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .6),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.circle, size: 8, color: primary),
              ),
            ),
            Positioned(
              left: 2,
              top: 47,
              child: Transform.rotate(
                angle: math.pi / 10,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 23,
                  color: Color(0xFFEFB87B),
                ),
              ),
            ),
            const Positioned(
              right: 0,
              top: 23,
              child: Icon(Icons.add_rounded, size: 25, color: rose),
            ),
            Positioned(
              left: 14,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: rose,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
