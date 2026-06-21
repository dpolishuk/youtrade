import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/exchange_credentials.dart';
import '../../domain/entities/venue.dart';
import '../../presentation/exchange/exchange_credentials_provider.dart';
import '../../presentation/exchange/exchange_credentials_state.dart';
import '../../presentation/theme/theme_extensions.dart';

class ExchangeDetailEditScreen extends ConsumerStatefulWidget {
  const ExchangeDetailEditScreen({required this.venue, super.key});

  final Venue venue;

  @override
  ConsumerState<ExchangeDetailEditScreen> createState() =>
      _ExchangeDetailEditScreenState();
}

class _ExchangeDetailEditScreenState
    extends ConsumerState<ExchangeDetailEditScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _secretController;
  bool _isEnabled = true;
  bool _obscureSecret = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _secretController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredential();
    });
  }

  Future<void> _loadCredential() async {
    final repository = ref.read(exchangeCredentialsRepositoryProvider);
    final result = await repository.load(widget.venue);
    result.when(
      success: (credential) {
        if (credential != null && mounted) {
          setState(() {
            _apiKeyController.text = credential.apiKey;
            _secretController.text = credential.secret;
            _isEnabled = credential.isEnabled;
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      failure: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorTheme>()!;
    final state = ref.watch(exchangeCredentialsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.venue.displayName} API'),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: () => _save(), child: const Text('Save')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPermissionHint(theme, colors),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          hintText: 'Paste read-only API key',
                        ),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _secretController,
                        decoration: InputDecoration(
                          labelText: 'API Secret',
                          hintText: 'Paste API secret',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureSecret
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureSecret = !_obscureSecret;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureSecret,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _isEnabled,
                        onChanged: (value) {
                          setState(() => _isEnabled = value);
                        },
                        title: const Text('Enabled'),
                        subtitle: Text(
                          'Include this exchange in portfolio aggregation',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.subtleText,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _canTest() ? _testConnection : null,
                          icon: state is ExchangeCredentialsTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.network_check),
                          label: const Text('Test connection'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state is ExchangeCredentialsTestSuccess)
                        _buildTestResult(
                          'Connection successful',
                          colors.bullish,
                          Icons.check_circle,
                        )
                      else if (state is ExchangeCredentialsTestFailure)
                        _buildTestResult(
                          'Connection failed',
                          colors.bearish,
                          Icons.error,
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _delete(),
                          icon: Icon(
                            Icons.delete_outline,
                            color: colors.bearish,
                          ),
                          label: Text(
                            'Delete credentials',
                            style: TextStyle(color: colors.bearish),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.bearish),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionHint(ThemeData theme, AppColorTheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceGlass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Read-only access only',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an API key with read-only permissions (no trading or '
                  'withdrawals). YouTrade stores keys encrypted on your device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.subtleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  bool _canTest() {
    return _apiKeyController.text.isNotEmpty &&
        _secretController.text.isNotEmpty;
  }

  Future<void> _save() async {
    final credential = ExchangeCredentials(
      venue: widget.venue,
      apiKey: _apiKeyController.text.trim(),
      secret: _secretController.text.trim(),
      isEnabled: _isEnabled,
    );

    await ref
        .read(exchangeCredentialsNotifierProvider.notifier)
        .save(credential);
    if (!mounted) return;
    final state = ref.read(exchangeCredentialsNotifierProvider);
    if (state is ExchangeCredentialsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${state.failure.message}')),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _testConnection() {
    final credential = ExchangeCredentials(
      venue: widget.venue,
      apiKey: _apiKeyController.text.trim(),
      secret: _secretController.text.trim(),
      isEnabled: _isEnabled,
    );

    ref
        .read(exchangeCredentialsNotifierProvider.notifier)
        .testConnection(credential);
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).extension<AppColorTheme>()!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete credentials?'),
        content: Text(
          'This will remove the saved API key and secret for '
          '${widget.venue.displayName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: colors.bearish)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref
        .read(exchangeCredentialsNotifierProvider.notifier)
        .delete(widget.venue);
    if (!mounted) return;
    final state = ref.read(exchangeCredentialsNotifierProvider);
    if (state is ExchangeCredentialsError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${state.failure.message}')),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
