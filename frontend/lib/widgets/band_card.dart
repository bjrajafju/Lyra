import 'package:flutter/material.dart';
import 'safe_network_image.dart';
import '../models/band_model.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class BandCard extends StatelessWidget {
  final Band band;
  final VoidCallback? onTap;

  const BandCard({super.key, required this.band, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeNetworkImage(
                imageUrl: band.profileImage,
                width: 130,
                height: 130,
                borderRadius: BorderRadius.circular(65),
                fallbackIcon: Icons.group,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              band.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '${band.followerCount} followers',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
