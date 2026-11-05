import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/alumnos/screens/alumnos_screen.dart';
import '../features/reportes/screens/reportes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userRole = 'guest';
  String _userEmail = '';

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'guest';
        });
      }
    }
  }

  // MODAL DE CREACIÓN RÁPIDA DE FALTA/DEMÉRITO DIRECTO EN EL DASHBOARD
  void _mostrarCrearReporteModal() {
    if (_userRole == 'guest') return;

    final TextEditingController razonController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController buscarAlumnoController = TextEditingController();

    String tipoSeleccionado = 'Falta Leve';
    final List<String> tiposDisponibles = ['Falta Leve', 'Falta Grave', 'Demerito'];
    List<String> alumnosSeleccionados = [];

    String filtroGradoModal = 'Todos';
    String filtroBusquedaModal = '';
    final List<String> gradosModalLista = [
      'Todos',
      'Primero General',
      'Segundo General',
      'Primero Técnico',
      'Segundo Técnico',
      'Tercero Técnico',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nuevo Reporte de Falta / Demérito',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _accentColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: razonController,
                      style: TextStyle(color: _accentColor),
                      decoration: InputDecoration(
                        labelText: 'Razón de la falta',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      dropdownColor: _darkCardColor,
                      style: TextStyle(color: _accentColor),
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: tiposDisponibles.map((String tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo, style: TextStyle(color: _accentColor)),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        if (nuevoValor != null) {
                          setStateModal(() => tipoSeleccionado = nuevoValor);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descripcionController,
                      style: TextStyle(color: _accentColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción detallada',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alumnos Implicados:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: buscarAlumnoController,
                      style: TextStyle(color: _accentColor, fontSize: 13),
                      onChanged: (value) {
                        setStateModal(() {
                          filtroBusquedaModal = value.toLowerCase().trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar alumno por nombre o carnet...',
                        hintStyle: TextStyle(color: _accentColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: _accentColor, size: 20),
                        filled: true,
                        fillColor: _darkCardColor,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: filtroGradoModal,
                      dropdownColor: _darkCardColor,
                      style: TextStyle(color: _accentColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Filtrar por grado',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: gradosModalLista.map((String grado) {
                        return DropdownMenuItem<String>(
                          value: grado,
                          child: Text(grado, style: TextStyle(color: _accentColor)),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        if (nuevoValor != null) {
                          setStateModal(() => filtroGradoModal = nuevoValor);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _darkCardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('alumnos').orderBy('nombre').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            
                            final alumnosDocs = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final nombre = (data['nombre'] ?? '').toLowerCase();
                              final carnet = (data['carnet'] ?? '').toLowerCase();
                              final gradoAlumno = (data['grado'] ?? '');

                              bool cumpleGrado = filtroGradoModal == 'Todos' || gradoAlumno.contains(filtroGradoModal);
                              bool cumpleBusq = nombre.contains(filtroBusquedaModal) || carnet.contains(filtroBusquedaModal);

                              return cumpleGrado && cumpleBusq;
                            }).toList();

                            if (alumnosDocs.isEmpty) {
                              return Center(
                                child: Text('No se encontraron alumnos', style: TextStyle(color: _accentColor.withOpacity(0.6), fontSize: 13)),
                              );
                            }

                            return ListView.builder(
                              itemCount: alumnosDocs.length,
                              itemBuilder: (context, index) {
                                final doc = alumnosDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final alumnoId = doc.id;
                                final isSelected = alumnosSeleccionados.contains(alumnoId);

                                return CheckboxListTile(
                                  title: Text(data['nombre'] ?? '', style: TextStyle(color: _accentColor, fontSize: 13)),
                                  subtitle: Text(data['grado'] ?? '', style: TextStyle(color: _accentColor.withOpacity(0.6), fontSize: 11)),
                                  value: isSelected,
                                  activeColor: _accentColor,
                                  checkColor: _cardColor,
                                  dense: true,
                                  onChanged: (bool? value) {
                                    setStateModal(() {
                                      if (value == true) {
                                        alumnosSeleccionados.add(alumnoId);
                                      } else {
                                        alumnosSeleccionados.remove(alumnoId);
                                      }
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: _cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final razon = razonController.text.trim();
                        final descripcion = descripcionController.text.trim();

                        if (razon.isEmpty || alumnosSeleccionados.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Escribe una razón y selecciona al menos un alumno')),
                          );
                          return;
                        }

                        final alumnosQuery = await FirebaseFirestore.instance.collection('alumnos').get();
                        List<String> nombresAlumnos = [];
                        for (var doc in alumnosQuery.docs) {
                          if (alumnosSeleccionados.contains(doc.id)) {
                            final data = doc.data();
                            nombresAlumnos.add(data['nombre'] ?? '');
                          }
                        }

                        await FirebaseFirestore.instance.collection('reportes').add({
                          'razon': razon,
                          'tipo': tipoSeleccionado,
                          'descripcion': descripcion,
                          'alumnosIds': alumnosSeleccionados,
                          'alumnosNombres': nombresAlumnos,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar Reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                          'Usuario',
                          style: TextStyle(
                            color: Color(0xFFF2D6BD),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            color: _accentColor.withOpacity(0.7),
                            fontSize: 12,
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
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.popUntil(context, (route) => route.isFirst);
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