import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/grupo_materia.dart';

class CourseGroupsScreen extends StatefulWidget {
  const CourseGroupsScreen({Key? key}) : super(key: key);

  @override
  State<CourseGroupsScreen> createState() => _CourseGroupsScreenState();
}

class _CourseGroupsScreenState extends State<CourseGroupsScreen> {
  late Future<List<GrupoMateria>> futureGrupos;
  final apiService = ApiService();

  @override
  void initState() {
    super.initState();
    futureGrupos = apiService.fetchGruposPorMateria("MAT101");
  }

  int? loadingIndex;
  String status = 'Sin iniciar';

  List<CourseGroup> groups = [
    CourseGroup(
      groupNumber: '101',
      schedule: 'Lunes y Miércoles 8:00-10:00',
      professor: 'Dr. García',
      totalQuota: 30,
      enrolledStudents: 20,
      status: GroupStatus.available,
    ),
    CourseGroup(
      groupNumber: '102',
      schedule: 'Martes y Jueves 14:00-16:00',
      professor: 'Dra. López',
      totalQuota: 25,
      enrolledStudents: 25,
      status: GroupStatus.full,
    ),
    CourseGroup(
      groupNumber: '103',
      schedule: 'Viernes 9:00-13:00',
      professor: 'Prof. Martínez',
      totalQuota: 35,
      enrolledStudents: 15,
      status: GroupStatus.available,
    ),
  ];

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
      ),
      body: Column(
        children: [
          // Estado siempre visible
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
              child: Text(
                "Estado: $status",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Lista de grupos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final hasSuccessfulEnrollment = groups.any(
                  (g) => g.status == GroupStatus.success,
                );

                if (hasSuccessfulEnrollment) {
                  if (groups[index].status != GroupStatus.success) {
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
                    group: groups[index],
                    isLoading: loadingIndex == index,
                    onEnroll: () => _handleEnroll(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEnroll(int index) async {
    final requestId = const Uuid().v4();
    debugPrint("Request ID generado: $requestId");

    setState(() {
      loadingIndex = index;
      groups[index].status = GroupStatus.pending;
    });

    try {
      final url = Uri.parse(
        "http://192.168.0.184:5000/api/inscripciones-sync/async/completa",
      );

      final body = {
        "estudianteRegistro": "20251234",
        "periodoGestion": "2025-1",
        "materiaGrupoCodigos": ["MAT101-A", "INF119-B"],
        "callbackUrl": "http://192.168.0.184:5000/webhook/sink",
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
          groups[index].enrolledStudents++;
          if (groups[index].enrolledStudents >= groups[index].totalQuota) {
            groups[index].status = GroupStatus.full;
          } else {
            groups[index].status = GroupStatus.success;
          }
          loadingIndex = null;
          status = "✅ Estado: $estado\nTransacción: $transaccionId";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inscrito en Grupo ${groups[index].groupNumber}\n'
              'Estado: $estado\n'
              'Transacción: $transaccionId',
            ),
            backgroundColor: const Color(0xFF00D9D9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          loadingIndex = null;
          groups[index].status = GroupStatus.error;
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
        groups[index].status = GroupStatus.error;
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
}

enum GroupStatus { available, full, pending, success, error }

class CourseGroup {
  final String groupNumber;
  final String schedule;
  final String professor;
  final int totalQuota;
  int enrolledStudents;
  GroupStatus status;

  CourseGroup({
    required this.groupNumber,
    required this.schedule,
    required this.professor,
    required this.totalQuota,
    required this.enrolledStudents,
    required this.status,
  });

  int get availableSpots => totalQuota - enrolledStudents;
  String get quota => '$enrolledStudents/$totalQuota';
}

class CourseGroupCard extends StatelessWidget {
  final CourseGroup group;
  final bool isLoading;
  final VoidCallback onEnroll;

  const CourseGroupCard({
    Key? key,
    required this.group,
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
                  'Grupo ${group.groupNumber}',
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
            _buildInfoRow(Icons.schedule, 'Horario: ${group.schedule}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Profesor: ${group.professor}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.people, 'Cupos: ${group.quota}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (group.status == GroupStatus.available && !isLoading)
                        ? onEnroll
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      group.status == GroupStatus.available
                          ? const Color.fromARGB(255, 0, 71, 255)
                          : const Color(0xFF3A3A4E),
                  foregroundColor:
                      group.status == GroupStatus.available
                          ? const Color(0xFF1E1E2E)
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
                            color: Color(0xFF1E1E2E),
                          ),
                        )
                        : Text(
                          group.status == GroupStatus.available
                              ? 'Inscribir (${group.availableSpots} cupos)'
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

    switch (group.status) {
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
        text = '❌ Error';
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
