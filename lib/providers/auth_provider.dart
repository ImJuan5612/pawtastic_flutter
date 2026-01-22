import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/config/supabase_config.dart';
import 'package:pawtastic/models/profile.dart'; // Importar el modelo Profile

class AuthProvider extends ChangeNotifier {
  User? _user;
  Profile? _profile; // Añadir para almacenar el perfil del usuario
  bool _loading = true; // Usaremos este loading para el estado general
  String? _error;
  Session? _session;

  User? get user => _user;
  Profile? get profile => _profile; // Getter para el perfil
  bool get isLoading => _loading; // Renombrar getter para consistencia si prefieres, o mantener 'loading'
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
            if (_user != null) {
              fetchUserProfile(_user!.id); // Cargar perfil al iniciar sesión
            }
            break;
          case AuthChangeEvent.signedOut:
            _session = null;
            _user = null;
            break;
          case AuthChangeEvent.tokenRefreshed:
            _session = session;
            _user = session?.user;
            // Podrías considerar recargar el perfil aquí también si es necesario
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
      if (_user != null) {
        await fetchUserProfile(_user!.id); // Cargar perfil después de iniciar sesión
      }
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
      if (_user != null) {
        await fetchUserProfile(_user!.id); // Cargar perfil después de registrarse
      }
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
      _profile = null; // Limpiar perfil al cerrar sesión
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
      if (_user != null && _profile == null) { // Si el perfil no se había cargado
        await fetchUserProfile(_user!.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    _user = Supabase.instance.client.auth.currentUser;
    notifyListeners();
  }

  // Método para cargar el perfil del usuario
  Future<void> fetchUserProfile([String? userId]) async {
    // if (_loading) return; // Podrías quitar esto si _loading se maneja bien en otros lados
    _loading = true; // Indicar que estamos cargando algo
    notifyListeners();

    try {
      final idToFetch = userId ?? _user?.id;
      if (idToFetch == null) {
        throw Exception("ID de usuario no disponible para cargar el perfil.");
      }
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', idToFetch)
          .single(); 

      _profile = Profile.fromJson(response);
      _error = null;
    } catch (e) {
      _error = "Error al cargar el perfil: ${e.toString()}";
      _profile = null; 
      debugPrint(_error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Método para deducir del saldo (lo necesitarás para la funcionalidad de billetera)
  Future<bool> deductFromWallet(double amountToDeduct) async {
    if (_profile == null || _user == null) {
      _error = "Perfil no cargado para la operación de billetera.";
      notifyListeners();
      return false;
    }
    // Asumiendo que Profile tiene walletBalance, si no, necesitas añadirlo al modelo Profile
    // if (_profile!.walletBalance < amountToDeduct) { 
    //   _error = "Saldo insuficiente.";
    //   notifyListeners();
    //   return false;
    // }

    _loading = true;
    notifyListeners();

    try {
      // final newBalance = _profile!.walletBalance - amountToDeduct;
      // await Supabase.instance.client
      //     .from('profiles')
      //     .update({'wallet_balance': newBalance})
      //     .eq('id', _user!.id);
      // _profile = _profile!.copyWith(walletBalance: newBalance); // Asumiendo copyWith en Profile
      _error = null;
      notifyListeners();
      return true; // Simulación por ahora, necesitas la lógica real de 'wallet_balance'
    } catch (e) {
      _error = "Error al actualizar el saldo: ${e.toString()}";
      debugPrint(_error);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
