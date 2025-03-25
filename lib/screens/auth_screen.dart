import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Track current view
  bool _showLogin = true;
  bool _isLoading = false;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
      // Clear fields when toggling
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _nameController.clear();
    });
  }

  Future<bool> signUp(String email, String password) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await supabase.Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('Auth sign-up successful: ${response.user!.email}');
        
        try {
          final result = await supabase.Supabase.instance.client
              .rpc('register_user', params: {
                'p_user_id': response.user!.id,
                'p_user_email': email,
                'p_user_name': _nameController.text,
                'p_user_phone': _phoneController.text,
              });
          
          print('Profile data registration successful');
          return true;
        } catch (profileError) {
          print('Error registering profile data: $profileError');
          
          // Attempt to delete the created auth user to maintain atomicity
          try {
            // Note: No Rollback method yet
            print('Attempting to rollback auth registration...');
          } catch (rollbackError) {
            print('Could not rollback auth registration: $rollbackError');
          }
          
          return false;
        }
      } else {
        print('Error signing up - auth failed');
        return false;
      }
    } catch (e) {
        print('Error signing up: $e');
        return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Print the login data to console
    print('Login Data:');
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');

    try {
      // Sign in using the auth service
      final response = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (response.user != null && response.session != null) {
        if (mounted) {
          // Success - navigate to Home
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const HomeScreen())
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please check your credentials.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF2979FF),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_showLogin ? -1.0 : 1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _showLogin ? _buildLoginForm() : _buildSignUpForm(),
              ),
            ),

            // Bottom navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showLogin
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleView,
                      child: Text(
                        _showLogin ? 'Sign Up' : 'Login',
                        style: TextStyle(
                          color: const Color(0xFF2979FF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      key: const ValueKey<String>('login'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Logo and app name
          Center(
            child: SvgPicture.asset(
              'assets/logo/Component_1.svg',
              height: 50,
              width: 180,
            ),
          ),
          const SizedBox(height: 48),

          // Email field
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Login button in form
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      key: const ValueKey<String>('signup'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Logo and app name
          Center(
            child: SvgPicture.asset(
              'assets/logo/Component_1.svg',
              height: 50,
              width: 180,
            ),
          ),
          const SizedBox(height: 48),

          // Phone Number field
          const Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Email field
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          const Text(
            'Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Government ID selector
          InkWell(
            onTap: () {
              print('Add government ID tapped');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '+ Add government ID',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.photo_outlined,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign Up button in form
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading 
                ? null 
                : () async {
                  final success = await signUp(
                    _emailController.text, 
                    _passwordController.text
                  );
                  if (success && mounted) {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const HomeScreen())
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign up failed. Please try again.')),
                    );
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
