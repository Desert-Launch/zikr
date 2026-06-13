import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WProfileAvatar extends StatelessWidget {
  const WProfileAvatar({this.avatar, super.key});

  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = avatar;
    return Container(
      width: 58.r,
      height: 58.r,
      decoration: BoxDecoration(
        color: const Color(0xFF2F7E63),
        borderRadius: BorderRadius.circular(22.r),
        image: avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: avatarUrl == null
          ? Icon(Icons.person_outline_rounded, color: Colors.white, size: 29.r)
          : null,
    );
  }
}
