import 'package:cctv/shared/models/app_models.dart';
import 'package:cctv/shared/state/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _useOtp = false;
  AppRole _selectedRole = AppRole.operator;
  bool _loading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(authProvider.notifier)
        .login(
          _identifierController.text.trim(),
          _passwordController.text,
          _selectedRole,
        );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enterprise CCTV',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'Email or phone',
                    child: TextField(
                      controller: _identifierController,
                      minLines: 1,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Email or phone',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_useOtp,
                    minLines: 1,
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: _useOtp ? 'OTP code' : 'Password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('OTP fallback'),
                    value: _useOtp,
                    onChanged: (value) => setState(() => _useOtp = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AppRole>(
                    initialValue: _selectedRole,
                    items: AppRole.values
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (role) => setState(
                      () => _selectedRole = role ?? AppRole.operator,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Role selection',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Session expired'),
                          content: const Text(
                            'Your session has expired. Please login again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Preview session-expiry UI'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
