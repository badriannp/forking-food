import 'package:flutter/material.dart';
import 'package:forking/utils/image_utils.dart';

class CreatorAvatar extends StatefulWidget {
  final String? imageUrl;

  const CreatorAvatar({super.key, this.imageUrl});

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

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha(220),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (currentIndex < fallbackUrls.length - 1) {
              // Așteaptă până se termină build-ul curent
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
    return Icon(
      Icons.person_outline,
      size: 16,
      color: Colors.white.withAlpha(220),
    );
  }
}