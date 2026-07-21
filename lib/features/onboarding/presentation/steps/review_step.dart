import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';

class ReviewStep extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onFinish;
  final Function(int) onEdit;
  final bool isSubmitting;

  const ReviewStep({
    super.key,
    required this.data,
    required this.onFinish,
    required this.onEdit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review Setup',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please confirm your details before we create your dashboard.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              
              _buildReviewSection(
                theme: theme,
                title: 'Company Information',
                items: [
                  'Name: ${data.company?.name}',
                  'Industry: ${data.company?.industry}',
                  'Stage: ${data.company?.stage}',
                  'Country: ${data.company?.country}',
                ],
                onEdit: () => onEdit(1),
              ),
              const SizedBox(height: 16),
              
              _buildReviewSection(
                theme: theme,
                title: 'Financials',
                items: [
                  'Cash: \$${data.financials?.currentCash}',
                  'MRR: \$${data.financials?.monthlyRevenue}',
                  'Expenses: \$${data.financials?.monthlyExpenses}',
                  'Payroll: \$${data.financials?.payroll}',
                ],
                onEdit: () => onEdit(2),
              ),
              const SizedBox(height: 16),
              
              _buildReviewSection(
                theme: theme,
                title: 'Team',
                items: [
                  'Size: ${data.team?.teamSize}',
                  'Departments: ${data.team?.departments.join(', ')}',
                ],
                onEdit: () => onEdit(3),
              ),
              const SizedBox(height: 16),
              
              _buildReviewSection(
                theme: theme,
                title: 'Funding',
                items: [
                  'Raised: ${data.funding?.hasRaised == true ? 'Yes' : 'No'}',
                  if (data.funding?.hasRaised == true) ...[
                    'Round: ${data.funding?.round}',
                    'Amount: \$${data.funding?.amount}',
                    'Investor: ${data.funding?.investorName}',
                  ],
                ],
                onEdit: () => onEdit(4),
              ),
              const SizedBox(height: 16),
              
              _buildReviewSection(
                theme: theme,
                title: 'Treasury',
                items: [
                  'Investments: ${data.treasury?.hasInvestments == true ? 'Yes' : 'No'}',
                  if (data.treasury?.hasInvestments == true)
                    'Types: ${data.treasury?.investmentTypes.join(', ')}',
                ],
                onEdit: () => onEdit(5),
              ),
              
              const SizedBox(height: 48),
              CustomButton(
                text: isSubmitting ? 'Creating Workspace...' : 'Finish Setup',
                onPressed: isSubmitting ? () {} : onFinish,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        if (isSubmitting)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewSection({
    required ThemeData theme,
    required String title,
    required List<String> items,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  item,
                  style: theme.textTheme.bodyMedium,
                ),
              )),
        ],
      ),
    );
  }
}
