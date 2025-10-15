import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:inscripcion_app/screens/login_screen2.dart';
import 'package:inscripcion_app/screens/grupo_materias_screen.dart';
import 'package:inscripcion_app/screens/materias_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return const MaterialApp(home: InscripcionScreen());
    //return const MaterialApp(home: LoginScreen2());
    //return const MaterialApp(home: CourseGroupsScreen());
    return const MaterialApp(home: MateriasScreen());
  }
}

class InscripcionScreen extends StatefulWidget {
  const InscripcionScreen({super.key});

  @override
  State<InscripcionScreen> createState() => _InscripcionScreenState();
}

class _InscripcionScreenState extends State<InscripcionScreen> {
  bool isLoading = false;
  String status = 'Sin iniciar';

  Future<void> _enviar() async {
    final requestId = const Uuid().v4();
    debugPrint("Request ID generado: $requestId");

    setState(() {
      isLoading = true;
      status = '📩 Pendiente...';
    });

    try {
      final url = Uri.parse(
        "http://192.168.0.184:5000/api/inscripciones-sync/async/completa",
        //"http://172.20.10.6:5000/api/inscripciones-sync/async/completa",
      );

      final body = {
        "estudianteRegistro": "20251234",
        "periodoGestion": "2025-1",
        "materiaGrupoCodigos": ["MAT101-A", "INF119-B"],
        "callbackUrl": "http://192.168.0.184:5000/webhook/sink",
        //"callbackUrl": "http://172.20.10.6:5000/webhook/sink",
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        final estado = data["estado"];
        final transaccionId = data["transaccionId"];

        setState(() {
          isLoading = false;
          status = "✅ Estado: $estado\nTransacción: $transaccionId";
        });
      } else {
        setState(() {
          isLoading = false;
          status = "❌ Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        status = "❌ Error en la conexión: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscripción")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Texto de estado siempre visible
            Text(
              "Estado: $status",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Botón de inscripción
            ElevatedButton(
              onPressed: isLoading ? null : _enviar,
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text("Inscribirse"),
            ),
          ],
        ),
      ),
    );
  }
}
