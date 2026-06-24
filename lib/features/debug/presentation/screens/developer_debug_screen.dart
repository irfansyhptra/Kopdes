import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/health_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/debug_logger_provider.dart';

class DeveloperDebugScreen extends ConsumerStatefulWidget {
  const DeveloperDebugScreen({super.key});

  @override
  ConsumerState<DeveloperDebugScreen> createState() =>
      _DeveloperDebugScreenState();
}

class _DeveloperDebugScreenState extends ConsumerState<DeveloperDebugScreen> {
  String _jwtToken = 'Loading...';
  String _refreshToken = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final storage = ref.read(secureStorageProvider);
    final jwt = await storage.read(key: AppConstants.tokenKey) ?? 'Not Found';
    final refresh =
        await storage.read(key: AppConstants.refreshTokenKey) ?? 'Not Found';
    if (mounted) {
      setState(() {
        _jwtToken = jwt;
        _refreshToken = refresh;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final healthState = ref.watch(healthProvider);
    final debugLogs = ref.watch(debugLogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Debug Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTokens();
              ref.read(healthProvider.notifier).checkServerHealth();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Backend URL & Health
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BACKEND CONFIG',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildDebugRow('Base URL', ApiConfig.baseUrl),
                  _buildDebugRow(
                    'API Status',
                    healthState == HealthState.healthy
                        ? 'ONLINE'
                        : healthState == HealthState.checking
                        ? 'CHECKING...'
                        : 'UNREACHABLE',
                    valueColor: healthState == HealthState.healthy
                        ? Colors.green
                        : healthState == HealthState.checking
                        ? Colors.orange
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // 2. Authentication State
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTH STATE',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildDebugRow('Status', authState.status.name),
                  _buildDebugRow('User Name', authState.user?.name ?? 'Null'),
                  _buildDebugRow('User Email', authState.user?.email ?? 'Null'),
                  _buildDebugRow(
                    'User Role',
                    authState.user?.role ?? 'Null',
                    valueColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // 3. Security Tokens
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECURITY TOKENS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildTokenRow('Access Token (JWT)', _jwtToken),
                  const SizedBox(height: 8),
                  _buildTokenRow('Refresh Token', _refreshToken),
                ],
              ),
            ),
          ),

          // 4. Live Request & Response Logs
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST HTTP TRANSACTION LOG',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Last Request:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      debugLogs.lastRequest ?? 'No request logged yet',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last Response:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      debugLogs.lastResponse ?? 'No response logged yet',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
