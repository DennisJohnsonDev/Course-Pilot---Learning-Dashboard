import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/models/user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.user, this.size = 36, super.key});

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = user?.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, const Color(0xFF9B5DE5), 0.55)!,
          ],
        ),
      ),
      child: initials == null || initials.isEmpty
          ? Icon(
              CupertinoIcons.person_fill,
              size: size * 0.5,
              color: colors.onPrimary,
            )
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: colors.onPrimary,
              ),
            ),
    );
  }
}
