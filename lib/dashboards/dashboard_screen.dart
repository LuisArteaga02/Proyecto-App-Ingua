import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/alumnos/screens/alumnos_screen.dart';
import '../features/reportes/screens/reportes_screen.dart';
import '../features/auth/screens/admin_approvals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userRole = 'guest';
  String _userEmail = '';
  String _userName = 'Usuario';
  // Paleta de colores corporativa
  final Color _bgColor = const Color(0xFF1A1617);
  final Color _cardColor = const Color(0xFF4A2E35);
  final Color _accentColor = const Color(0xFFF2D6BD);
  final Color _darkCardColor = const Color(0xFF351F24);

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  void _cargarDatosUsuario() async {
     final user = FirebaseAuth.instance.currentUser;
  
  if (user != null) {
    setState(() {
      _userEmail = user.email ?? 'Usuario';
    });
    
    // Consultamos el documento del usuario en Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _userRole = data['role'] ?? 'guest';
        // Buscamos el campo 'nombre' o 'username' en tu base de datos
        _userName = data['nombre'] ?? data['username'] ?? user.email?.split('@')[0] ?? 'Usuario';
      });
    }
  }
  }

  // MODAL DE CREACIÓN RÁPIDA DE FALTA/DEMÉRITO DIRECTO EN EL DASHBOARD
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        title: Text(
          'Gestión de Deméritos',
          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: _accentColor),
      ),
      drawer: Drawer(
        backgroundColor: _cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _accentColor,
                    child: Icon(Icons.person, color: _cardColor, size: 36),
                  ),
                  const SizedBox(width: 14),
                 Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bienvenido!',
                        style: TextStyle(
                          color: Color(0xFFF2D6BD),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _userName,
                        style: TextStyle(
                          color: _accentColor.withOpacity(0.7),
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ],
              ),
              const SizedBox(height: 50),
              _buildDrawerItem(
                icon: Icons.menu_book,
                title: 'Gestión Alumnos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlumnosScreen()),
                  );
                },
              ),

               const SizedBox(height: 12,),

             if (_userRole == 'admin')

             _buildDrawerItem(
              icon: Icons.menu_book,
              title: 'Gestion Administrador',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminApprovalsScreen()),
                );
                },
            ),

              const SizedBox(height: 16),
              _buildDrawerItem(
                icon: Icons.assignment,
                title: 'Reportes de Faltas',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportesScreen()),
                  );
                },
              ),
              const Spacer(),
               ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                // 1. Cerrar sesión en Firebase Auth
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;

                // 2. Limpiar todas las rutas anteriores y navegar a la pantalla de Login
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/', // O tu ruta/pantalla de Login
                  (route) => false,
                );
              },
            ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PANEL PRINCIPAL CON LOS DEMÉRITOS Y FALTAS MÁS RECIENTES
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deméritos Recientes',
                          style: TextStyle(
                            color: _cardColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward, color: _cardColor),
                          tooltip: 'Ver todos',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ReportesScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reportes')
                            .orderBy('createdAt', descending: true)
                            .limit(6)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'No hay registros recientes',
                                style: TextStyle(color: _cardColor.withOpacity(0.7)),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final List<dynamic> nombres = data['alumnosNombres'] ?? [];
                              final String tipo = data['tipo'] ?? 'Falta Leve';

                              Color badgeColor;
                              if (tipo == 'Demerito') {
                                badgeColor = Colors.redAccent;
                              } else if (tipo == 'Falta Grave') {
                                badgeColor = Colors.orangeAccent;
                              } else {
                                badgeColor = Colors.brown;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _cardColor,
                                      radius: 18,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['razon'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            nombres.join(', '),
                                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tipo,
                                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BOTÓN PROMINENTE DE ACCIÓN RÁPIDA PARA REGISTRAR FALTA O DEMÉRITO
            if (_userRole != 'guest')
              InkWell(
                onTap: _mostrarCrearReporteModal,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accentColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 40, color: _accentColor),
                      const SizedBox(width: 12),
                      Text(
                        'Crear Falta / Demérito',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // FUNCIÓN DE ACCESO RÁPIDO PARA ABRIR EL MODAL DE REGISTRO DE FALTAS / DEMÉRITOS
  void _mostrarCrearReporteModal() {
    if (_userRole == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta es de invitado y solo tiene modo de lectura.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Puedes navegar directamente a la pantalla de reportes donde se despliega el modal,
    // o invocar el diálogo directamente si tienes las referencias a Firestore (_tiposFaltaRef, _razonesRef, etc.) en esta vista.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportesScreen(),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _accentColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: _cardColor, size: 28),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: _cardColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}