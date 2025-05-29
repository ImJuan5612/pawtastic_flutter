import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;
  String? _error;
  Session? _session;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _session != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _loading = true;
      notifyListeners();

      // Recuperar sesión actual
      _session = SupabaseConfig.client.auth.currentSession;
      _user = _session?.user;

      // Escuchar cambios en el estado de autenticación
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        switch (event) {
          case AuthChangeEvent.signedIn:
            _session = session;
            _user = session?.user;
            break;
          case AuthChangeEvent.signedOut:
            _session = null;
            _user = null;
            break;
          case AuthChangeEvent.tokenRefreshed:
            _session = session;
            _user = session?.user;
            break;
          default:
            break;
        }
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Error de autenticación: sesión no válida');
      }

      _session = response.session;
      _user = response.user;

      debugPrint('Usuario autenticado: ${_user?.email}');
      debugPrint('Sesión activa: ${_session?.accessToken != null}');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error de autenticación: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Error de registro: verifica tu email para continuar');
      }

      _session = response.session;
      _user = response.user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      _session = null;
      _user = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshSession() async {
    try {
      _loading = true;
      notifyListeners();

      final response = await SupabaseConfig.client.auth.refreshSession();
      _session = response.session;
      _user = response.user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
