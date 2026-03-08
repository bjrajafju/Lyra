import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final userController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'listener';
  bool isLoading = false;

  void handleRegister() async {
    setState(() { isLoading = true; });
    bool ok = await context.read<AuthProvider>().register(userController.text, emailController.text, passwordController.text, role);
    setState(() { isLoading = false; });
    if (ok && mounted) {
      Navigator.pop(context); // go back to login or root
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: userController, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 16),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'listener', child: Text('Listener')),
                DropdownMenuItem(value: 'artist', child: Text('Artist/Band')),
              ],
              onChanged: (val) => setState(() => role = val!),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 32),
            isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: handleRegister, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
