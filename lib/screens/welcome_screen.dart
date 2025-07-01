import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:forking/screens/auth/login_screen.dart';
import 'package:forking/screens/main_screen.dart';
import 'package:forking/services/auth_service.dart';
import 'package:flutter/services.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final userCredential = await authService.signInWithGoogle();
      
      if (userCredential != null) {
        // Successfully signed in
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        // User cancelled or error occurred
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in was cancelled or failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Future<void> _signInWithFacebook() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     final authService = AuthService();
  //     final userCredential = await authService.signInWithFacebook();
      
  //     if (userCredential != null) {
  //       // Successfully signed in
  //       if (mounted) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (_) => const MainScreen()),
  //         );
  //       }
  //     } else {
  //       // User cancelled or error occurred
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Facebook sign in was cancelled or failed'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error signing in with Facebook: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/forking-bg.jpg', fit: BoxFit.cover),
            Container(color: const Color(0x80000000)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Forking',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontFamily: 'EduNSWACTHand',
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 40,
                              ),
                            ),
                            // SizedBox(height: 4),
                            Text(
                                'WE ARE WHAT WE EAT',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 48,
                                  letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 96),
                            
                            _LoginButton(
                              icon: _isLoading 
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/google_logo.svg',
                                      height: 20,
                                      width: 20,
                                    ),
                              text: _isLoading ? 'Signing in...' : 'Continue with Google',
                              color: Theme.of(context).colorScheme.surface,
                              textColor: Theme.of(context).colorScheme.onSurface,
                              onPressed: _isLoading ? null : () => _signInWithGoogle(),
                            ),
                            const SizedBox(height: 8),
                            // _LoginButton(
                            //   icon: _isLoading 
                            //       ? SizedBox(
                            //           height: 20,
                            //           width: 20,
                            //           child: CircularProgressIndicator(
                            //             strokeWidth: 2,
                            //             valueColor: AlwaysStoppedAnimation<Color>(
                            //               Theme.of(context).colorScheme.onPrimary,
                            //             ),
                            //           ),
                            //         )
                            //       : SvgPicture.asset(
                            //           'assets/facebook_logo.svg',
                            //           height: 20,
                            //           width: 20,
                            //         ),
                            //   text: _isLoading ? 'Signing in...' : 'Continue with Facebook',
                            //   color: AppColors.facebookBlue,
                            //   textColor: Theme.of(context).colorScheme.onPrimary,
                            //   onPressed: _isLoading ? null : () => _signInWithFacebook(),
                            // ),
                            // const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(thickness: 1, indent: 12, color: Theme.of(context).colorScheme.onPrimary.withAlpha(180), endIndent: 12)),
                                Text('or', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary.withAlpha(180),)),
                                Expanded(child: Divider(thickness: 1, indent: 12, color: Theme.of(context).colorScheme.onPrimary.withAlpha(180), endIndent: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _LoginButton(
                              icon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurface.withAlpha(220)),
                              text: 'Log in using your email',
                              color: Theme.of(context).colorScheme.surface,
                              textColor: Theme.of(context).colorScheme.onSurface,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary.withAlpha(180),
                                ),
                                children: [
                                  const TextSpan(text: 'By signing up, you agree to our '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Theme.of(context).colorScheme.onPrimary.withAlpha(180),
                                      color: Theme.of(context).colorScheme.onPrimary.withAlpha(180),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        final url = Uri.parse('https://example.com/terms');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Theme.of(context).colorScheme.onPrimary.withAlpha(180),
                                      color: Theme.of(context).colorScheme.onPrimary.withAlpha(180),
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        final url = Uri.parse('https://example.com/privacy');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  const _LoginButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: icon,
        label: Text(text, style: TextStyle(color: textColor, fontSize: 16, letterSpacing: -0.1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
