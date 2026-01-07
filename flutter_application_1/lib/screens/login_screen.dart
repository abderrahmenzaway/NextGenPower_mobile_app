import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String factoryId, String factoryName) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _factoryIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _factoryNameController = TextEditingController();
  final _initialBalanceController = TextEditingController(text: '1000');
  final _currencyBalanceController = TextEditingController(text: '500');
  String _selectedEnergyType = 'Solar';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _factoryIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _factoryNameController.dispose();
    _initialBalanceController.dispose();
    _currencyBalanceController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_isLogin) {
      // For login, call the API with factoryId and password
      final factoryId = _factoryIdController.text.trim();
      final password = _passwordController.text;
      
      if (factoryId.isEmpty || password.isEmpty) {
        _showError('Please enter your Factory ID and password');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final result = await ApiService.loginFactory(
          factoryId: factoryId,
          password: password,
        );

        if (!mounted) return;
        
        // Extract factory name from response
        final factoryData = result['data'] as Map<String, dynamic>;
        final factoryName = factoryData['name'] as String? ?? factoryId;
        
        widget.onLogin(factoryId, factoryName);
      } on ApiException catch (e) {
        _showError(e.message);
      } catch (e) {
        _showError('Connection error: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // For registration, call the API
      final factoryId = _factoryIdController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final factoryName = _factoryNameController.text.trim();
      final initialBalance = double.tryParse(_initialBalanceController.text) ?? 0;
      final currencyBalance = double.tryParse(_currencyBalanceController.text) ?? 0;

      if (factoryId.isEmpty || factoryName.isEmpty || password.isEmpty) {
        _showError('Please fill in all required fields');
        return;
      }

      if (password.length < 6) {
        _showError('Password must be at least 6 characters long');
        return;
      }

      if (password != confirmPassword) {
        _showError('Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);

      try {
        await ApiService.registerFactory(
          factoryId: factoryId,
          name: factoryName,
          password: password,
          initialBalance: initialBalance,
          energyType: _selectedEnergyType,
          currencyBalance: currencyBalance,
        );

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Factory "$factoryName" registered successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onLogin(factoryId, factoryName);
      } on ApiException catch (e) {
        _showError(e.message);
      } catch (e) {
        _showError('Connection error: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0a0a0a),
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.grey.shade900.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'lib/screens/assets/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Next Gen Power',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Peer-to-Peer Energy Trading Platform',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Tabs
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _isLogin = true),
                              style: TextButton.styleFrom(
                                backgroundColor: _isLogin
                                    ? Colors.grey.shade800
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _isLogin = false),
                              style: TextButton.styleFrom(
                                backgroundColor: !_isLogin
                                    ? Colors.grey.shade800
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Register Factory'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Form
                      TextField(
                        controller: _factoryIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Factory ID',
                          hintText: 'e.g., F-001',
                          labelStyle: const TextStyle(color: Colors.grey),
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade800,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isLogin) ...[
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                      
                      if (!_isLogin) ...[
                        TextField(
                          controller: _factoryNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Factory Name',
                            hintText: 'e.g., Solar Factory Alpha',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _initialBalanceController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Initial Energy Balance (kWh)',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _currencyBalanceController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Initial TEC Balance',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'Starting currency balance',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEnergyType,
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: Colors.grey.shade800,
                          decoration: InputDecoration(
                            labelText: 'Energy Type',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['Solar', 'Wind', 'Hydro', 'Biomass', 'Mixed']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEnergyType = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            hintText: 'At least 6 characters',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLogin
                                ? Colors.blue.shade600
                                : Colors.purple.shade600,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isLogin ? Icons.login : Icons.add_business,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLogin ? 'Login to Dashboard' : 'Register Factory',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isLogin
                            ? 'Enter your Factory ID to access the dashboard'
                            : 'Register your factory on the blockchain network',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
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
