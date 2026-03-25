import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../chat/chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoginMode = true; // Toggle between Login and Register

  void _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (_isLoginMode) {
      result = await _authService.login(_usernameController.text, _passwordController.text);
    } else {
      result = await _authService.register(_usernameController.text, _passwordController.text);
      if (result['success']) {
        // Auto-login after successful registration
        result = await _authService.login(_usernameController.text, _passwordController.text);
      }
    }

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Mora A.I Interface!', style: TextStyle(color: Colors.greenAccent))),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
    } 
    }else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'], style: const TextStyle(color: Colors.redAccent))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              const Icon(Icons.smart_toy_outlined, size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              Text(
                _isLoginMode ? 'SYSTEM LOGIN' : 'INITIALIZE USER',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person, color: Colors.cyan)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock, color: Colors.cyan)),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.cyanAccent)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                          side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isLoginMode ? 'ENGAGE' : 'REGISTER',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode ? 'No profile? Initialize new user.' : 'Existing profile? Engage login.',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}