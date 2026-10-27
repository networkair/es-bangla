import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../home/presentation/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  int _selectedSemester = 3;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.length < 6) {
      setState(() => _errorMessage = 'অনুগ্রহ করে সঠিক ইমেইল এবং কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড দিন।');
      return;
    }

    if (_isSignUp && name.isEmpty) {
      setState(() => _errorMessage = 'অনুগ্রহ করে আপনার পুরো নাম লিখুন।');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCred;
      if (_isSignUp) {
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'provider': 'password',
          'class': '12',
          'semester': _selectedSemester,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        // Save local
        final storage = LocalStorageService();
        storage.userName = name;
        storage.userEmail = email;
        storage.semester = _selectedSemester;
      } else {
        userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Fetch user data
        final doc = await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).get();
        final storage = LocalStorageService();
        if (doc.exists) {
          final data = doc.data()!;
          storage.userName = data['name'] ?? 'Student';
          storage.userEmail = email;
          storage.semester = data['semester'] ?? 3;

          await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'এই ইমেইলটি দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট রয়েছে।';
        } else {
          _errorMessage = e.message ?? 'লগইন ব্যর্থ হয়েছে।';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'একটি অপ্রত্যাশিত সমস্যা হয়েছে।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সাহায্য প্রয়োজন?'),
        content: const Text(
          'পাসওয়ার্ড ভুলে গেলে বা অ্যাকাউন্টে সমস্যা হলে সরাসরি WhatsApp বা ফোনে আমাদের সাথে যোগাযোগ করুন। অ্যাডমিন আপনার পাসওয়ার্ড রিসেট করে দেবেন।\n\n'
          'WhatsApp: ${ApiConstants.defaultWhatsappNumber}\n'
          'Email: support@esbangla.app',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ঠিক আছে')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo / Title
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Es Bangla',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'দ্বাদশ শ্রেণি সেমিস্টার ৩ ও ৪ প্রস্তুতি অ্যাপ',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Card container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.Border.all(color: AppColors.border),
                    boxShadow: AppColors.softCardShadow,
                  ),
                  child: Column(
                    children: [
                      // Toggle Tab
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !_isSignUp ? AppColors.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_isSignUp ? AppColors.softCardShadow : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'লগইন (Login)',
                                      style: TextStyle(
                                        fontWeight: !_isSignUp ? FontWeight.bold : FontWeight.normal,
                                        color: !_isSignUp ? AppColors.primary : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isSignUp = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isSignUp ? AppColors.surface : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _isSignUp ? AppColors.softCardShadow : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'সাইন আপ (Sign Up)',
                                      style: TextStyle(
                                        fontWeight: _isSignUp ? FontWeight.bold : FontWeight.normal,
                                        color: _isSignUp ? AppColors.primary : AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign Up extra fields
                      if (_isSignUp) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'আপনার পুরো নাম',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  'Class 12',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedSemester,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                                items: const [
                                  DropdownMenuItem(value: 3, child: Text('Semester 3')),
                                  DropdownMenuItem(value: 4, child: Text('Semester 4')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSemester = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Email & Password
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ইমেইল অ্যাড্রেস',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.wrongRed, fontSize: 13, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isSignUp ? 'অ্যাকাউন্ট তৈরি করুন' : 'লগইন করুন',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Help link
                TextButton.icon(
                  onPressed: _showHelpDialog,
                  icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.textSecondary),
                  label: const Text(
                    'লগইনে সমস্যা বা পাসওয়ার্ড ভুলে গেছেন? সহায়তা নিন',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
