import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/screens/login_screen.dart';

class ProfessorDashboard extends StatelessWidget {
  const ProfessorDashboard({super.key});

  // Función para cerrar sesión
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Diálogo para registrar un nuevo demérito
  void _showAddDemeritModal(BuildContext context) {
    final studentController = TextEditingController();
    final reasonController = TextEditingController();
    String severityLevel = 'Leve'; // Opciones: Leve, Grave, Muy Grave

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar Demérito / Reporte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentController,
                  decoration: const InputDecoration(labelText: 'Nombre del Alumno / Grado'),
                ),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Motivo de la falta'),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: severityLevel,
                  decoration: const InputDecoration(labelText: 'Gravedad de la falta'),
                  items: ['Leve', 'Grave', 'Muy Grave']
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList,
                  onChanged: (value) {
                    if (value != null) severityLevel = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (studentController.text.isNotEmpty && reasonController.text.isNotEmpty) {
                  // Guardar en Firestore en una colección llamada 'demerits'
                  await FirebaseFirestore.instance.collection('demerits').add({
                    'studentName': studentController.text.trim(),
                    'reason': reasonController.text.trim(),
                    'severity': severityLevel,
                    'professorEmail': FirebaseAuth.instance.currentUser?.email ?? 'Desconocido',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demérito registrado exitosamente')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Profesor - Control Disciplinario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escuchamos en tiempo real los deméritos registrados en Firestore
        stream: FirebaseFirestore.instance
            .collection('demerits')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay deméritos registrados todavía.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final student = data['studentName'] ?? 'Sin nombre';
              final reason = data['reason'] ?? 'Sin motivo';
              final severity = data['severity'] ?? 'Leve';
              final professor = data['professorEmail'] ?? '';

              // Color indicador según la gravedad
              Color severityColor = Colors.orange;
              if (severity == 'Grave') severityColor = Colors.deepOrange;
              if (severity == 'Muy Grave') severityColor = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: severityColor,
                    child: const Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(student, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Falta: $reason'),
                      const SizedBox(height: 4),
                      Text('Registrado por: $professor', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(severity, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    backgroundColor: severityColor,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDemeritModal(context),
        child: const Icon(Icons.add),
        tooltip: 'Agregar Demérito',
      ),
    );
  }
}