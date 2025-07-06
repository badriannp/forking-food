import 'package:flutter/material.dart';
import 'package:forking/utils/image_utils.dart';

class ProfileAvatarImage extends StatefulWidget {
  final String? imageUrl;
  final double radius;

  const ProfileAvatarImage({
    super.key,
    required this.imageUrl,
    this.radius = 44,
  });

  @override
  State<ProfileAvatarImage> createState() => _ProfileAvatarImageState();
}

class _ProfileAvatarImageState extends State<ProfileAvatarImage> {
  late final List<String> fallbackUrls;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    if (widget.imageUrl != null) {
      fallbackUrls = [
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
      return _defaultAvatar(context);
    }

    final url = fallbackUrls[currentIndex];

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {
        if (currentIndex < fallbackUrls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => currentIndex++);
          });
        }
      },
      child: currentIndex >= fallbackUrls.length
          ? _defaultIcon(context)
          : null,
    );
  }

  Widget _defaultAvatar(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      child: _defaultIcon(context),
    );
  }

  Widget _defaultIcon(BuildContext context) {
    return Icon(
      Icons.person,
      size: widget.radius,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
    );
  }
}