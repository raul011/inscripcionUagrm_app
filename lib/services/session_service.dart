import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  //  Guardar el registro al iniciar sesión
  static Future<void> guardarRegistro(String registro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('registro', registro);
  }

  //  Recuperar el registro cuando lo necesites
  static Future<String?> obtenerRegistro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('registro');
  }

  //
  //   Borrar el registro al cerrar sesión
  static Future<void> borrarRegistro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('registro');
  }
}
