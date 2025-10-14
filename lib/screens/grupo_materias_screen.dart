import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../models/grupo_materia.dart';

class CourseGroupsScreen extends StatefulWidget {
  final String codMat;

  CourseGroupsScreen({super.key, required this.codMat});

  @override
  State<CourseGroupsScreen> createState() => _CourseGroupsScreenState();
}

class _CourseGroupsScreenState extends State<CourseGroupsScreen> {
  late Future<List<GrupoMateria>> futureGrupos;
  final apiService = ApiService();

  @override
  void initState() {
    super.initState();
    futureGrupos = apiService.fetchGruposPorMateria(widget.codMat);
  }

  int? loadingIndex;
  String status = 'Sin iniciar';
  List<GrupoMateriaConStatus> grupos = [];

  // Variables para guardar información de inscripción
  int? inscripcionId;
  String? transactionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text(
          'Grupos de Materias',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2A2A3E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00D9D9)),
        actions: [
          // Botón para consultar estado
          if (inscripcionId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _consultarEstado,
              tooltip: 'Consultar estado',
            ),
        ],
      ),
      body: FutureBuilder<List<GrupoMateria>>(
        future: futureGrupos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9D9)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay grupos disponibles',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (grupos.isEmpty) {
            grupos =
                snapshot.data!
                    .map((g) => GrupoMateriaConStatus(grupoMateria: g))
                    .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A4E)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Estado: $status",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (inscripcionId != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ID Inscripción: $inscripcionId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B8B9E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grupos.length,
                  itemBuilder: (context, index) {
                    final hasSuccessfulEnrollment = grupos.any(
                      (g) => g.status == GroupStatus.success,
                    );

                    if (hasSuccessfulEnrollment) {
                      if (grupos[index].status != GroupStatus.success) {
                        return const SizedBox.shrink();
                      }
                    } else {
                      if (loadingIndex != null && loadingIndex != index) {
                        return const SizedBox.shrink();
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CourseGroupCard(
                        grupo: grupos[index],
                        isLoading: loadingIndex == index,
                        onEnroll: () => _handleEnroll(index),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEnroll(int index) async {
    final grupoSeleccionado = grupos[index];
    final requestId = const Uuid().v4();
    debugPrint("Request ID generado: $requestId");

    setState(() {
      loadingIndex = index;
      grupoSeleccionado.status = GroupStatus.pending;
    });

    try {
      final registroLogeado = await SessionService.obtenerRegistro();
      debugPrint(
        "✅-----------------------***** REGISTRO ******-------------------------" +
            (registroLogeado ?? "No registro"),
      );

      final url = Uri.parse(
        "http://192.168.0.184:5000/api/inscripciones/async",
      );

      final body = {
        "registro": registroLogeado,
        "periodoId": 1,
        "materias": [
          //{"materiaCodigo": "LIN100", "grupo": "Z1"},
          {"materiaCodigo": widget.codMat, "grupo": grupoSeleccionado.grupo},
        ],
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        final estado = data["estado"];
        final transaccionId = data["transactionId"];

        // Guardar el ID de inscripción y transactionId
        final inscripcionData = data["inscripcion"];
        inscripcionId = inscripcionData["id"];
        transactionId = transaccionId;

        debugPrint("Inscripción ID guardado: $inscripcionId");
        debugPrint("Transaction ID guardado: $transactionId");

        setState(() {
          // Mantener en pending para que el polling actualice el estado
          grupoSeleccionado.status = GroupStatus.pending;
          loadingIndex = null;
          status =
              "⏳ Estado: $estado\nTransacción: $transaccionId\nID: $inscripcionId";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inscrito en Grupo ${grupoSeleccionado.grupo}\n'
              'Estado: $estado\n'
              'Transacción: $transaccionId\n'
              'ID Inscripción: $inscripcionId',
            ),
            backgroundColor: const Color(0xFF00D9D9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        // Iniciar polling automático del estado
        _iniciarPolling();
      } else {
        setState(() {
          loadingIndex = null;
          grupoSeleccionado.status = GroupStatus.error;
          status = "❌ Error: ${response.statusCode}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inscribir: ${response.statusCode}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        loadingIndex = null;
        grupoSeleccionado.status = GroupStatus.error;
        status = "❌ Error en la conexión: $e";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la conexión: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Método para consultar el estado de la inscripción
  Future<void> _consultarEstado() async {
    if (inscripcionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay inscripción para consultar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // URL con el formato correcto: /registro/inscripcionId
      final url = Uri.parse(
        //"http://192.168.0.184:5000/api/inscripciones/estado-inscripcion/20251234/$inscripcionId",
        "http://172.20.10.6:5000/api/inscripciones/estado-inscripcion/20251234/$inscripcionId",
      );

      debugPrint("🔍 Consultando estado para inscripción $inscripcionId");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final estado = data["estado"];
        final materias = data["materias"] as List;

        debugPrint("📡 Estado recibido: $estado");

        // Obtener información adicional de las materias
        String materiasInfo = materias
            .map((m) => '${m["codigo"]} (${m["grupo"]}): ${m["estado"]}')
            .join('\n');

        // Determinar el nuevo estado del grupo
        GroupStatus nuevoEstado = GroupStatus.pending;

        if (estado == "CONFIRMADA" ||
            estado == "COMPLETADO" ||
            estado == "ACEPTADA" ||
            estado == "EXITOSO") {
          nuevoEstado = GroupStatus.success;
          debugPrint("✅ Cambiando a estado SUCCESS");
        } else if (estado == "RECHAZADA" ||
            estado == "ERROR" ||
            estado == "FALLIDO") {
          nuevoEstado = GroupStatus.error;
          debugPrint("❌ Cambiando a estado ERROR");
        } else if (estado == "PENDIENTE") {
          nuevoEstado = GroupStatus.pending;
          debugPrint("⏳ Mantiene estado PENDING");
        }

        setState(() {
          status = "📡 Estado: $estado\n$materiasInfo";

          // Actualizar el estado del grupo que estaba pendiente
          final index = grupos.indexWhere(
            (g) => g.status == GroupStatus.pending,
          );
          if (index != -1) {
            grupos[index].status = nuevoEstado;
            debugPrint("🔄 Grupo en index $index actualizado a $nuevoEstado");
          }
        });

        // Mostrar notificación con el estado
        Color snackbarColor;
        String emoji;

        if (estado == "CONFIRMADA" ||
            estado == "COMPLETADO" ||
            estado == "ACEPTADA" ||
            estado == "EXITOSO") {
          snackbarColor = Colors.green;
          emoji = '✅';
        } else if (estado == "RECHAZADA" ||
            estado == "ERROR" ||
            estado == "FALLIDO") {
          snackbarColor = Colors.red;
          emoji = '❌';
        } else if (estado == "PENDIENTE") {
          snackbarColor = Colors.orange;
          emoji = '⏳';
        } else {
          snackbarColor = const Color(0xFF00D9D9);
          emoji = '📡';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$emoji Estado: $estado\n$materiasInfo'),
            backgroundColor: snackbarColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception('Error al consultar estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error al consultar estado: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al consultar estado: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Polling automático cada 3 segundos
  void _iniciarPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && inscripcionId != null) {
        // Verificar si hay grupos pendientes antes de continuar
        final tienePendiente = grupos.any(
          (g) => g.status == GroupStatus.pending,
        );
        if (tienePendiente) {
          _consultarEstado().then((_) {
            // Después de consultar, verificar nuevamente si debe continuar
            final sigueHabiendoPendiente = grupos.any(
              (g) => g.status == GroupStatus.pending,
            );
            if (sigueHabiendoPendiente) {
              _iniciarPolling();
            } else {
              debugPrint("Polling detenido: estado final alcanzado");
            }
          });
        } else {
          debugPrint("Polling detenido: no hay inscripciones pendientes");
        }
      }
    });
  }
}

enum GroupStatus { available, full, pending, success, error }

class GrupoMateriaConStatus {
  final GrupoMateria grupoMateria;
  GroupStatus status;

  GrupoMateriaConStatus({
    required this.grupoMateria,
    this.status = GroupStatus.available,
  });

  int get id => grupoMateria.id;
  String get grupo => grupoMateria.grupo;
  int get cupo => grupoMateria.cupo;
  String get estado => grupoMateria.estado;
  String get docenteNombre => grupoMateria.docenteNombre;
  String? get docenteRegistro => grupoMateria.docenteRegistro;
  String? get horarioDia => grupoMateria.horarioDia;
  String? get horaInicio => grupoMateria.horaInicio;
  String? get horaFin => grupoMateria.horaFin;

  String get horarioCompleto {
    if (horarioDia != null && horaInicio != null && horaFin != null) {
      return '$horarioDia $horaInicio-$horaFin';
    }
    return 'Horario no disponible';
  }
}

class CourseGroupCard extends StatelessWidget {
  final GrupoMateriaConStatus grupo;
  final bool isLoading;
  final VoidCallback onEnroll;

  const CourseGroupCard({
    Key? key,
    required this.grupo,
    required this.isLoading,
    required this.onEnroll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A4E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grupo ${grupo.grupo}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.schedule, 'Horario: ${grupo.horarioCompleto}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Docente: ${grupo.docenteNombre}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.people, 'Cupos: ${grupo.cupo}'),
            if (grupo.status == GroupStatus.available ||
                grupo.status == GroupStatus.full) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (grupo.status == GroupStatus.available && !isLoading)
                          ? onEnroll
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        grupo.status == GroupStatus.available
                            ? const Color.fromARGB(255, 0, 71, 255)
                            : const Color(0xFF3A3A4E),
                    foregroundColor:
                        grupo.status == GroupStatus.available
                            ? Colors.white
                            : const Color(0xFF8B8B9E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
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
                          : Text(
                            grupo.status == GroupStatus.available
                                ? 'Inscribir (${grupo.cupo} cupos)'
                                : 'Cupos llenos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                ),
              ),
            ] else
              const SizedBox(
                height: 8,
              ), // Espacio para mantener la altura de la tarjeta
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00D9D9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8B8B9E)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (grupo.status) {
      case GroupStatus.available:
        backgroundColor = const Color(0xFF1F3A2F);
        textColor = const Color(0xFF4ADE80);
        text = 'Disponible';
        break;
      case GroupStatus.full:
        backgroundColor = const Color(0xFF3A1F1F);
        textColor = const Color(0xFFFF6B6B);
        text = 'Cupos Llenos';
        break;
      case GroupStatus.pending:
        backgroundColor = const Color(0xFF3A2F1F);
        textColor = const Color(0xFFFFA500);
        text = '📩 Pendiente...';
        break;
      case GroupStatus.success:
        backgroundColor = const Color(0xFF1F2F3A);
        textColor = const Color.fromARGB(255, 5, 233, 93);
        text = '✅ Confirmado';
        break;
      case GroupStatus.error:
        backgroundColor = const Color(0xFF3A1F1F);
        textColor = const Color(0xFFFF6B6B);
        text = '❌ Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
