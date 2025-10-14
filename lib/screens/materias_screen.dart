import 'package:flutter/material.dart';
import '../models/materia.dart';
import '../services/api_service.dart';
import 'grupo_materias_screen.dart';
import '../services/session_service.dart';
import 'login_screen2.dart';
import 'perfil_estudiante_screen.dart';
import 'materias-agregadas_screen.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  late Future<List<Materia>> materiasFuture;

  @override
  void initState() {
    super.initState();
    materiasFuture = ApiService.fetchMaterias(page: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text(
          "Materias Disponibles",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2A2A3E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00D9D9)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onSelected: (value) async {
              if (value == 'perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerfilEstudianteScreen(),
                  ),
                );
              } else if (value == 'logout') {
                // Borrar la sesión
                await SessionService.borrarRegistro();

                // Navegar a la pantalla de login y eliminar el historial de rutas
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen2(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              } else if (value == 'materias') {
                // Borrar la sesión

                // Navegar a la pantalla de login y eliminar el historial de rutas
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MateriasAgregadasScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'perfil',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Ver Perfil'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Cerrar Sesión'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'materias',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('materias agregadas'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: FutureBuilder<List<Materia>>(
        future: materiasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9D9)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(0xFFFF6B6B),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(
                      color: Color(0xFF8B8B9E),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 60,
                    color: Color(0xFF8B8B9E),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No hay materias",
                    style: TextStyle(color: Color(0xFF8B8B9E), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final materias = snapshot.data!;
          // final codMateria = "MAT101";

          // Lista de colores alternos para las tarjetas
          final cardColors = [
            const Color(0xFF2D3250), // Azul grisáceo
            const Color(0xFF1F3A3A), // Verde azulado oscuro
            const Color(0xFF3A2D3E), // Púrpura oscuro
            const Color(0xFF2D3A2F), // Verde oscuro
            const Color(0xFF2A2A3E), // Azul oscuro original
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materias.length,
            itemBuilder: (context, index) {
              final materia = materias[index];
              final cardColor = cardColors[index % cardColors.length];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              CourseGroupsScreen(codMat: materia.codigo),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3A3A4E),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la materia
                        Text(
                          materia.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Información adicional
                        Row(
                          children: [
                            // Nivel
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.school_outlined,
                                      size: 16,
                                      color: Color(0xFF00D9D9),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        materia.nivelNombre,
                                        style: const TextStyle(
                                          color: Color(0xFF8B8B9E),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Créditos
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_outline,
                                    size: 16,
                                    color: Color(0xFF00D9D9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${materia.creditos}",
                                    style: const TextStyle(
                                      color: Color(0xFF8B8B9E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
