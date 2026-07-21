import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'main_layout.dart';
import '../features/onboarding/data/repositories/onboarding_repository.dart';
import '../features/onboarding/presentation/onboarding_wrapper.dart';
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Illustration placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your financial intelligence dashboard.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha:0.6)),
              ),
              const SizedBox(height: 32),
              
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              CustomButton(
                text: 'Continue',
                onPressed: () => _handleLogin(context),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Sign in with Google',
                isOutlined: true,
                onPressed: () => _handleLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Simulate authentication
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading

      final isCompleted = await OnboardingRepository().isOnboardingCompleted();
      
      if (context.mounted) {
        if (isCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingWrapper()),
          );
        }
      }
    }
  }
}
