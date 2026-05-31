import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/band_provider.dart';
import '../screens/home/main_screen.dart';
import '../theme/app_theme.dart';
import '../models/band_model.dart';
import '../utils/constants.dart';

class ProfileContextSwitcher extends StatelessWidget {
  const ProfileContextSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bandProvider = context.watch<BandProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<Band?>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: (bandProvider.selectedBand?.profileImage ?? user.profilePicture) != null
                  ? NetworkImage(Constants.imageUrl(bandProvider.selectedBand?.profileImage ?? user.profilePicture))
                  : null,
              child: (bandProvider.selectedBand?.profileImage ?? user.profilePicture) == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              bandProvider.selectedBand?.name ?? user.username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      onSelected: (band) {
        if (band?.id == -1) {
          bandProvider.selectBand(null);
        } else {
          bandProvider.selectBand(band);
          if (band != null) {
            MainScreen.globalBandIndex = 0; // Reset to dashboard when switching bands
          }
        }
      },
      itemBuilder: (context) {
        final personalBandSentinel = Band(id: -1, name: 'Personal Profile');
        return [
          // Personal Profile
          PopupMenuItem<Band?>(
            value: personalBandSentinel,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: user.profilePicture != null
                      ? NetworkImage(Constants.imageUrl(user.profilePicture))
                      : null,
                  child: user.profilePicture == null ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Personal Artist Profile', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (!bandProvider.isBandContext)
                  const Icon(Icons.check, color: AppTheme.primary, size: 18),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // Managed Bands
          if (bandProvider.managedBands.isNotEmpty) ...[
            const PopupMenuItem(
              enabled: false,
              child: Text('MANAGE BANDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ...bandProvider.managedBands.map((band) => PopupMenuItem<Band?>(
                  value: band,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: band.profileImage != null
                            ? NetworkImage(Constants.imageUrl(band.profileImage))
                            : null,
                        child: band.profileImage == null ? const Icon(Icons.groups, size: 18) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(band.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(band.roleInBand ?? 'Editor', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (bandProvider.selectedBand?.id == band.id)
                        const Icon(Icons.check, color: AppTheme.primary, size: 18),
                    ],
                  ),
                )),
          ],
        ];
      },
    );
  }
}
