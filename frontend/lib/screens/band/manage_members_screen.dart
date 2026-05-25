import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/band_member_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'invite_member_screen.dart';
import '../../widgets/safe_network_image.dart';

class ManageMembersScreen extends StatefulWidget {
  final int bandId;
  final String currentUserRole;

  const ManageMembersScreen({
    super.key,
    required this.bandId,
    required this.currentUserRole,
  });

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final members = await BandMemberService.getMembers(
        widget.bandId.toString(),
      );
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRolePicker(dynamic member) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (widget.currentUserRole == 'member') return;
    if (member['user_id'] == currentUserId) return;

    // Editor restriction: cannot manage Admins or promote to Admin
    if (widget.currentUserRole == 'editor') {
      if (member['role'] == 'admin') return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Change Role',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.currentUserRole == 'admin') _roleTile('admin', member),
          _roleTile('editor', member),
          _roleTile('member', member),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _roleTile(String role, dynamic member) {
    final isSelected = member['role'] == role;
    return ListTile(
      title: Text(role.toUpperCase()),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primary)
          : null,
      onTap: isSelected
          ? null
          : () => _updateRole(member['user_id'].toString(), role),
    );
  }

  Future<void> _updateRole(String userId, String role) async {
    Navigator.pop(context);
    try {
      await BandMemberService.updateMemberRole(
        widget.bandId.toString(),
        userId,
        role,
      );
      _fetchMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeMember(dynamic member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BandMemberService.removeMember(
          widget.bandId.toString(),
          member['user_id'].toString(),
        );
        _fetchMembers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canInvite = widget.currentUserRole != 'member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          if (canInvite)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteMemberScreen(bandId: widget.bandId),
                  ),
                );
                if (result == true) _fetchMembers();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return _buildMemberTile(member);
              },
            ),
    );
  }

  Widget _buildMemberTile(dynamic member) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMe = member['user_id'] == currentUserId;
    final role = member['role'].toString().toLowerCase();

    // Permission check for removal
    bool canRemove = false;
    if (widget.currentUserRole == 'admin') {
      if (role != 'admin' ||
          _members.where((m) => m['role'] == 'admin').length > 1) {
        canRemove = !isMe;
      }
    } else if (widget.currentUserRole == 'editor') {
      canRemove = role == 'member';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.white05),
      ),
      child: ListTile(
        onTap: isMe ? null : () => _showRolePicker(member),
        leading: CircleAvatar(
          backgroundColor: AppTheme.surfaceLight,
          backgroundImage: member['profile_picture'] != null
              ? SafeNetworkImage.getProvider(member['profile_picture'])
              : null,
          child: member['profile_picture'] == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          member['username'] ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getRoleColor(role).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(role),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        trailing: canRemove
            ? IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppTheme.error,
                  size: 20,
                ),
                onPressed: () => _removeMember(member),
              )
            : null,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.primary;
      case 'editor':
        return AppTheme.accent;
      default:
        return AppTheme.textSecondary;
    }
  }
}
