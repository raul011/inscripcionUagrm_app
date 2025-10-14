import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarritoMaterias {
  static const _key = "materias_carrito";

  // Agregar una materia al carrito
  static Future<void> agregarMateria(Map<String, dynamic> materia) async {
    final prefs = await SharedPreferences.getInstance();
    final materias = prefs.getStringList(_key) ?? [];
    materias.add(jsonEncode(materia));
    await prefs.setStringList(_key, materias);
  }

  // Obtener todas las materias
  static Future<List<Map<String, dynamic>>> obtenerMaterias() async {
    final prefs = await SharedPreferences.getInstance();
    final materias = prefs.getStringList(_key) ?? [];
    return materias.map((m) => jsonDecode(m) as Map<String, dynamic>).toList();
  }

  // Limpiar carrito
  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
