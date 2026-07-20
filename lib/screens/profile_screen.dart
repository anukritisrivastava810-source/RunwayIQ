import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary.withValues(alpha:0.1),
              child: Text(
                'F',
                style: TextStyle(
                  fontSize: 32,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Acme Corp Founder', style: theme.textTheme.headlineMedium),
            Text('founder@acmecorp.com', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildListTile(context, Icons.business, 'Company Profile'),
                  const Divider(height: 1),
                  _buildListTile(context, Icons.currency_exchange, 'Currency Preference', subtitle: 'USD (\$)'),
                  const Divider(height: 1),
                  _buildListTile(context, Icons.palette_outlined, 'Theme', subtitle: 'System Default'),
                  const Divider(height: 1),
                  _buildListTile(context, Icons.security, 'Security'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            CustomButton(
              text: 'Log Out',
              isOutlined: true,
              icon: Icons.logout,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
