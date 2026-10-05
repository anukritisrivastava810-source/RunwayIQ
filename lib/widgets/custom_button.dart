import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _buildContent(context),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? Theme.of(context).colorScheme.primary : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isOutlined ? Theme.of(context).colorScheme.primary : Colors.white),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: isOutlined ? Theme.of(context).colorScheme.primary : Colors.white)),
        ],
      );
    }
    return Text(text, style: TextStyle(color: isOutlined ? Theme.of(context).colorScheme.primary : Colors.white));
  }
}
