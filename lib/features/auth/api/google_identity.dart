import 'package:google_sign_in/google_sign_in.dart';

import 'package:cheapest_go_mobile/shared/lib/env.dart';

/// Asking Google who this is. See #45.
///
/// A seam, for the same reason the payment gateway is one: Google's sign-in is a platform
/// view and an account picker behind a method channel, and a widget test has neither. The
/// real implementation is small and holds no secret — the app never sees a password, and the
/// ID token it comes back with is useless to anyone but api-v2, which checks who minted it.
abstract class GoogleIdentity {
    /// The ID token for the account the traveller picked, or null if they backed out.
    ///
    /// Backing out of the account picker is not a failure and must not be reported as one.
    Future<String?> idToken();

    /// Forgets the chosen account, so the next sign-in asks again. Called on sign-out;
    /// otherwise someone who signs out stays silently bound to one Google account.
    Future<void> forget();
}

/// Google is not configured in this build.
class GoogleNotConfigured implements Exception {
    const GoogleNotConfigured();
}

class RealGoogleIdentity implements GoogleIdentity {
    RealGoogleIdentity();

    /// The **web** client id, not the Android one.
    ///
    /// Counter-intuitive and the usual cause of a day lost: Android authenticates with its
    /// own client, picked up from the package name and signing certificate, but the ID token
    /// has to be *audienced* to the server that will verify it. That is what `serverClientId`
    /// sets. Without it `idToken` comes back null and nothing says why.
    static final _serverClientId = env.googleServerClientId;

    GoogleSignIn? _client;

    GoogleSignIn get _google {
        if (_serverClientId.isEmpty) throw const GoogleNotConfigured();
        return _client ??= GoogleSignIn(
            serverClientId: _serverClientId,
            scopes: const ['email', 'profile'],
        );
    }

    @override
    Future<String?> idToken() async {
        final account = await _google.signIn();
        // Null when the picker was dismissed. Their decision, not an error.
        if (account == null) return null;
        final auth = await account.authentication;
        return auth.idToken;
    }

    @override
    Future<void> forget() async {
        if (_serverClientId.isEmpty) return;
        try {
            await _google.signOut();
        } catch (_) {
            // Signing out of this app must not fail because Google would not let go.
        }
    }
}

/// The app's client. Replaced in tests.
GoogleIdentity googleIdentity = RealGoogleIdentity();
