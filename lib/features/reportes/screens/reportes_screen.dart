import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../alumnos/screens/alumnos_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _userRole = 'guest';
  String _userEmail = '';

  // Filtro de grado seleccionado desde el menú lateral
  String _gradoSeleccionadoFiltro = 'Todos';

  final List<String> _gradosFiltros = [
    'Todos',
    'Tercero Técnico',
    'Segundo Técnico',
    'Primero Técnico',
    'Segundo General',
    'Primero General',
  ];

  // Paleta de colores corporativa
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

  final CollectionReference _reportesRef =
      FirebaseFirestore.instance.collection('reportes');
  final CollectionReference _alumnosRef =
      FirebaseFirestore.instance.collection('alumnos');

  // MODAL PARA MOSTRAR DETALLES EXTENSOS DEL REPORTE, ALUMNOS Y EL AUTOR
  void _mostrarDetalleReporte(Map<String, dynamic> data) {
    final List<dynamic> nombresAlumnos = data['alumnosNombres'] ?? [];
    final String tipo = data['tipo'] ?? 'Falta Leve';
    final String publicadoPor = data['creadoPor'] ?? 'No especificado';

    Color badgeColor;
    if (tipo == 'Demerito') {
      badgeColor = Colors.redAccent;
    } else if (tipo == 'Falta Grave') {
      badgeColor = Colors.orangeAccent;
    } else {
      badgeColor = Colors.amber;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accentColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con Razón y Tipo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['razon'] ?? 'Sin Razón',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      tipo,
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // MOSTRAR EL USUARIO QUE PUBLICÓ EL REPORTE
              Row(
                children: [
                  Icon(Icons.person_pin, color: _accentColor.withOpacity(0.8), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Publicado por: ',
                    style: TextStyle(color: _accentColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      publicadoPor,
                      style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Alumnos implicados en tarjetas visuales
              Text(
                'Alumnos Involucrados:',
                style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nombresAlumnos.map((nombre) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _darkCardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _accentColor,
                          child: Text(
                            nombre.toString().isNotEmpty ? nombre.toString()[0].toUpperCase() : '?',
                            style: TextStyle(color: _cardColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nombre.toString(),
                          style: TextStyle(color: _accentColor, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Descripción Detallada
              Text(
                'Descripción del Incidente:',
                style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _darkCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (data['descripcion'] == null || data['descripcion'].toString().trim().isEmpty)
                      ? 'Sin descripción adicional.'
                      : data['descripcion'],
                  style: TextStyle(color: _accentColor.withOpacity(0.9), fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Botón de cerrar
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: _cardColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Diálogo para Crear o Editar un Reporte
  void _showReporteDialog({String? docId, Map<String, dynamic>? currentData}) {
    if (_userRole == 'guest') return;

    final TextEditingController razonController =
        TextEditingController(text: currentData?['razon'] ?? '');
    final TextEditingController descripcionController =
        TextEditingController(text: currentData?['descripcion'] ?? '');
    final TextEditingController buscarAlumnoModalController = TextEditingController();

    String tipoSeleccionado = currentData?['tipo'] ?? 'Falta Leve';
    final List<String> tiposDisponibles = ['Falta Leve', 'Falta Grave', 'Demerito'];

    List<String> alumnosSeleccionados = [];
    if (currentData != null && currentData['alumnosIds'] != null) {
      alumnosSeleccionados = List<String>.from(currentData['alumnosIds']);
    }

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
                      docId == null ? 'Registrar Falta o Demérito' : 'Actualizar Reporte',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _accentColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: razonController,
                      style: TextStyle(color: _accentColor),
                      decoration: InputDecoration(
                        labelText: 'Razón (ej. Llegar tarde, Vestimenta)',
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
                        labelText: 'Descripción del incidente',
                        labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alumnos Implicados (Selección Múltiple):',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: buscarAlumnoModalController,
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
                      height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _darkCardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _alumnosRef.orderBy('nombre').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final alumnosDocs = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final nombre = (data['nombre'] ?? '').toLowerCase();
                              final carnet = (data['carnet'] ?? '').toLowerCase();
                              final gradoAlumno = (data['grado'] ?? '');

                              bool cumpleGradoModal = filtroGradoModal == 'Todos' || gradoAlumno.contains(filtroGradoModal);
                              bool cumpleBusqModal = nombre.contains(filtroBusquedaModal) || carnet.contains(filtroBusquedaModal);

                              return cumpleGradoModal && cumpleBusqModal;
                            }).toList();

                            if (alumnosDocs.isEmpty) {
                              return Center(
                                child: Text('No se encontraron alumnos', style: TextStyle(color: _accentColor.withOpacity(0.6), fontSize: 13)),
                              );
                            }

                            return ListView.builder(
                              itemCount: alumnosDocs.length,
                              itemBuilder: (context, index) {
                                final alumnoDoc = alumnosDocs[index];
                                final alumnoData = alumnoDoc.data() as Map<String, dynamic>;
                                final alumnoId = alumnoDoc.id;
                                final alumnoNombre = alumnoData['nombre'] ?? 'Sin nombre';
                                final alumnoGrado = alumnoData['grado'] ?? '';
                                final isSelected = alumnosSeleccionados.contains(alumnoId);

                                return CheckboxListTile(
                                  title: Text(alumnoNombre, style: TextStyle(color: _accentColor, fontSize: 13)),
                                  subtitle: Text(alumnoGrado, style: TextStyle(color: _accentColor.withOpacity(0.6), fontSize: 11)),
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
                    const SizedBox(height: 24),
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

                        final alumnosQuery = await _alumnosRef.get();
                        List<String> nombresAlumnos = [];
                        for (var doc in alumnosQuery.docs) {
                          if (alumnosSeleccionados.contains(doc.id)) {
                            final data = doc.data() as Map<String, dynamic>;
                            nombresAlumnos.add(data['nombre'] ?? '');
                          }
                        }

                        if (docId == null) {
                          // AL CREAR UN REPORTE NUEVO, SE GUARDA EL EMAIL DEL AUTOR
                          await _reportesRef.add({
                            'razon': razon,
                            'tipo': tipoSeleccionado,
                            'descripcion': descripcion,
                            'alumnosIds': alumnosSeleccionados,
                            'alumnosNombres': nombresAlumnos,
                            'creadoPor': _userEmail,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          // AL ACTUALIZAR, CONSERVAMOS LOS DATOS Y SOLO ACTUALIZAMOS LOS CAMPOS EDITADOS
                          await _reportesRef.doc(docId).update({
                            'razon': razon,
                            'tipo': tipoSeleccionado,
                            'descripcion': descripcion,
                            'alumnosIds': alumnosSeleccionados,
                            'alumnosNombres': nombresAlumnos,
                          });
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: Text(
                        docId == null ? 'Guardar Reporte' : 'Actualizar Reporte',
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

  void _deleteReporte(String docId) async {
    if (_userRole == 'guest') return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('Eliminar Reporte', style: TextStyle(color: _accentColor)),
        content: Text('¿Estás seguro de eliminar este registro?', style: TextStyle(color: _accentColor.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: _accentColor.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _reportesRef.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
          'Reportes de Faltas',
          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: _accentColor),
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
              icon: Icons.menu_book,
              title: 'Gestión Alumnos',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AlumnosScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildDrawerItem(
              icon: Icons.assignment,
              title: 'Reportes de Faltas',
              onTap: () => Navigator.pop(context),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: Color(0xFFF2D6BD), thickness: 1),
            ),
            
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
      body: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(color: _cardColor),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
              decoration: InputDecoration(
                labelText: 'Buscar por razón, descripción o alumno...',
                labelStyle: TextStyle(color: _cardColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: _cardColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _reportesRef.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No hay reportes de faltas registrados.', style: TextStyle(color: Colors.black54)),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final razon = (data['razon'] ?? '').toLowerCase();
                    final descripcion = (data['descripcion'] ?? '').toLowerCase();
                    
                    final List<dynamic> nombresAlumnos = data['alumnosNombres'] ?? [];
                    final bool coincideAlumno = nombresAlumnos.any((nombre) => nombre.toString().toLowerCase().contains(_searchQuery));

                    bool cumpleBusqueda = razon.contains(_searchQuery) || 
                                          descripcion.contains(_searchQuery) || 
                                          coincideAlumno;
                    return cumpleBusqueda;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron coincidencias.', style: TextStyle(color: Colors.black54)),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;
                      final List<dynamic> nombresAlumnos = data['alumnosNombres'] ?? [];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['razon'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(data['tipo'] ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                nombresAlumnos.join(', '),
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                data['descripcion'] ?? '',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Botón de ver detalles
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.teal, size: 20),
                              tooltip: 'Ver detalles',
                              onPressed: () => _mostrarDetalleReporte(data),
                            ),
                            if (_userRole != 'guest') ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                tooltip: 'Editar',
                                onPressed: () => _showReporteDialog(docId: docId, currentData: data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                tooltip: 'Eliminar',
                                onPressed: () => _deleteReporte(docId),
                              ),
                            ],
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
      floatingActionButton: _userRole == 'guest'
          ? null
          : FloatingActionButton(
              backgroundColor: _cardColor,
              foregroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _accentColor, width: 2),
              ),
              onPressed: () => _showReporteDialog(),
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