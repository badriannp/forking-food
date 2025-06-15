import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? 'Login' : 'Register',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (isLogin)
                    const LoginForm()
                  else
                    const RegisterForm(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(thickness: 1, endIndent: 12)),
                      Text('or', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Expanded(child: Divider(thickness: 1, indent: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.g_mobiledata, color: theme.colorScheme.secondary),
                      label: const Text('Sign in with Google'),
                      onPressed: () {
                        // Google Sign-In logic
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      overlayColor: theme.colorScheme.primary.withAlpha(20),
                    ),
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                      });
                    },
                    child: Text(
                      isLogin ? "Don't have an account? Register!" : "Already have an account? Login!",
                    ),
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

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _firebaseError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _firebaseError = null;
    });
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authService = AuthService();
    try {
      await authService.signIn(_emailController.text, _passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (message.contains('user-not-found') || message.contains('wrong-password')) {
        setState(() {
          _firebaseError = 'Wrong email or password';
        });
      } else {
        setState(() {
          _firebaseError = 'Login failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorStyle = theme.inputDecorationTheme.errorStyle ?? TextStyle(color: theme.colorScheme.error, fontSize: 13);
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(_passwordFocus);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
              ),
              errorStyle: errorStyle,
            ),
            obscureText: true,
            onEditingComplete: () {
              FocusScope.of(context).unfocus();
              _handleLogin();
            },
          ),
          if (_firebaseError != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  _firebaseError!,
                  style: errorStyle,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _firebaseEmailError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (_firebaseEmailError != null) {
      final error = _firebaseEmailError;
      _firebaseEmailError = null; // reset after showing
      return error;
    }
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    setState(() {
      _firebaseEmailError = null;
    });
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authService = AuthService();
    try {
      await authService.register(_emailController.text, _passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created!')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (message.contains('email-already-in-use')) {
        setState(() {
          _firebaseEmailError = 'Email already in use';
        });
        // retrigger validation for email field
        _formKey.currentState!.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            validator: _validateName,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'John Doe',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(_emailFocus);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(_passwordFocus);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'At least 6 characters',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha((0.4 * 255).toInt()),
              ),
            ),
            obscureText: true,
            onEditingComplete: () {
              FocusScope.of(context).unfocus();
              _handleRegister();
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRegister,
              child: const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}