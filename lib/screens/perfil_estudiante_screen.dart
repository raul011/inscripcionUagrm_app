import 'package:flutter/material.dart';
import 'package:inscripcion_app/models/estudiante_model.dart';

class PerfilEstudianteScreen extends StatelessWidget {
  const PerfilEstudianteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2A2A3E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00D9D9)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF2A2A3E),
              child: Icon(
                Icons.person_outline,
                size: 70,
                color: Color(0xFF00D9D9),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Raul Osinaga', // Dato harcodeado
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'raul.osinaga@uagrm.edu.bo', // Dato harcodeado
              style: TextStyle(fontSize: 16, color: Color(0xFF8B8B9E)),
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFF3A3A4E)),
            _buildInfoCard(
              icon: Icons.circle,
              label: 'Estado',
              value: 'Activo',
              iconColor: const Color(0xFF4ADE80), // Verde brillante
            ),
            _buildInfoCard(
              icon: Icons.badge_outlined,
              label: 'Registro',
              value: '219072144', // Dato harcodeado
            ),
            _buildInfoCard(
              icon: Icons.school_outlined,
              label: 'Carrera',
              value: 'Ing. Informática', // Dato harcodeado
            ),

            _buildInfoCard(
              icon: Icons.credit_card_outlined,
              label: 'CI',
              value: '12345678 SC', // Dato harcodeado
            ),
            _buildInfoCard(
              icon: Icons.home_outlined,
              label: 'Dirección',
              value: 'Av. Busch, 3er Anillo', // Dato harcodeado
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A4E)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? const Color(0xFF00D9D9),
            size: 24, // Ajustado para el círculo
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF8B8B9E), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
