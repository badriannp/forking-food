import 'package:flutter/material.dart';
import 'package:forking/utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:forking/screens/login_screen.dart';
import 'package:flutter/services.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

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
                            const SizedBox(height: 144),
                            
                            _LoginButton(
                              icon: SvgPicture.asset(
                                'assets/google_logo.svg',
                                height: 20,
                                width: 20,
                              ),
                              text: 'Continue with Google',
                              color: Theme.of(context).colorScheme.surface,
                              textColor: Theme.of(context).colorScheme.onSurface,
                              onPressed: () {
                                // Google login logic
                              },
                            ),
                            const SizedBox(height: 16),
                            _LoginButton(
                              icon: Icon(Icons.facebook, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                              text: 'Continue with Facebook',
                              color: AppColors.facebookBlue,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                              onPressed: () {
                                // Facebook login logic
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(thickness: 1, indent: 12, color: Theme.of(context).colorScheme.onPrimary.withAlpha(180), endIndent: 12)),
                                Text('or', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary.withAlpha(180),)),
                                Expanded(child: Divider(thickness: 1, indent: 12, color: Theme.of(context).colorScheme.onPrimary.withAlpha(180), endIndent: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
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
  final VoidCallback onPressed;

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
