import 'package:flutter/material.dart';

class AiAdvisorScreen extends StatelessWidget {
  const AiAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildAiMessage(context, "Hi founder! I've analyzed your financial data for this month. You're doing well, but I found some optimization opportunities."),
                _buildAiMessage(context, "Recommendation:\n\nYour AWS bill increased by 22% last month. Implementing reserved instances could save you ~\$2,400 monthly.\n\nReduce marketing spend or delay hiring to extend runway."),
                _buildUserMessage(context, "How does this affect my runway?"),
                _buildAiMessage(context, "Saving \$2,400/mo extends your runway by approximately 1.5 weeks at current cash levels, reducing overall burn rate by 2.8%."),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ask about finances...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha:0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha:0.2)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0, right: 40.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(text, style: const TextStyle(height: 1.5)),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0, left: 40.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, height: 1.5)),
      ),
    );
  }
}
