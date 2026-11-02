/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c)  2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wger/core/app_link_router.dart';
import 'package:wger/core/app_settings_notifier.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/error_dialogs.dart';
import 'package:wger/core/errors.dart';
import 'package:wger/core/exceptions/http_exception.dart';
import 'package:wger/core/exceptions/mfa_required_exception.dart';
import 'package:wger/core/network/auth_notifier.dart';
import 'package:wger/core/network/auth_state.dart';
import 'package:wger/core/widgets/atlas.dart';
import 'package:wger/core/widgets/server_config_warning_dialog.dart';
import 'package:wger/features/auth/screens/mfa_challenge_screen.dart';
import 'package:wger/features/auth/widgets/advanced_sheet.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/theme/atlas.dart';

import 'advanced_footer.dart';
import 'auth_mode_switch_link.dart';
import 'confirm_password_field.dart';
import 'email_field.dart';
import 'password_field.dart';
import 'refresh_token_field.dart';
import 'username_field.dart';
import 'web_handoff_link.dart';

enum AuthMode {
  register,
  login,
}

class AuthCard extends ConsumerStatefulWidget {
  const AuthCard();

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends ConsumerState<AuthCard> {
  WgerHttpException? _httpError;
  final GlobalKey<FormState> _formKey = GlobalKey();

  AuthMode _authMode = AuthMode.login;

  bool _showNetworkError = false;
  // Live validation is suppressed until the user taps submit at least once.
  // Otherwise programmatic controller writes (debug prefill, _resetTextfields
  // on mode switch) trip the FormFields' "interacted by user" flag and
  // immediately surface error messages on a form the user hasn't touched.
  bool _autoValidate = false;
  bool _hideCustomServer = true;
  bool _useUsernameAndPassword = true;
  var _isLoading = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _serverUrlController = TextEditingController(
    text: kDebugMode ? DEFAULT_SERVER_TEST : DEFAULT_SERVER_PROD,
  );
  final _refreshTokenController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _emailController.dispose();
    _serverUrlController.dispose();
    _refreshTokenController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AuthNotifier.getServerUrlFromPrefs().then((value) {
      if (mounted) {
        setState(() {
          _serverUrlController.text = value;
          // Reflect the actual server in the option selection: anything other
          // than the official server counts as a self-hosted instance.
          _hideCustomServer = value == DEFAULT_SERVER_PROD;
        });
      }
    });

    _preFillTextFields();
  }

