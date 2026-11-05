
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/screens/admin_approvals_screen.dart';
import '../../reportes/screens/reportes_screen.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userRole = 'guest';
  String _userEmail = '';

  // Grado seleccionado actualmente desde el Drawer (sincronizado con los nombres del guardado)
  String _gradoSeleccionadoFiltro = 'Todos';

  final List<String> _gradosFiltros = [
    'Todos',
    'Tercero Técnico',
    'Segundo Técnico',
    'Primero Técnico',
    'Segundo General',
    'Primero General',
  ];

  // Paleta de colores de la app
  final Color _bgColor = const Color(0xFF1A1617);
  final Color _cardColor = const Color(0xFF4A2E35);
  final Color _accentColor = const Color(0xFFF2D6BD);
  final Color _darkCardColor = const Color(0xFF351F24);

  @override
  void initState() {
    super.initState();
    _obtenerDatosUsuario();
  }

  void _obtenerDatosUsuario() async {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final CollectionReference _alumnosRef =
      FirebaseFirestore.instance.collection('alumnos');

  // Diálogo para Agregar o Editar Alumno
  void _showAlumnoDialog({String? docId, Map<String, dynamic>? currentData}) {
    if (_userRole == 'guest') return;

    final TextEditingController nombreController =
        TextEditingController(text: currentData?['nombre'] ?? '');
    final TextEditingController carnetController =
        TextEditingController(text: currentData?['carnet'] ?? '');

    final List<String> gradosDisponibles = [
      'Primero General',
      'Segundo General',
      'Primero Técnico',
      'Segundo Técnico',
      'Tercero Técnico',
    ];

    String gradoSeleccionado = 'Primero General';
    String seccionSeleccionada = 'A';

    if (currentData != null && currentData['grado'] != null) {
      String gradoActual = currentData['grado'];
      for (var g in gradosDisponibles) {
        if (gradoActual.contains(g)) {
          gradoSeleccionado = g;
          break;
        }
      }
      if (gradoActual.contains('B')) {
        seccionSeleccionada = 'B';
      } else {
        seccionSeleccionada = 'A';
      }
    }

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
                      docId == null ? 'Registrar Nuevo Alumno' : 'Actualizar Alumno',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _accentColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nombreController,
                      style: TextStyle(color: _accentColor),
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: carnetController,
                      style: TextStyle(color: _accentColor),
                      decoration: InputDecoration(
                        labelText: 'Carnet o Código',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: gradoSeleccionado,
                      dropdownColor: _darkCardColor,
                      style: TextStyle(color: _accentColor),
                      decoration: InputDecoration(
                        labelText: 'Grado',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: gradosDisponibles.map((String grado) {
                        return DropdownMenuItem<String>(
                          value: grado,
                          child: Text(grado, style: TextStyle(color: _accentColor)),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        if (nuevoValor != null) {
                          setStateModal(() => gradoSeleccionado = nuevoValor);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Sección:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('A', style: TextStyle(color: _accentColor)),
                            value: 'A',
                            groupValue: seccionSeleccionada,
                            activeColor: _accentColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (String? value) {
                              if (value != null) setStateModal(() => seccionSeleccionada = value);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('B', style: TextStyle(color: _accentColor)),
                            value: 'B',
                            groupValue: seccionSeleccionada,
                            activeColor: _accentColor,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (String? value) {
                              if (value != null) setStateModal(() => seccionSeleccionada = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: _cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final nombre = nombreController.text.trim();
                        final carnet = carnetController.text.trim();
                        final gradoFinal = '$gradoSeleccionado - Sección $seccionSeleccionada';

                        if (nombre.isEmpty || carnet.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa los campos de nombre y carnet')),
                          );
                          return;
                        }

                        if (docId == null) {
                          await _alumnosRef.add({
                            'nombre': nombre,
                            'carnet': carnet,
                            'grado': gradoFinal,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await _alumnosRef.doc(docId).update({
                            'nombre': nombre,
                            'carnet': carnet,
                            'grado': gradoFinal,
                          });
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(
                        docId == null ? 'Guardar Alumno' : 'Actualizar Cambios',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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

  // Diálogo de eliminar alumno
  void _deleteAlumno(String docId) async {
    if (_userRole == 'guest') return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('Eliminar Alumno', style: TextStyle(color: _accentColor)),
        content: Text('¿Estás seguro de eliminar este registro del sistema?', style: TextStyle(color: _accentColor.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: _accentColor.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _alumnosRef.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Diálogo de borrado masivo de sección
  void _confirmarBorradoSeccion(String gradoActual) {
    if (_userRole == 'guest' || gradoActual == 'Todos') return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('⚠️ ADVERTENCIA DE SEGURIDAD', style: TextStyle(color: Colors.redAccent)),
        content: Text(
          'Estás a punto de eliminar a TODOS los alumnos de "$gradoActual". Esta acción no se puede deshacer.\n\n¿Deseas continuar?',
          style: TextStyle(color: _accentColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: _accentColor.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              final querySnapshot = await _alumnosRef.get();
              WriteBatch batch = FirebaseFirestore.instance.batch();
              int count = 0;

              for (var doc in querySnapshot.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final String gradoAlumno = data['grado'] ?? '';
                if (gradoAlumno.contains(gradoActual)) {
                  batch.delete(doc.reference);
                  count++;
                }
              }

              if (count > 0) await batch.commit();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Se eliminaron $count registros de $gradoActual')),
              );
            },
            child: const Text('Sí, eliminar todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        title: Text(
          _userRole == 'guest' ? 'Consulta de Alumnos' : 'Gestión de Alumnos',
          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: _accentColor),
        actions: [
          if (_userRole == 'admin')
            IconButton(
              icon: Icon(Icons.mark_email_unread, color: _accentColor),
              tooltip: 'Solicitudes pendientes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminApprovalsScreen()),
                );
              },
            ),
          if (_userRole != 'guest' && _gradoSeleccionadoFiltro != 'Todos')
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Borrar sección completa',
              onPressed: () => _confirmarBorradoSeccion(_gradoSeleccionadoFiltro),
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _cardColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
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
            const SizedBox(height: 30),
            
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),

            _buildDrawerItem(
              icon: Icons.menu_book,
              title: 'Gestión Alumnos',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
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
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: Color(0xFFF2D6BD), thickness: 1),
            ),

            ..._gradosFiltros.map((grado) {
              bool isSelected = _gradoSeleccionadoFiltro == grado;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Material(
                  color: isSelected ? const Color(0xFFD4B598) : _accentColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _gradoSeleccionadoFiltro = grado;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      alignment: Alignment.center,
                      child: Text(
                        grado,
                        style: TextStyle(
                          color: _cardColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: _cardColor.withOpacity(0.4),
            width: double.infinity,
            child: Text(
              'Mostrando: $_gradoSeleccionadoFiltro',
              style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: _accentColor),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o carnet...',
                labelStyle: TextStyle(color: _accentColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: _accentColor),
                filled: true,
                fillColor: _cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentColor.withOpacity(0.3), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentColor.withOpacity(0.3), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentColor, width: 2),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _accentColor),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _alumnosRef.orderBy('nombre').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _accentColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No hay alumnos registrados aún.', style: TextStyle(color: _accentColor.withOpacity(0.7))),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toLowerCase();
                  final carnet = (data['carnet'] ?? '').toLowerCase();
                  final gradoAlumno = (data['grado'] ?? '');

                  bool cumpleGrado = _gradoSeleccionadoFiltro == 'Todos' || gradoAlumno.contains(_gradoSeleccionadoFiltro);
                  bool cumpleBusqueda = nombre.contains(_searchQuery) || carnet.contains(_searchQuery);

                  return cumpleGrado && cumpleBusqueda;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text('No se encontraron coincidencias.', style: TextStyle(color: _accentColor.withOpacity(0.7))),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _accentColor.withOpacity(0.2), width: 1.5),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _darkCardColor,
                          child: Text(
                            data['nombre'][0].toUpperCase(),
                            style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          data['nombre'] ?? 'Sin Nombre',
                          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Carnet: ${data['carnet']} | Grado: ${data['grado']}',
                          style: TextStyle(color: _accentColor.withOpacity(0.7)),
                        ),
                        trailing: _userRole == 'guest'
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _showAlumnoDialog(docId: docId, currentData: data),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteAlumno(docId),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _userRole == 'guest'
          ? null
          : FloatingActionButton(
              backgroundColor: _cardColor,
              foregroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _accentColor, width: 2),
              ),
              onPressed: () => _showAlumnoDialog(),
              child: const Icon(Icons.add, size: 30),
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
              Icon(icon, color: _cardColor, size: 26),
              const SizedBox(width: 14),
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
