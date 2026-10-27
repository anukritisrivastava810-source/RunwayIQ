import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/scenario/data/repositories/scenario_repository.dart';
import '../features/scenario/domain/models/scenario.dart';
import '../features/scenario/domain/repositories/scenario_repository_interface.dart';
import '../widgets/stats_card.dart';

class RunwayScreen extends StatefulWidget {
  final IScenarioRepository? scenarioRepository;
  final CompanyRepository? companyRepository;

  const RunwayScreen({
    super.key,
    this.scenarioRepository,
    this.companyRepository,
  });

  @override
  State<RunwayScreen> createState() => _RunwayScreenState();
}

class _RunwayScreenState extends State<RunwayScreen> {
  late final IScenarioRepository _scenarioRepo;
  late final CompanyRepository _companyRepo;

  bool _isLoading = true;
  bool _isSimulating = false;
  bool _isSavingScenario = false;
  bool _isUpdatingScenario = false;
  bool _isDeletingScenario = false;
  String? _errorMessage;

  Company? _company;
  SimulationResult? _baselineResult;
  SimulationResult? _simulationResult;
  List<Scenario> _scenarios = [];
  Scenario? _selectedScenario;

  final TextEditingController _burnController = TextEditingController();
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scenarioRepo = widget.scenarioRepository ?? ScenarioRepository();
    _companyRepo = widget.companyRepository ?? CompanyRepository();
    _loadInitialData();
  }

  @override
  void dispose() {
    _burnController.dispose();
    _revenueController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  bool get _isBusy =>
      _isSimulating || _isSavingScenario || _isUpdatingScenario || _isDeletingScenario;

  // ─── Data Loading ────────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final companies = await _companyRepo.getCompanies();
      if (!mounted) return;

      if (companies.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No company found. Please complete onboarding.';
        });
        return;
      }

      final company = companies.first;

      final results = await Future.wait([
        _scenarioRepo
            .getScenariosByCompany(company.id!)
            .then<Object>((v) => v)
            .catchError((e) => <Scenario>[]),
        _scenarioRepo
            .simulate(companyId: company.id!)
            .then<Object>((v) => v)
            .catchError((e) => e),
      ]);

      if (!mounted) return;

      final scenarios = results[0] as List<Scenario>;
      final baselineOrError = results[1];

      SimulationResult? baseline;
      String? baselineError;
      if (baselineOrError is SimulationResult) {
        baseline = baselineOrError;
      } else if (baselineOrError is Exception) {
        baselineError = baselineOrError.toString();
      }

      setState(() {
        _company = company;
        _scenarios = scenarios;
        _baselineResult = baseline;
        _errorMessage = baselineError;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ─── Simulation ──────────────────────────────────────────────────────────────

  Future<void> _runSimulation() async {
    if (_company?.id == null || _isBusy) return;

    final addBurn = double.tryParse(_burnController.text.trim()) ?? 0.0;
    final addRevenue = double.tryParse(_revenueController.text.trim()) ?? 0.0;
    final addCash = double.tryParse(_cashController.text.trim()) ?? 0.0;

    setState(() => _isSimulating = true);
    try {
      final result = await _scenarioRepo.simulate(
        companyId: _company!.id!,
        additionalBurn: addBurn,
        additionalRevenue: addRevenue,
        additionalCash: addCash,
      );
      if (!mounted) return;
      setState(() {
        _simulationResult = result;
        _isSimulating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSimulating = false);
      _showError('Simulation failed: $e');
    }
  }

  Future<void> _loadSavedScenarioSimulation(Scenario scenario) async {
    if (_isBusy) return;
    setState(() {
      _selectedScenario = scenario;
      _burnController.text = scenario.additionalBurn > 0
          ? scenario.additionalBurn.toStringAsFixed(0)
          : '';
      _revenueController.text = scenario.additionalRevenue > 0
          ? scenario.additionalRevenue.toStringAsFixed(0)
          : '';
      _cashController.text = scenario.additionalCash > 0
          ? scenario.additionalCash.toStringAsFixed(0)
          : '';
      _isSimulating = true;
    });

    try {
      final result = await _scenarioRepo.simulate(
        companyId: _company!.id!,
        scenarioId: scenario.id,
      );
      if (!mounted) return;
      setState(() {
        _simulationResult = result;
        _isSimulating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSimulating = false);
      _showError('Failed to load scenario: $e');
    }
  }

  // ─── Save / Update / Delete Scenarios ────────────────────────────────────────

  Future<void> _saveScenario(String name) async {
    if (_company?.id == null || _isBusy) return;

    final addBurn = double.tryParse(_burnController.text.trim()) ?? 0.0;
    final addRevenue = double.tryParse(_revenueController.text.trim()) ?? 0.0;
    final addCash = double.tryParse(_cashController.text.trim()) ?? 0.0;

    final baseline = _baselineResult?.baseline;

    final scenario = Scenario(
      companyId: _company!.id!,
      name: name,
      baseCash: baseline?.cash ?? 0.0,
      baseMonthlyBurn: baseline?.burn ?? 0.0,
      baseMonthlyRevenue: 0.0,
      baseRunwayMonths: baseline?.runway ?? 0.0,
      additionalBurn: addBurn,
      additionalRevenue: addRevenue,
      additionalCash: addCash,
      currency: _company!.currency,
    );

    setState(() => _isSavingScenario = true);
    try {
      final created = await _scenarioRepo.createScenario(scenario);
      if (!mounted) return;
      final refreshed =
          await _scenarioRepo.getScenariosByCompany(_company!.id!);
      if (!mounted) return;
      setState(() {
        _scenarios = refreshed;
        _selectedScenario = created;
        _isSavingScenario = false;
      });
      _showMessage('Scenario saved successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingScenario = false);
      _showError('Save failed: $e');
    }
  }

  Future<void> _updateCurrentScenario() async {
    if (_selectedScenario?.id == null || _company?.id == null || _isBusy) return;

    final addBurn = double.tryParse(_burnController.text.trim()) ?? 0.0;
    final addRevenue = double.tryParse(_revenueController.text.trim()) ?? 0.0;
    final addCash = double.tryParse(_cashController.text.trim()) ?? 0.0;

    final confirmedName = await showDialog<String>(
      context: context,
      builder: (ctx) => _UpdateScenarioDialog(
        initialName: _selectedScenario!.name,
      ),
    );

    if (confirmedName == null || confirmedName.isEmpty) return;

    setState(() => _isUpdatingScenario = true);
    try {
      final updated = _selectedScenario!.copyWith(
        name: confirmedName,
        additionalBurn: addBurn,
        additionalRevenue: addRevenue,
        additionalCash: addCash,
      );
      final result =
          await _scenarioRepo.updateScenario(updated.id!, updated);
      if (!mounted) return;
      final refreshed =
          await _scenarioRepo.getScenariosByCompany(_company!.id!);
      if (!mounted) return;
      setState(() {
        _scenarios = refreshed;
        _selectedScenario = result;
        _isUpdatingScenario = false;
      });
      _showMessage('Scenario updated successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingScenario = false);
      _showError('Update failed: $e');
    }
  }

  Future<void> _deleteScenario(Scenario scenario) async {
    if (scenario.id == null || _isBusy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scenario'),
        content: Text('Delete "${scenario.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeletingScenario = true);
    try {
      await _scenarioRepo.deleteScenario(scenario.id!);
      if (!mounted) return;
      final refreshed =
          await _scenarioRepo.getScenariosByCompany(_company!.id!);
      if (!mounted) return;
      setState(() {
        _scenarios = refreshed;
        if (_selectedScenario?.id == scenario.id) {
          _selectedScenario = null;
          _simulationResult = null;
        }
        _isDeletingScenario = false;
      });
      _showMessage('Scenario deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingScenario = false);
      _showError('Delete failed: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final absAmount = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    final symbol = _currencySymbol(currency);
    if (absAmount >= 1000000) {
      return '$prefix$symbol${(absAmount / 1000000).toStringAsFixed(1)}M';
    }
    if (absAmount >= 1000) {
      return '$prefix$symbol${(absAmount / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix$symbol${absAmount.toStringAsFixed(0)}';
  }

  String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }

  String _formatRunway(double? runway) {
    if (runway == null) return '∞';
    if (runway <= 0) return '0';
    return runway.toStringAsFixed(1);
  }

  String _runwayLabel(double? runway) {
    if (runway == null) return 'Unlimited';
    if (runway <= 0) return 'Depleted';
    return 'Months';
  }

  Future<void> _showSaveDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _SaveScenarioDialog(),
    );
    if (name != null && name.isNotEmpty) {
      await _saveScenario(name);
    }
  }

  void _resetSimulation() {
    setState(() {
      _selectedScenario = null;
      _simulationResult = null;
      _burnController.clear();
      _revenueController.clear();
      _cashController.clear();
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _company == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Runway Analysis')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final baseline = _baselineResult?.baseline;
    final simulated = _simulationResult?.simulated;
    final currency = _company?.currency ?? 'USD';

    final displayRunway = simulated?.runway ?? baseline?.runway;
    final displayCash = simulated?.cash ?? baseline?.cash ?? 0.0;
    final displayBurn = simulated?.burn ?? baseline?.burn ?? 0.0;

    final progressValue = displayRunway == null
        ? 1.0
        : (displayRunway / 24.0).clamp(0.0, 1.0);
    final isLowRunway =
        displayRunway != null && displayRunway > 0 && displayRunway < 6;
    final isUnlimited = displayRunway == null;
    final isDepleted = displayRunway != null && displayRunway <= 0;

    final runwayColor = isLowRunway || isDepleted
        ? theme.colorScheme.error
        : isUnlimited
            ? Colors.green
            : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runway Analysis'),
        actions: [
          if (_simulationResult != null || _selectedScenario != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to Baseline',
              onPressed: _resetSimulation,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulate scenarios to see impact on survival.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Circular Runway Indicator ──────────────────────────────────
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 12,
                        backgroundColor: theme.colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(runwayColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatRunway(displayRunway),
                          style: theme.textTheme.displayLarge
                              ?.copyWith(color: runwayColor),
                        ),
                        Text(
                          _runwayLabel(displayRunway),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Stats Cards ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Cash Available',
                      value: _formatCurrency(displayCash, currency),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: _simulationResult != null
                          ? 'Projected Burn'
                          : 'Monthly Burn',
                      value: _formatCurrency(displayBurn, currency),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Simulation Inputs ─────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Adjust Scenario',
                    style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 12),

              _buildNumericField(
                controller: _burnController,
                label: 'Additional Monthly Burn',
                hint: 'e.g. 15000',
                prefix: _currencySymbol(currency),
              ),
              const SizedBox(height: 12),
              _buildNumericField(
                controller: _revenueController,
                label: 'Additional Monthly Revenue',
                hint: 'e.g. 5000',
                prefix: _currencySymbol(currency),
              ),
              const SizedBox(height: 12),
              _buildNumericField(
                controller: _cashController,
                label: 'Additional Cash Injection',
                hint: 'e.g. 500000',
                prefix: _currencySymbol(currency),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _runSimulation,
                    icon: _isSimulating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isSimulating ? 'Simulating…' : 'Simulate'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _showSaveDialog,
                    icon: _isSavingScenario
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                  ),
                  if (_selectedScenario != null)
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _updateCurrentScenario,
                      icon: _isUpdatingScenario
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_outlined),
                      label: const Text('Update Selected'),
                    ),
                ],
              ),

              // ── Simulation Results ────────────────────────────────────────
              if (_simulationResult != null) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Simulation Results',
                      style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 12),
                _buildSimResultCard(_simulationResult!, currency, theme),
              ],

              const SizedBox(height: 32),

              // ── Saved Scenarios ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text('Saved Scenarios',
                        style: theme.textTheme.titleLarge),
                  ),
                  if (_isBusy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_scenarios.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.folder_open_outlined,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('No saved scenarios yet.',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Adjust the inputs above and tap Save.',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._scenarios.map((s) => _buildScenarioCard(s, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String prefix = '\$',
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildSimResultCard(
      SimulationResult result, String currency, ThemeData theme) {
    final b = result.baseline;
    final s = result.simulated;
    final adj = result.adjustments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baseline', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _simRow('Cash', _formatCurrency(b.cash, currency), theme),
            _simRow('Monthly Burn', _formatCurrency(b.burn, currency), theme),
            _simRow(
              'Runway',
              b.runway == null
                  ? 'Unlimited runway'
                  : b.runway! <= 0
                      ? '0 mo (Depleted)'
                      : '${b.runway!.toStringAsFixed(1)} mo',
              theme,
            ),
            const Divider(height: 20),
            Text('Adjustments', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            if (adj.additionalBurn != 0)
              _simRow('+Burn', _formatCurrency(adj.additionalBurn, currency),
                  theme),
            if (adj.additionalRevenue != 0)
              _simRow('+Revenue',
                  _formatCurrency(adj.additionalRevenue, currency), theme),
            if (adj.additionalCash != 0)
              _simRow(
                  '+Cash', _formatCurrency(adj.additionalCash, currency), theme),
            const Divider(height: 20),
            Text('Simulated', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _simRow('Cash', _formatCurrency(s.cash, currency), theme,
                highlight: true),
            _simRow('Monthly Burn', _formatCurrency(s.burn, currency), theme,
                highlight: true),
            _simRow(
              'Runway',
              s.runway == null
                  ? 'Unlimited runway'
                  : s.runway! <= 0
                      ? '0 mo (Depleted)'
                      : '${s.runway!.toStringAsFixed(1)} mo',
              theme,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _simRow(String label, String value, ThemeData theme,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Scenario scenario, ThemeData theme) {
    final isSelected = _selectedScenario?.id == scenario.id;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? theme.colorScheme.primary.withAlpha(26)
          : theme.colorScheme.surface,
      child: ListTile(
        selected: isSelected,
        title: Text(
          scenario.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _scenarioSubtitle(scenario),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete scenario',
              onPressed: _isBusy ? null : () => _deleteScenario(scenario),
            ),
          ],
        ),
        onTap: _isBusy ? null : () => _loadSavedScenarioSimulation(scenario),
      ),
    );
  }

  String _scenarioSubtitle(Scenario scenario) {
    final parts = <String>[];
    if (scenario.additionalBurn > 0) {
      parts.add('+${scenario.additionalBurn.toStringAsFixed(0)} burn');
    }
    if (scenario.additionalRevenue > 0) {
      parts.add('+${scenario.additionalRevenue.toStringAsFixed(0)} revenue');
    }
    if (scenario.additionalCash > 0) {
      parts.add('+${scenario.additionalCash.toStringAsFixed(0)} cash');
    }
    return parts.isEmpty ? 'No adjustments' : parts.join(' · ');
  }
}

class _SaveScenarioDialog extends StatefulWidget {
  const _SaveScenarioDialog();

  @override
  State<_SaveScenarioDialog> createState() => _SaveScenarioDialogState();
}

class _SaveScenarioDialogState extends State<_SaveScenarioDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Scenario'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Scenario Name',
          hintText: 'e.g. Hire 2 Engineers',
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _UpdateScenarioDialog extends StatefulWidget {
  final String initialName;

  const _UpdateScenarioDialog({required this.initialName});

  @override
  State<_UpdateScenarioDialog> createState() => _UpdateScenarioDialogState();
}

class _UpdateScenarioDialogState extends State<_UpdateScenarioDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Scenario'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Scenario Name',
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
