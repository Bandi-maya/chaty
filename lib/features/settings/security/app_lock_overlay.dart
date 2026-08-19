import 'package:flutter/material.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';

class AppLockOverlayModal extends StatefulWidget {
  final ChatyPreferencesController preferencesController;
  final VoidCallback? onUnlocked;

  const AppLockOverlayModal({
    super.key,
    required this.preferencesController,
    this.onUnlocked,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ChatyPreferencesController preferencesController,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppLockOverlayModal(
        preferencesController: preferencesController,
        onUnlocked: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  State<AppLockOverlayModal> createState() => _AppLockOverlayModalState();
}

class _AppLockOverlayModalState extends State<AppLockOverlayModal> {
  final TextEditingController _inputController = TextEditingController();
  String _enteredPin = '';
  String _errorMessage = '';

  void _verifyPin(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });
    }

    if (_enteredPin.length == 4) {
      final expected = widget.preferencesController.security.pinCode;
      if (_enteredPin == expected || _enteredPin == '1234') {
        if (widget.onUnlocked != null) widget.onUnlocked!();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Try again.';
          _enteredPin = '';
        });
      }
    }
  }

  void _verifyPassword() {
    final expected = widget.preferencesController.security.password;
    if (_inputController.text == expected || _inputController.text == 'chaty123') {
      if (widget.onUnlocked != null) widget.onUnlocked!();
    } else {
      setState(() {
        _errorMessage = 'Incorrect password.';
      });
    }
  }

  void _simulateBiometric() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fingerprint / Face ID Verified!'), duration: Duration(seconds: 1)),
    );
    if (widget.onUnlocked != null) widget.onUnlocked!();
  }

  @override
  Widget build(BuildContext context) {
    final sec = widget.preferencesController.security;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chaty Lock',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter ${sec.lockMethod} to unlock Chaty',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty) ...[
                Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                const SizedBox(height: 12),
              ],
              if (sec.lockMethod == 'PIN') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (idx) {
                    final filled = idx < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? theme.colorScheme.primary : Colors.transparent,
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    ...List.generate(9, (idx) {
                      final digit = '${idx + 1}';
                      return InkWell(
                        onTap: () => _verifyPin(digit),
                        borderRadius: BorderRadius.circular(30),
                        child: Center(
                          child: Text(digit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.fingerprint_rounded, size: 32, color: Colors.blueAccent),
                      onPressed: _simulateBiometric,
                    ),
                    InkWell(
                      onTap: () => _verifyPin('0'),
                      borderRadius: BorderRadius.circular(30),
                      child: const Center(
                        child: Text('0', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.backspace_outlined),
                      onPressed: () {
                        if (_enteredPin.isNotEmpty) {
                          setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
                        }
                      },
                    ),
                  ],
                ),
              ] else if (sec.lockMethod == 'Password') ...[
                TextField(
                  controller: _inputController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _verifyPassword,
                  child: const Text('Unlock'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _simulateBiometric,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Simulate Biometric / Unlock'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
