import 'package:flutter/material.dart';
import 'package:forking/utils/image_utils.dart';

class CreatorAvatar extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final Color? borderColor;
  final Color? fallbackColor;
  final double borderWidth;
  const CreatorAvatar({
    super.key, 
    this.imageUrl,
    this.size = 20,
    this.borderColor = Colors.transparent,
    this.fallbackColor,
    this.borderWidth = 0,
  });

  @override
  State<CreatorAvatar> createState() => _CreatorAvatarState();
}

class _CreatorAvatarState extends State<CreatorAvatar> {
  late final List<String> fallbackUrls;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.imageUrl != null) {
      fallbackUrls = [
        getResizedImageUrl(originalUrl: widget.imageUrl!, size: 100),
        getResizedImageUrl(originalUrl: widget.imageUrl!, size: 300),
        getResizedImageUrl(originalUrl: widget.imageUrl!, size: 600),
        widget.imageUrl!,
      ];
    } else {
      fallbackUrls = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fallbackUrls.isEmpty) {
      return _defaultIcon();
    }

    final url = fallbackUrls[currentIndex];
    final effectiveBorderColor = widget.borderColor ?? Colors.white.withAlpha(220);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveBorderColor,
          width: widget.borderWidth,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (currentIndex < fallbackUrls.length - 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => currentIndex++);
                }
              });
              return const SizedBox.shrink();
            }
            return _defaultIcon();
          },
        ),
      ),
    );
  }

  Widget _defaultIcon() {
    final effectiveFallbackColor = widget.fallbackColor ?? Colors.white.withAlpha(220);
    
    return Icon(
      Icons.person_outline,
      size: widget.size,
      color: effectiveFallbackColor,
    );
  }
}