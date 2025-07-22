import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/models/university.dart';
import 'package:core/utils/validators.dart';
import 'package:core/utils/alert_utils.dart';
import 'package:core/services/user_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  University? _selectedUniversity;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final List<University> _universities = University.sampleUniversities;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _universityIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final success = await userProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        universityId: _universityIdController.text.trim(),
        universityName: _selectedUniversity?.name ?? '',
        phoneNumber: _phoneController.text.trim(),
        //role: '',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Show success message with custom alert
          AlertUtils.showAlert(
            context: context,
            title: 'Account Created',
            message:
                'Your account has been created successfully! Please verify your email address to continue.',
            buttonText: 'Verify Email',
            onPressed: () {
              // Close the dialog
              // Navigator.pop(context);
              // Navigate to email verification screen
              Navigator.pushReplacementNamed(context, '/email-verification');
            },
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userProvider.error)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with icon
                const Icon(
                  Icons.school_rounded,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create your student account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in all the required information',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Signup Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // University selection dropdown
                      DropdownButtonFormField<University>(
                        decoration: const InputDecoration(
                          labelText: 'Select University',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                        ),
                        hint: const Text('Select your university'),
                        value: _selectedUniversity,
                        isExpanded: true,
                        items: _universities.map((university) {
                          return DropdownMenuItem<University>(
                            value: university,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  university.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (University? newValue) {
                          setState(() {
                            _selectedUniversity = newValue;
                            // Clear email when university changes
                            _emailController.clear();
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your university';
                          }
                          return null;
                        },
                        icon: const Icon(Icons.arrow_drop_down_circle),
                        dropdownColor: Colors.white,
                      ),
                      const SizedBox(height: 30),

                      // Full name field
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => Validators.validateRequired(
                          value,
                          'Full name',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email field with domain restriction
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: _selectedUniversity != null
                              ? 'StudentID@${_selectedUniversity!.emailDomain}'
                              : 'StudentID@university.edu',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email_outlined),
                          helperText: _selectedUniversity != null
                              ? 'Must end with @${_selectedUniversity!.emailDomain}'
                              : 'Please select a university first',
                          helperStyle: TextStyle(
                            color: _selectedUniversity != null
                                ? Colors.green.shade700
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        validator: (value) => Validators.validateEmail(
                          value,
                          _selectedUniversity?.emailDomain,
                        ),
                        onChanged: (value) {
                          // Force rebuild to update validation in real time
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      // University ID field
                      TextFormField(
                        controller: _universityIdController,
                        decoration: const InputDecoration(
                          labelText: 'University ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) => Validators.validateRequired(
                          value,
                          'University ID',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone number field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: 'e.g. +20 1010023910',
                        ),
                        validator: (value) => Validators.validatePhone(value),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Signup button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : _signup,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign Up'),
                      ),
                      const SizedBox(height: 16),

                      // Login option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
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
