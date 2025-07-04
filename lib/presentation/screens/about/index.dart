import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:sysadmin/presentation/screens/about/upi_donation_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );
  // String _formattedDate = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    // TODO: Replace with your actual build date logic
    // final buildDate = DateTime.now();

    setState(() {
      _packageInfo = info;
      // _formattedDate = DateFormat('MMMM d, yyyy').format(buildDate);
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  static Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildGlassPill({
    required String title,
    required IconData icon,
    required Function() onTap,
    Color? iconColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String asset,
    required String label,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(asset, height: 28, width: 28),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationOption({
    required String asset,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.useOpacity(0.3)),
          gradient: const LinearGradient(
            colors: <Color> [
              Color(0xFFCC3399),
              Color(0xFF3399CC),
              Color(0xFF9933CC),
              Color(0xFF33CC99),
            ],
          ),
        ),
        child: Center(
          child: asset.endsWith('.svg')
            ? SvgPicture.asset(asset, height: 36)
            : Image.asset(asset, height: 36, fit: BoxFit.contain),
        )
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(color: Theme.of(context).colorScheme.primary.useOpacity(0.3)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium)
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        title: const Text(
          'GPL-3.0 License',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'SysAdmin is licensed under the GNU General Public License v3.0 or later.\n\n'
              'This program is free software: you can redistribute it and/or modify '
              'it under the terms of the GNU General Public License as published by '
              'the Free Software Foundation, either version 3 of the License, or '
              '(at your option) any later version.\n\n'
              'This program is distributed in the hope that it will be useful, '
              'but WITHOUT ANY WARRANTY; without even the implied warranty of '
              'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the '
              'GNU General Public License for more details.\n\n'
              'You should have received a copy of the GNU General Public License '
              'along with this program. If not, see <https://www.gnu.org/licenses/>.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl('https://www.gnu.org/licenses/gpl-3.0.en.html');
            },
            child: Text(
              'View Full License',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IosScaffold(
      title: 'About',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Logo and App Info
              Center(
                child: Column(
                  children: [
                    // App Logo
                    Container(
                      height: 120,
                      width: 120,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.asset('assets/LogoRound.png', fit: BoxFit.fill),
                    ),

                    const SizedBox(height: 16),

                    // App Name
                    Text('SysAdmin', style: theme.textTheme.headlineMedium),

                    const SizedBox(height: 8),

                    // Tagline
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "The open-source Swiss Army knife\n for system administrators.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Version and Build Info
                    Text(
                      "v${_packageInfo.version}", // • $_formattedDate
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Action Pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  spacing: 8,
                  children: [
                    _buildGlassPill(
                      title: 'Feedback',
                      icon: Icons.feedback_outlined,
                      onTap: () => _launchUrl('https://github.com/prathameshkhade/sysadmin/issues'),
                    ),

                    _buildGlassPill(
                      title: 'License',
                      icon: Icons.gavel_outlined,
                      onTap: () => _showLicenseDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildGlassPill(
                      title: 'Discussions',
                      icon: Icons.forum_outlined,
                      onTap: () =>
                          _launchUrl('https://github.com/prathameshkhade/sysadmin/discussions'),
                    ),
                    const SizedBox(width: 8),
                    _buildGlassPill(
                      title: 'Wiki',
                      icon: Icons.menu_book_outlined,
                      onTap: () => _launchUrl('https://github.com/prathameshkhade/sysadmin/wiki'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Project Information
              Text(
                'About SysAdmin',
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)
              ),

              const SizedBox(height: 12),

              const Text(
                'SysAdmin is an open-source mobile application designed to simplify Linux server management via SSH, providing a GUI-driven experience for system administrators. With features like SSH Manager, File Explorer, Scheduled Jobs, Live Resource Monitoring, Terminal Access, and Environment Variable Management.',
                style: TextStyle(height: 1.5),
                softWrap: true,
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 32),

              // Creator Information
              Text('Creator & Maintainer', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prathamesh Khade', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),

                  // Social Links
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSocialButton(
                        asset: 'assets/about/github.svg',
                        label: 'GitHub',
                        onTap: () => _launchUrl('https://github.com/prathameshkhade'),
                      ),
                      _buildSocialButton(
                        asset: 'assets/about/linkedin.svg',
                        label: 'LinkedIn',
                        onTap: () => _launchUrl('https://linkedin.com/in/prathameshkhade'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Donation Section
              Text(
                'Support Development',
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDonationOption(
                      // title: 'Buy Me a Coffee',
                      asset: 'assets/about/buymeacoffee.png',
                      onTap: () => _launchUrl('https://buymeacoffee.com/prathameshkhade'),
                    ),
                    _buildDonationOption(
                      // title: 'GitHub Sponsor',
                      asset: 'assets/about/github-sponsor.png',
                      onTap: () => _launchUrl('https://github.com/sponsors/prathameshkhade'),
                    ),
                    _buildDonationOption(
                      // title: "Donate via UPI",
                      asset: 'assets/about/upi.png',
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const Upi())
                      )
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Credits & Acknowledgements
              Text(
                'Credits & Acknowledgements',
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTechChip('Flutter'),
                  _buildTechChip('Dart'),
                  _buildTechChip('dartssh2'),
                  _buildTechChip('SSH'),
                  _buildTechChip('SFTP'),
                  _buildTechChip('Open Source'),
                ],
              ),

              const SizedBox(height: 32),

              // Footer with Animated Heart
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface.useOpacity(0.7)),
                      children: [
                        const TextSpan(text: 'Made with'),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Lottie.asset(
                            'assets/about/heart.json',
                            controller: _heartController,
                            width: 50
                          ),
                        ),
                        const TextSpan(text: 'by @prathameshkhade'),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
