import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  bool _isLogin = true;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        if (_isLogin) {
          await Provider.of<AuthProvider>(context, listen: false).login(_email, _password);
        } else {
          await Provider.of<AuthProvider>(context, listen: false).register(_name, _email, _password);
        }
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A1B9A), Color(0xFF1A1A2E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Sign in to continue' : 'Join AI Study Buddy',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (!_isLogin)
                        AnimatedOpacity(
                          opacity: _isLogin ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: const TextStyle(color: Colors.white),
                              prefixIcon: const Icon(Icons.person, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) => value!.isEmpty ? 'Enter name' : null,
                            onSaved: (value) => _name = value!,
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(Icons.email, color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value!.isEmpty ? 'Enter email' : null,
                        onSaved: (value) => _email = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'Enter password' : null,
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(height: 32),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6A1B9A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                          ),
                          child: Text(
                            _isLogin ? 'Login' : 'Register',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Create account' : 'Already have account?',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
