import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HostSettingsScreen extends StatefulWidget {
  const HostSettingsScreen({super.key});

  @override
  State<HostSettingsScreen> createState() => _HostSettingsScreenState();
}

class _HostSettingsScreenState extends State<HostSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load pending coaches when settings opens
    final authProvider = context.read<AuthProvider>();
    authProvider.loadPendingCoaches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.barlow(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Approve Coaches Section
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final pendingCount = authProvider.pendingCoaches.length;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approve Coaches',
                          style: GoogleFonts.barlow(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: pendingCount > 0 ? Colors.amber[300] : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (pendingCount == 0)
                          Text(
                            'No coaches waiting for approval',
                            style: GoogleFonts.barlow(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingCount,
                              itemBuilder: (context, index) {
                                final coach = authProvider.pendingCoaches[index];
                                return _buildCoachApprovalTile(
                                  context,
                                  coach.name,
                                  coach.email,
                                  coach.id,
                                  authProvider,
                                  index == pendingCount - 1 ? null : Divider(color: Colors.white30, height: 0),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white30),
                const SizedBox(height: 24),
                // Manage Coaches Section
                _buildSettingsSection(
                  title: 'Manage Coaches',
                  subtitle: 'View and manage coaches for this gym',
                  onTap: () {
                    Navigator.of(context).pushNamed('/host-manage-coaches');
                  },
                ),
              ],
            ),
          ),
          // Logout Button at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: Text(
                      'Logout',
                      style: GoogleFonts.barlow(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to log out? You will return to the main screen.',
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.barlow(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthProvider>().logout();
                          Navigator.of(context).pushReplacementNamed('/welcome');
                        },
                        child: Text(
                          'Logout',
                          style: GoogleFonts.barlow(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachApprovalTile(
    BuildContext context,
    String coachName,
    String coachEmail,
    String coachId,
    AuthProvider authProvider,
    Widget? bottomDivider,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachName,
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coachEmail,
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () async {
                  await authProvider.approveCoach(coachId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Approved $coachName')),
                    );
                  }
                },
                child: Text(
                  'Approve',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        ?bottomDivider,
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? Colors.red[300] : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red[300] : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
