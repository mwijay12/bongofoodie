import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/env_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/auth_validation.dart';
import '../../data/models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/settings_provider.dart';

/// Shared form presentation; the existing repository remains the auth boundary.
class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key, required this.signUp});
  final bool signUp;
  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _guestPending = false;
  bool _resetPending = false;

  String tr(String en, String sw) =>
      ref.read(appStringsProvider).isSw ? sw : en;

  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guest() async {
    if (_guestPending || ref.read(authProvider).isLoading) return;
    setState(() => _guestPending = true);
    try {
      await ref.read(appSettingsProvider.notifier).completeOnboarding();
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _guestPending = false);
    }
  }

  Future<void> _submit() async {
    if (ref.read(authProvider).isLoading || !_form.currentState!.validate())
      return;
    FocusScope.of(context).unfocus();
    final controller = ref.read(authProvider.notifier);
    final success = widget.signUp
        ? await controller.signUpWithEmail(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            password: _password.text)
        : await controller.signInWithEmail(
            email: _email.text.trim(), password: _password.text);
    if (!mounted || !success) return;
    TextInput.finishAutofillContext();
    context.go('/home');
  }

  Future<void> _reset() async {
    if (_resetPending || ref.read(authProvider).isLoading) return;
    if (!isValidAuthEmail(_email.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('Enter your account email above first.',
              'Andika barua pepe ya akaunti yako kwanza.'))));
      return;
    }
    setState(() => _resetPending = true);
    try {
      final error = await ref
          .read(authProvider.notifier)
          .resetPassword(_email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error == null
              ? tr('If this account exists, check your inbox for a reset link.',
                  'Ikiwa akaunti hii ipo, angalia kiungo cha kubadili nenosiri kwenye barua pepe.')
              : tr('Could not send a reset link. Please retry.',
                  'Kiungo hakijatumwa. Jaribu tena.'))));
    } finally {
      if (mounted) setState(() => _resetPending = false);
    }
  }

  Future<void> _demo(UserRole role) async {
    final ok = await ref.read(authProvider.notifier).signInDemo(role);
    if (mounted && ok)
      context.go(role == UserRole.customer ? '/home' : '/staff');
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final auth = ref.watch(authProvider);
    final busy = auth.isLoading || _guestPending || _resetPending;
    final title = widget.signUp
        ? tr('Create account', 'Fungua akaunti')
        : tr('Welcome back', 'Karibu tena');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: ValueKey(widget.signUp ? 'sign-up-system-ui' : 'sign-in-system-ui'),
      value:
          SystemUiOverlayStyle.light.copyWith(statusBarColor: AppColors.ember),
      child: Scaffold(
        body: SafeArea(
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.screenH),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    decoration: BoxDecoration(
                        color: AppColors.ember,
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.restaurant_menu_rounded,
                                color: AppColors.heroLight),
                            const SizedBox(width: AppSpace.md),
                            const Expanded(
                                child: Text('BongoFoodie',
                                    style: TextStyle(
                                        color: AppColors.surface,
                                        fontWeight: FontWeight.w800))),
                            IconButton(
                                tooltip: tr('Switch language', 'Badili lugha'),
                                constraints: const BoxConstraints(
                                    minWidth: AppSpace.huge,
                                    minHeight: AppSpace.huge),
                                onPressed: () => ref
                                    .read(appSettingsProvider.notifier)
                                    .toggleLanguage(),
                                icon: const Icon(Icons.translate_rounded,
                                    color: AppColors.heroLight)),
                          ]),
                          const SizedBox(height: AppSpace.lg),
                          Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.w800)),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                              tr('Your next Swahili favourite awaits.',
                                  'Chakula chako ukipendacho kinakusubiri.'),
                              style: const TextStyle(
                                  color: AppColors.darkTextSecondary)),
                        ]),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  OutlinedButton(
                      key: const ValueKey('continue-guest'),
                      onPressed: busy ? null : _guest,
                      child: Text(
                          tr('Continue as guest', 'Endelea bila akaunti'),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: AppSpace.sm),
                  Text(tr(
                      'Browse and build your cart without signing in. An account helps keep your history across devices.',
                      'Tazama menyu na ongeza vyakula kikapuni bila kuingia. Akaunti hukusaidia kupata historia yako kwenye vifaa tofauti.')),
                  const SizedBox(height: AppSpace.xl),
                  if (!EnvConfig.hasSupabaseCredentials) ...[
                    Text(tr(
                        'Demo mode: registration creates a local test profile, not a live account.',
                        'Hali ya majaribio: usajili huunda wasifu wa kifaa hiki, si akaunti halisi.')),
                    const SizedBox(height: AppSpace.md),
                  ],
                  if (widget.signUp) ...[
                    TextFormField(
                        key: const ValueKey('auth-name'),
                        controller: _name,
                        enabled: !busy,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) => (value ?? '').trim().length < 2
                            ? tr('Enter your name.', 'Andika jina lako.')
                            : null,
                        decoration: InputDecoration(
                            labelText: tr('Full name', 'Jina kamili'))),
                    const SizedBox(height: AppSpace.md),
                    TextFormField(
                        key: const ValueKey('auth-phone'),
                        controller: _phone,
                        enabled: !busy,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (value) => !isValidTzPhone(value ?? '')
                            ? tr('Use a TZ mobile number, e.g. 0712 345 678.',
                                'Weka namba ya simu ya TZ, mfano 0712 345 678.')
                            : null,
                        decoration: InputDecoration(
                            labelText:
                                tr('Phone number (TZ)', 'Namba ya simu (TZ)'))),
                    const SizedBox(height: AppSpace.md),
                  ],
                  TextFormField(
                      key: const ValueKey('auth-email'),
                      controller: _email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      validator: (value) => !isValidAuthEmail(value ?? '')
                          ? tr('Enter a valid email address.',
                              'Weka barua pepe sahihi.')
                          : null,
                      decoration: InputDecoration(
                          labelText: tr('Email address', 'Barua pepe'))),
                  const SizedBox(height: AppSpace.md),
                  TextFormField(
                      key: const ValueKey('auth-password'),
                      controller: _password,
                      enabled: !busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        widget.signUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) =>
                          (value ?? '').length < (widget.signUp ? 6 : 1)
                              ? tr(
                                  widget.signUp
                                      ? 'Use at least 6 characters.'
                                      : 'Enter your password.',
                                  widget.signUp
                                      ? 'Tumia angalau herufi 6.'
                                      : 'Andika nenosiri lako.')
                              : null,
                      decoration: InputDecoration(
                          labelText: tr('Password', 'Nenosiri'),
                          suffixIcon: IconButton(
                              constraints: const BoxConstraints(
                                  minWidth: AppSpace.huge,
                                  minHeight: AppSpace.huge),
                              tooltip: _obscure
                                  ? tr('Show password', 'Onyesha nenosiri')
                                  : tr('Hide password', 'Ficha nenosiri'),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined)))),
                  if (!widget.signUp)
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: busy ? null : _reset,
                            child: Text(
                                tr('Forgot password?', 'Umesahau nenosiri?')))),
                  if (auth.confirmationEmail != null) ...[
                    const SizedBox(height: AppSpace.md),
                    Semantics(
                        liveRegion: true,
                        child: Text(tr(
                            'Check ${auth.confirmationEmail} to confirm your email, then sign in. You can keep browsing as a guest.',
                            'Thibitisha barua pepe kupitia ${auth.confirmationEmail}, kisha ingia. Unaweza kuendelea bila akaunti.'))),
                  ],
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: AppSpace.md),
                    Semantics(
                        liveRegion: true,
                        child: Text(tr(
                            'Could not complete authentication. Check your details and connection, then retry.',
                            'Haijawezekana kuingia au kusajili. Hakiki taarifa na intaneti, kisha jaribu tena.'))),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  ElevatedButton(
                      key: const ValueKey('auth-submit'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeep,
                          foregroundColor: AppColors.surface,
                          minimumSize: const Size(AppSpace.huge, AppSpace.v56)),
                      onPressed: busy ? null : _submit,
                      child: Text(busy
                          ? tr('Please wait…', 'Tafadhali subiri…')
                          : widget.signUp
                              ? tr('Create account', 'Fungua akaunti')
                              : tr('Sign in', 'Ingia'))),
                  if (!widget.signUp && EnvConfig.hasSupabaseCredentials) ...[
                    const SizedBox(height: AppSpace.md),
                    OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => ref
                                .read(authProvider.notifier)
                                .signInWithGoogle(),
                        child: Text(
                            tr('Continue with Google', 'Endelea na Google'))),
                  ],
                  const SizedBox(height: AppSpace.md),
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => widget.signUp
                              ? context.go('/sign-in')
                              : context.push('/sign-up'),
                      child: Text(widget.signUp
                          ? tr('Already registered? Sign in',
                              'Una akaunti? Ingia')
                          : tr('New here? Create an account',
                              'Huna akaunti? Fungua akaunti'))),
                  if (!widget.signUp && !EnvConfig.hasSupabaseCredentials)
                    ExpansionTile(
                        title: Text(tr(
                            'Demo role previews', 'Jaribu majukumu ya demo')),
                        subtitle: Text(tr(
                            'Local test data only — not live staff access.',
                            'Taarifa za majaribio tu — si ruhusa halisi za wahudumu.')),
                        children: [
                          for (final role in [
                            UserRole.customer,
                            UserRole.waiter,
                            UserRole.admin
                          ])
                            TextButton(
                                onPressed: busy ? null : () => _demo(role),
                                child: Text(role == UserRole.customer
                                    ? t.demoCustomer
                                    : role == UserRole.admin
                                        ? t.demoAdmin
                                        : t.demoWaiter))
                        ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
