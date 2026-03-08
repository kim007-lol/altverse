import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Basic
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Step 2: Role
  String _selectedRole = 'reader';

  // Author specific
  final _penNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    _penNameCtrl.dispose();
    _bioCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validasi semua field di Step 1
      if (_nameCtrl.text.trim().isEmpty) {
        _showError('Nama wajib diisi!');
        return;
      }
      if (_emailCtrl.text.trim().isEmpty) {
        _showError('Email wajib diisi!');
        return;
      }
      if (!_emailCtrl.text.contains('@')) {
        _showError('Format email tidak valid!');
        return;
      }
      if (_passCtrl.text.isEmpty) {
        _showError('Password wajib diisi!');
        return;
      }
      if (_passCtrl.text.length < 8) {
        _showError('Password minimal 8 karakter!');
        return;
      }
      if (_passConfirmCtrl.text.isEmpty) {
        _showError('Konfirmasi password wajib diisi!');
        return;
      }
      if (_passCtrl.text != _passConfirmCtrl.text) {
        _showError('Password dan Konfirmasi tidak cocok!');
        return;
      }
      // Lolos validasi → lanjut ke Step 2
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      setState(() => _currentStep = 1);
    } else {
      // Step 2: langsung submit, tidak perlu validasi lagi
      _handleRegister();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[400]),
    );
  }

  Future<void> _handleRegister() async {
    if (_selectedRole == 'author' && _penNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pen Name wajib diisi untuk Author!')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      passwordConfirmation: _passConfirmCtrl.text,
      role: _selectedRole,
      penName: _penNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      final role = authProvider.role;
      if (role == 'author') {
        context.go('/author-home');
      } else {
        context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (_currentStep == 1) {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
              setState(() => _currentStep = 0);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? 'Create Account' : 'Choose Your Role',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1BasicData(),
          _buildStep2RoleSelection(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC084FC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: authProvider.isLoading ? null : _nextStep,
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _currentStep == 0 ? 'Continue' : 'Create Account',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1BasicData() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Join the AU Reader community!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              hintText: 'your@email.com',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'Your full name',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passConfirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2RoleSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select how you want to use AU Reader',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  title: 'Reader',
                  subtitle: 'Read & explore',
                  icon: Icons.menu_book_rounded,
                  isSelected: _selectedRole == 'reader',
                  onTap: () => setState(() => _selectedRole = 'reader'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RoleCard(
                  title: 'Author',
                  subtitle: 'Write & create',
                  icon: Icons.draw_rounded,
                  isSelected: _selectedRole == 'author',
                  onTap: () => setState(() => _selectedRole = 'author'),
                ),
              ),
            ],
          ),

          if (_selectedRole == 'reader') ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('As a Reader, you can:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('• Read and like AU stories'),
                  Text('• Follow your favorite authors'),
                  Text('• Get personalized recommendations'),
                  Text('• Collect achievements & rewards'),
                ],
              ),
            ),
          ],

          if (_selectedRole == 'author') ...[
            const SizedBox(height: 32),
            const Text('Pen Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _penNameCtrl,
              decoration: InputDecoration(
                hintText: 'Your pen name',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Short Bio (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a short bio...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFC084FC);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? purple.withAlpha(25) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? purple : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: isSelected ? purple : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? purple : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