  /// Opens the server's web-handoff page in the system browser. The user
  /// authenticates there (password, social, SSO, …) and the server redirects
  /// back via `wger://app-auth#token=…`, which the app_link_router picks up
  /// and feeds into the existing refresh-token login path.
  Future<void> _launchWebHandoff() async {
    var serverUrl = _serverUrlController.text.trim();
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }
    if (serverUrl.isEmpty) {
      serverUrl = kDebugMode ? DEFAULT_SERVER_TEST : DEFAULT_SERVER_PROD;
    }
    final state = await issueAppAuthState(serverUrl);
    await launchUrl(
      Uri.parse('$serverUrl/user/app-auth/?state=$state'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _preFillTextFields() {
    if (kDebugMode && _authMode == AuthMode.login) {
      setState(() {
        _usernameController.text = TESTSERVER_USER_NAME;
        _passwordController.text = TESTSERVER_PASSWORD;
      });
    }
  }

  void _resetTextFields() {
    _usernameController.clear();
    _passwordController.clear();
    _refreshTokenController.clear();
  }

  Future<void> _submit(BuildContext context) async {
    // From the first submit attempt on, validators run live as the user fixes
    // each field — but not before.
    setState(() {
      _autoValidate = true;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    var serverUrl = _serverUrlController.text;
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      // Login existing user
      late LoginActions res;
      if (_authMode == AuthMode.login) {
        res = await authNotifier.login(
          _usernameController.text,
          _passwordController.text,
          serverUrl,
          _refreshTokenController.text,
        );

        // Register new user
      } else {
        res = await authNotifier.register(
          username: _usernameController.text,
          password: _passwordController.text,
          email: _emailController.text,
          serverUrl: serverUrl,
          locale: Localizations.localeOf(context).languageCode,
        );
      }

      // The "update required" screens are handled reactively by main.dart's
      // _getHomeScreen, which swaps the home screen on the auth status.
      if (context.mounted && res == LoginActions.proceed) {
        final showWarning = ref.read(authProvider).value?.serverConfigWarning ?? false;
        if (showWarning && context.mounted) {
          showServerConfigWarning(context);
          ref.read(authProvider.notifier).clearServerConfigWarning();
        }
      }
    } on MfaRequiredException catch (e) {
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MfaChallengeScreen(
              sessionToken: e.sessionToken,
              serverUrl: serverUrl,
              availableFactors: e.availableFactors,
            ),
          ),
        );
      }
    } on WgerHttpException catch (error) {
      if (context.mounted) {
        setState(() {
          _httpError = error;
          _showNetworkError = false;
        });
      }
    } catch (error) {
      // Login is inherently online, but surface an unreachable server as a
      // friendly message instead of crashing to the red error screen.
      if (isNetworkError(error) && context.mounted) {
        setState(() {
          _showNetworkError = true;
          _httpError = null;
        });
      } else {
        rethrow;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.login) {
      setState(() {
        _authMode = AuthMode.register;
        _useUsernameAndPassword = true;
        _autoValidate = false;
      });
      _resetTextFields();
    } else {
      setState(() {
        _authMode = AuthMode.login;
        _autoValidate = false;
      });
      _preFillTextFields();
    }
  }

  /// Opens the advanced bottom sheet (server + sign-in-method selection).
  ///
  /// [allowSelfSignedCerts] is the persisted setting, passed in from `build` so
  /// the sheet opens on the current value.
  void _showAdvancedSheet(bool allowSelfSignedCerts) {
    showAdvancedSheet(
      context: context,
      initialHideCustomServer: _hideCustomServer,
      initialUsePassword: _useUsernameAndPassword,
      initialAllowSelfSignedCerts: allowSelfSignedCerts,
      loginMode: _authMode == AuthMode.login,
      serverUrlController: _serverUrlController,
      onChanged: (hideCustomServer, usePassword, allowSelfSigned) {
        setState(() {
          _hideCustomServer = hideCustomServer;
          _useUsernameAndPassword = usePassword;
        });
        // Persist immediately so the next login request, still made from this
        // screen, already trusts the certificate.
        ref.read(appSettingsProvider.notifier).setAllowSelfSignedCerts(allowSelfSigned);
      },
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final allowSelfSignedCerts = ref.watch(
      appSettingsProvider.select(
        (s) => s.value?.allowSelfSignedCerts ?? ALLOW_SELF_SIGNED_CERTS_DEFAULT,
      ),
    );

    // Involuntary logout (expired/revoked tokens): tell the user why they
    // are looking at the login form. The transient snackbar shown at the
    // moment of the logout is easy to miss, this hint persists until the
    // next login.
    final sessionExpired = ref.watch(
      authProvider.select((s) => s.value?.sessionExpired ?? false),
    );

    Widget errorMessage = const SizedBox.shrink();
    if (_httpError != null) {
      errorMessage = FormHttpErrorsWidget(_httpError!);
    } else if (_showNetworkError) {
      errorMessage = Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          i18n.errorCouldNotConnectToServer,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Column(
                children: [
                  if (sessionExpired && _authMode == AuthMode.login)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        i18n.sessionExpired,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  errorMessage,
                  if (_useUsernameAndPassword) UsernameField(controller: _usernameController),
                  if (_authMode == AuthMode.register) EmailField(controller: _emailController),
                  if (_useUsernameAndPassword)
                    PasswordField(
                      controller: _passwordController,
                      enforceMinLength: _authMode == AuthMode.register,
                    ),

                  if (_authMode == AuthMode.register)
                    ConfirmPasswordField(
                      controller: _password2Controller,
                      passwordController: _passwordController,
                    ),

                  if (_authMode == AuthMode.login && !_useUsernameAndPassword)
                    RefreshTokenField(controller: _refreshTokenController),

                  if (_authMode == AuthMode.login)
                    WebHandoffLink(
                      onTap: _isLoading ? null : _launchWebHandoff,
                    ),

                  const SizedBox(height: 16),
                  // Bespoke submit:  the shared FormSubmitButton only surfaces
                  // WgerHttpException and has no style override, so it is
                  // intentionally not used here.
                  //
                  // Never gated on the network status: the login attempt is
                  // the better probe and a wrong status would lock the user
                  // out of the app. A failure lands in the error message
                  // above.
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      key: const Key('actionButton'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AtlasRadius.control),
                        ),
                        textStyle: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () {
                        if (!_isLoading) {
                          _submit(context);
                        }
                      },
                      child: _isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              _authMode == AuthMode.register
                                  ? i18n.register
                                  : (_useUsernameAndPassword ? i18n.login : i18n.signInWithToken),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  AuthModeSwitchLink(
                    isLogin: _authMode == AuthMode.login,
                    onTap: _switchAuthMode,
                  ),
                  const SizedBox(height: 20),
                  _ServerChoice(
                    custom: !_hideCustomServer,
                    host: _serverUrlController.text.trim().replaceFirst(RegExp(r'^https?://'), ''),
                    onOfficial: () => setState(() {
                      _hideCustomServer = true;
                      _serverUrlController.text = DEFAULT_SERVER_PROD;
                    }),
                    onCustom: () {
                      setState(() => _hideCustomServer = false);
                      _showAdvancedSheet(allowSelfSignedCerts);
                    },
                  ),
                  const SizedBox(height: 4),
                  AdvancedFooter(
                    isCustomServer: !_hideCustomServer,
                    isTokenMode: _authMode == AuthMode.login && !_useUsernameAndPassword,
                    serverUrl: _serverUrlController.text,
                    onTap: () => _showAdvancedSheet(allowSelfSignedCerts),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i18n.authFooter,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.atlas.ink3,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The two servers one can sign in to as selectable cards: the official one
/// and a self-hosted instance (whose address is entered in the advanced sheet).
class _ServerChoice extends StatelessWidget {
  const _ServerChoice({
    required this.custom,
    required this.host,
    required this.onOfficial,
    required this.onCustom,
  });

  final bool custom;
  final String host;
  final VoidCallback onOfficial;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final atlas = context.atlas;

    Widget card(
      Key key,
      IconData icon,
      String title,
      String subtitle,
      bool selected,
      VoidCallback onTap,
    ) {
      return AtlasCard(
        key: key,
        onTap: onTap,
        borderColor: selected ? theme.colorScheme.primary : null,
        color: selected ? atlas.surface2 : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconBadge(icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  MonoText(
                    subtitle,
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: atlas.ink3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AtlasMotion.of(context),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : atlas.line2,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionEyebrow(i18n.authServerHeading),
        const SizedBox(height: 10),
        card(
          const ValueKey('server-official'),
          Icons.public_outlined,
          i18n.authServerOfficial,
          i18n.authServerOfficialSub,
          !custom,
          onOfficial,
        ),
        const SizedBox(height: 10),
        card(
          const ValueKey('server-custom'),
          Icons.dns_outlined,
          i18n.authServerCustom,
          custom && host.isNotEmpty && host != Uri.parse(DEFAULT_SERVER_PROD).host
              ? host
              : i18n.authServerCustomSub,
          custom,
          onCustom,
        ),
      ],
    );
  }
}
