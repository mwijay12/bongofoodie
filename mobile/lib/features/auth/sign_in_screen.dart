import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginDemo(UserRole role) async {
    final ok = await ref.read(authProvider.notifier).signInDemo(role);
    if (!mounted || !ok) return;
    if (role == UserRole.waiter || role == UserRole.admin) {
      context.go('/staff');
    } else {
      context.go('/home');
    }
  }

  Future<void> _submitEmailLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
    if (ok && mounted) {
      context.go('/home');
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetCtrl = TextEditingController(text: _emailCtrl.text);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: resetCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Account Email',
            hintText: 'you@bongofoodie.co.tz',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final err = await ref
                  .read(authProvider.notifier)
                  .resetPassword(resetCtrl.text);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    err ?? 'Password reset link sent! Check your inbox.',
                  ),
                ),
              );
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final t = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.signInTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Kijitonyama, Dar es Salaam • Tanzania',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Switch Language',
                    onPressed: () =>
                        ref.read(appSettingsProvider.notifier).toggleLanguage(),
                    icon: const Icon(Icons.translate_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1-Tap Portfolio Showcase Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2B1C10), const Color(0xFF1F1610)]
                        : [const Color(0xFFFFF5E6), const Color(0xFFFFEBD0)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            EnvConfig.hasSupabaseCredentials
                                ? 'LIVE SUPABASE + QUICK ROLE PREVIEW'
                                : '1-TAP SHOWCASE MODE (NO KEYS NEEDED)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.showcaseHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 14),
                    _DemoRoleTile(
                      icon: Icons.person_rounded,
                      title: t.demoCustomer,
                      subtitle: 'Browse menu, Chef AI, Cart & Lipa Namba checkout',
                      badgeColor: AppColors.success,
                      onTap: auth.isLoading
                          ? null
                          : () => _loginDemo(UserRole.customer),
                    ),
                    const SizedBox(height: 8),
                    _DemoRoleTile(
                      icon: Icons.delivery_dining_rounded,
                      title: t.demoWaiter,
                      subtitle: 'Live Kitchen & Waiter Order Dispatch Console',
                      badgeColor: AppColors.info,
                      onTap: auth.isLoading
                          ? null
                          : () => _loginDemo(UserRole.waiter),
                    ),
                    const SizedBox(height: 8),
                    _DemoRoleTile(
                      icon: Icons.verified_user_rounded,
                      title: t.demoAdmin,
                      subtitle: 'Full Dispatch + Daily Discoveries & Branch Admin',
                      badgeColor: AppColors.primary,
                      onTap: auth.isLoading
                          ? null
                          : () => _loginDemo(UserRole.admin),
                    ),
                  ],
                ),
              ),

              if (auth.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      t.isSw ? 'AU INGIA KWA BARUA PEPE' : 'OR SIGN IN WITH EMAIL',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'amina@bongofoodie.co.tz',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    t.isSw ? 'Umesahau Nenosiri?' : 'Forgot Password?',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submitEmailLogin,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(t.isSw ? 'Ingia Sasa' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signInWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                  label: Text(
                    t.isSw ? 'Endelea na Google' : 'Continue with Google',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/sign-up'),
                  child: Text(
                    t.isSw
                        ? 'Huna akaunti? Fungua Akaunti Mpya'
                        : "Don't have an account? Create Account",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoRoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _DemoRoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
