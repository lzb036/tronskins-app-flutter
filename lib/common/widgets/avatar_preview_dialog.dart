import 'package:flutter/material.dart';

Future<void> showAvatarPreviewDialog(
  BuildContext context, {
  required ImageProvider imageProvider,
  required Object heroTag,
}) {
  final size = MediaQuery.of(context).size;
  final width = size.width * 0.78;
  final height = size.height * 0.58;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.85),
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: SizedBox(
          width: width,
          height: height,
          child: Hero(
            tag: heroTag,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white70,
                              size: 40,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
