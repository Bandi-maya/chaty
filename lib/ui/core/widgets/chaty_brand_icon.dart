import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/app_icon_controller.dart';

class ChatyBrandIcon extends StatelessWidget {
  final AppIconController controller;
  final double size;
  final double borderRadius;

  const ChatyBrandIcon({
    super.key,
    required this.controller,
    this.size = 48,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        Widget image;
        final customPath = controller.customBrandIconPath;
        if (controller.brandIconSource == BrandIconSource.custom &&
            customPath != null &&
            customPath.isNotEmpty &&
            File(customPath).existsSync()) {
          image = Image.file(
            File(customPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _bundled(),
          );
        } else {
          image = _bundled();
        }

        return Semantics(
          image: true,
          label: 'Chaty app icon',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(width: size, height: size, child: image),
          ),
        );
      },
    );
  }

  Widget _bundled() {
    return Image.asset(
      controller.bundledBrandAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => ColoredBox(
        color: const Color(0xFF13B982),
        child: Icon(Icons.chat_bubble_rounded, size: size * 0.52, color: Colors.white),
      ),
    );
  }
}
