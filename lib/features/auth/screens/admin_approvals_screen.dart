import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Aprobación de Profesores'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay solicitudes pendientes de aprobación.'),
            );
          }

          final pendingUsers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final doc = pendingUsers[index];
              final data = doc.data() as Map<String, dynamic>;
              final userId = doc.id;
              final email = data['email'] ?? 'Sin correo';
              final role = data['role'] ?? 'professor';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.pending_actions, color: Colors.white),
                  ),
                  title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rol solicitado: $role'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Aprobar
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                        tooltip: 'Aprobar',
                        onPressed: () async {
                          await usersRef.doc(userId).update({'status': 'approved'});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profesor aprobado con éxito')),
                          );
                        },
                      ),
                      // Botón Rechazar (Elimina la cuenta o la rechaza)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                        tooltip: 'Rechazar',
                        onPressed: () async {
                          await usersRef.doc(userId).delete(); // O cambiar status a 'rejected'
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Solicitud rechazada')),
                          );
                        },
                      ),
                    ],
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