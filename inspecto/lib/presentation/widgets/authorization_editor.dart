import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';

class AuthorizationEditor extends StatelessWidget {
  const AuthorizationEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auth Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.authType,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: [
                  _buildAuthItem('none', 'No Auth'),
                  _buildAuthItem('basic', 'Basic Auth'),
                  _buildAuthItem('bearer', 'Bearer Token'),
                  _buildAuthItem('apiKey', 'API Key'),
                ],
                onChanged: (val) {
                  if (val != null) provider.setAuthType(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildAuthFields(context, provider),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildAuthItem(String value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildAuthFields(BuildContext context, RequestProvider provider) {
    switch (provider.authType) {
      case 'basic':
        return _buildBasicAuth(context, provider);
      case 'bearer':
        return _buildBearerAuth(context, provider);
      case 'apiKey':
        return _buildApiKeyAuth(context, provider);
      default:
        return _buildNoAuth(context);
    }
  }

  Widget _buildNoAuth(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open_rounded,
              size: 48, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'This request does not use any authorization.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAuth(BuildContext context, RequestProvider provider) {
    return Column(
      children: [
        _buildTextField(
          context,
          label: 'Username',
          initialValue: provider.authDetails['username'] ?? '',
          onChanged: (val) => provider.updateAuthDetail('username', val),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context,
          label: 'Password',
          isPassword: true,
          initialValue: provider.authDetails['password'] ?? '',
          onChanged: (val) => provider.updateAuthDetail('password', val),
        ),
      ],
    );
  }

  Widget _buildBearerAuth(BuildContext context, RequestProvider provider) {
    return Column(
      children: [
        _buildTextField(
          context,
          label: 'Token',
          initialValue: provider.authDetails['token'] ?? '',
          onChanged: (val) => provider.updateAuthDetail('token', val),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Text(
          'Bearer tokens are added to the "Authorization" header as "Bearer <token>".',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildApiKeyAuth(BuildContext context, RequestProvider provider) {
    return Column(
      children: [
        _buildTextField(
          context,
          label: 'Key',
          initialValue: provider.authDetails['key'] ?? '',
          onChanged: (val) => provider.updateAuthDetail('key', val),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context,
          label: 'Value',
          initialValue: provider.authDetails['value'] ?? '',
          onChanged: (val) => provider.updateAuthDetail('value', val),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Add to: ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(width: 8),
            _buildChoiceChip(context, 'Header',
                provider.authDetails['addTo'] != 'query',
                () => provider.updateAuthDetail('addTo', 'header')),
            const SizedBox(width: 8),
            _buildChoiceChip(context, 'Query Params',
                provider.authDetails['addTo'] == 'query',
                () => provider.updateAuthDetail('addTo', 'query')),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          obscureText: isPassword,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChoiceChip(BuildContext context, String label, bool selected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      showCheckmark: false,
    );
  }
}
