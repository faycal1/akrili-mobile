import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class AkriliImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AkriliImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiClient.resolveUrl(imageUrl);

    Widget fallback = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: errorWidget ??
            const Icon(
              Icons.home_work_outlined,
              size: 32,
              color: Colors.grey,
            ),
      ),
    );

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: fallback);
      }
      return fallback;
    }

    Widget imageWidget = Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return fallback;
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}
