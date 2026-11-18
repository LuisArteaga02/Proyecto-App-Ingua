import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../alumnos/screens/alumnos_screen.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  String _userName = 'Usuario';
  String _gradoSeleccionadoFiltro = 'Todos';

  final List<String> _gradosFiltros = [
    'Todos',
    'Tercer Técnico',
    'Segundo Técnico',
    'Primer Técnico',
    'Segundo General',
    'Primero General',
  ];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportarReportePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // 1. CARGAR EL LOGOTIPO DESDE LOS ASSETS DE FLUTTER
    pw.MemoryImage? logoImage;
    try {
      final imageByteData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(imageByteData.buffer.asUint8List());
    } catch (e) {
      // Si no encuentra la imagen, continúa sin romper la app
      logoImage = null;
    }

    final String razon = data['razon'] ?? 'Sin Razón';
    final String tipo = data['tipo'] ?? 'Falta Leve';
    final String descripcion =
        data['descripcion'] ?? 'Sin descripción adicional.';
    final String publicadoPor = data['creadoPor'] ?? 'No especificado';
    final List<dynamic> alumnos = data['alumnosNombres'] ?? [];
    final String grado = data['grado'] ?? 'No especificado';

    // Colores institucionales
    final primaryColor = PdfColor.fromHex('#4A2E35');
    final accentColor = PdfColor.fromHex('#F2D6BD');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==========================================
              // DISEÑO DEL MEMBRETE INSTITUCIONAL
              // ==========================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Lado izquierdo: Logo y Datos de la Institución
                  pw.Row(
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 45,
                          height: 45,
                          child: pw.Image(logoImage),
                        ),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Instituto Nacional',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            'San Jose Guayabal',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.Text(
                            'Sistema de Control Disciplinario',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Lado derecho: Etiqueta de Tipo de Falta y Fecha
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Text(
                      tipo.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              // Línea divisoria elegante con el color de acento
              pw.Divider(color: accentColor, thickness: 2.5),
              pw.SizedBox(height: 15),

              // ==========================================
              // CONTENIDO DEL REPORTE
              // ==========================================
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GRADO / SECCIÓN:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          grado,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'REGISTRADO POR:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          publicadoPor,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'ALUMNOS INVOLUCRADOS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  alumnos.join(', '),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),

              pw.SizedBox(height: 12),

              pw.Text(
                'MOTIVO ESPECÍFICO',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                razon,
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.black),
              ),

              pw.SizedBox(height: 12),

              pw.Text(
                'OBSERVACIONES DEL INCIDENTE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Text(
                  descripcion,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey800,
                  ),
                ),
              ),

              pw.Spacer(),

              // FIRMAS
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 180,
                        child: pw.Divider(color: primaryColor, thickness: 1.5),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Firma del Docente',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 180,
                        child: pw.Divider(color: primaryColor, thickness: 1.5),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Sello / Dirección',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'reporte_disciplinario.pdf',
    );
  }

  final CollectionReference _reportesRef = FirebaseFirestore.instance
      .collection('reportes');
  final CollectionReference _alumnosRef = FirebaseFirestore.instance.collection(
    'alumnos',
  );
  final CollectionReference _tiposFaltaRef = FirebaseFirestore.instance
      .collection('tipos_falta');
  final CollectionReference _razonesRef = FirebaseFirestore.instance.collection(
    'razones_falta',
  );

  // MODAL PARA MOSTRAR DETALLES EXTENSOS DEL REPORTE
  void _mostrarDetalleReporte(Map<String, dynamic> data) {
    final List<dynamic> nombresAlumnos = data['alumnosNombres'] ?? [];
    final String tipo = data['tipo'] ?? 'Falta Leve';
    final String publicadoPor = data['creadoPor'] ?? 'No especificado';

    Color badgeColor;
    if (tipo.toLowerCase().contains('demerito') ||
        tipo.toLowerCase().contains('demérito')) {
      badgeColor = Colors.redAccent;
    } else if (tipo.toLowerCase().contains('grave')) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['razon'] ?? 'Sin Razón',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      tipo,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_pin,
                    color: _accentColor.withOpacity(0.8),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Publicado por: ',
                    style: TextStyle(
                      color: _accentColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      publicadoPor,
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Alumnos Involucrados:',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nombresAlumnos.map((nombre) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                            nombre.toString().isNotEmpty
                                ? nombre.toString()[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: _cardColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nombre.toString(),
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Descripción del Incidente:',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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
                  (data['descripcion'] == null ||
                          data['descripcion'].toString().trim().isEmpty)
                      ? 'Sin descripción adicional.'
                      : data['descripcion'],
                  style: TextStyle(
                    color: _accentColor.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: _cardColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DIÁLOGO PARA CREAR NUEVO TIPO O RAZÓN CON CAPEO DE 300 CARACTERES
  void _mostrarDialogoAgregarOpcion({
    required bool esTipoFalta,
    String? tipoFaltaAsociado,
  }) {
    final TextEditingController controladorInput = TextEditingController();
    bool guardandoOpcion = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            esTipoFalta ? 'Agregar Nuevo Tipo de Falta' : 'Agregar Nueva Razón',
            style: TextStyle(color: _accentColor, fontSize: 18),
          ),
          content: TextField(
            controller: controladorInput,
            style: TextStyle(color: _accentColor),
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: esTipoFalta
                  ? 'Nombre (ej. Falta Gravísima)'
                  : 'Razón detallada...',
              labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
              filled: true,
              fillColor: _darkCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardandoOpcion ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: _accentColor.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _cardColor,
              ),
              onPressed: guardandoOpcion
                  ? null
                  : () async {
                      final texto = controladorInput.text.trim();
                      if (texto.isEmpty) return;

                      setStateDialog(() => guardandoOpcion = true);

                      if (esTipoFalta) {
                        await _tiposFaltaRef.add({'nombre': texto});
                      } else {
                        await _razonesRef.add({
                          'tipoFalta': tipoFaltaAsociado,
                          'razon': texto,
                        });
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Opción agregada exitosamente!'),
                        ),
                      );
                    },
              child: guardandoOpcion
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // DIÁLOGO PRINCIPAL CON COMBO BOX DINÁMICO Y PROTECCIÓN CONTRA DOBLE CLIC
  void _showReporteDialog({String? docId, Map<String, dynamic>? currentData}) {
    if (_userRole == 'guest') return;

    final TextEditingController descripcionController = TextEditingController(
      text: currentData?['descripcion'] ?? '',
    );
    final TextEditingController buscarAlumnoModalController =
        TextEditingController();

    String? tipoSeleccionado = currentData?['tipo'];
    String? razonSeleccionada = currentData?['razon'];
    bool guardandoReporte = false;

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
                      docId == null
                          ? 'Registrar Falta o Demérito'
                          : 'Actualizar Reporte',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // COMBO BOX TIPO DE FALTA
                    StreamBuilder<QuerySnapshot>(
                      stream: _tiposFaltaRef.snapshots(),
                      builder: (context, snapshot) {
                        List<String> listaNombresTipos = [];
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final nombre = doc['nombre'] ?? '';
                            if (nombre.isNotEmpty)
                              listaNombresTipos.add(nombre);
                          }
                        }

                        if ((tipoSeleccionado == null ||
                                !listaNombresTipos.contains(
                                  tipoSeleccionado,
                                )) &&
                            listaNombresTipos.isNotEmpty) {
                          tipoSeleccionado = listaNombresTipos.first;
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: tipoSeleccionado,
                                dropdownColor: _darkCardColor,
                                style: TextStyle(color: _accentColor),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de Falta',
                                  labelStyle: TextStyle(
                                    color: _accentColor.withOpacity(0.7),
                                  ),
                                  filled: true,
                                  fillColor: _darkCardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return listaNombresTipos.map<Widget>((
                                    String item,
                                  ) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item,
                                        style: TextStyle(color: _accentColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                items: listaNombresTipos
                                    .map<DropdownMenuItem<String>>((
                                      String item,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              color: _accentColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                                onChanged: (nuevoValor) {
                                  setStateModal(() {
                                    tipoSeleccionado = nuevoValor;
                                    razonSeleccionada = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: _accentColor,
                                size: 30,
                              ),
                              tooltip: 'Añadir nuevo tipo',
                              onPressed: () => _mostrarDialogoAgregarOpcion(
                                esTipoFalta: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // COMBO BOX RAZÓN ESPECÍFICA
                    StreamBuilder<QuerySnapshot>(
                      stream: _razonesRef
                          .where('tipoFalta', isEqualTo: tipoSeleccionado)
                          .snapshots(),
                      builder: (context, snapshot) {
                        List<String> listaNombresRazones = [];
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final razon = doc['razon'] ?? '';
                            if (razon.isNotEmpty)
                              listaNombresRazones.add(razon);
                          }
                        }

                        if ((razonSeleccionada == null ||
                                !listaNombresRazones.contains(
                                  razonSeleccionada,
                                )) &&
                            listaNombresRazones.isNotEmpty) {
                          razonSeleccionada = listaNombresRazones.first;
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value:
                                    listaNombresRazones.contains(
                                      razonSeleccionada,
                                    )
                                    ? razonSeleccionada
                                    : null,
                                dropdownColor: _darkCardColor,
                                style: TextStyle(color: _accentColor),
                                isExpanded: true,
                                menuMaxHeight: 350,
                                decoration: InputDecoration(
                                  labelText: 'Razón Específica',
                                  labelStyle: TextStyle(
                                    color: _accentColor.withOpacity(0.7),
                                  ),
                                  filled: true,
                                  fillColor: _darkCardColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return listaNombresRazones.map<Widget>((
                                    String item,
                                  ) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item,
                                        style: TextStyle(color: _accentColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                items: listaNombresRazones
                                    .map<DropdownMenuItem<String>>((
                                      String item,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: _accentColor.withOpacity(
                                                  0.15,
                                                ),
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              color: _accentColor,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                                onChanged: (nuevoValor) {
                                  setStateModal(
                                    () => razonSeleccionada = nuevoValor,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: _accentColor,
                                size: 30,
                              ),
                              tooltip: 'Añadir nueva razón',
                              onPressed: tipoSeleccionado == null
                                  ? null
                                  : () => _mostrarDialogoAgregarOpcion(
                                      esTipoFalta: false,
                                      tipoFaltaAsociado: tipoSeleccionado,
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: descripcionController,
                      style: TextStyle(color: _accentColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción del incidente',
                        labelStyle: TextStyle(
                          color: _accentColor.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: _darkCardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alumnos Implicados (Selección Múltiple):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                        fontSize: 14,
                      ),
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
                        hintStyle: TextStyle(
                          color: _accentColor.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: _accentColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: _darkCardColor,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: filtroGradoModal,
                      dropdownColor: _darkCardColor,
                      style: TextStyle(color: _accentColor, fontSize: 13),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por grado',
                        labelStyle: TextStyle(
                          color: _accentColor.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: _darkCardColor,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: gradosModalLista.map((String grado) {
                        return DropdownMenuItem<String>(
                          value: grado,
                          child: Text(
                            grado,
                            style: TextStyle(color: _accentColor),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final alumnosDocs = snapshot.data!.docs.where((
                              doc,
                            ) {
                              final data = doc.data() as Map<String, dynamic>;
                              final nombre = (data['nombre'] ?? '')
                                  .toLowerCase();
                              final carnet = (data['carnet'] ?? '')
                                  .toLowerCase();
                              final gradoAlumno = (data['grado'] ?? '');

                              bool cumpleGradoModal =
                                  filtroGradoModal == 'Todos' ||
                                  gradoAlumno.contains(filtroGradoModal);
                              bool cumpleBusqModal =
                                  nombre.contains(filtroBusquedaModal) ||
                                  carnet.contains(filtroBusquedaModal);

                              return cumpleGradoModal && cumpleBusqModal;
                            }).toList();

                            if (alumnosDocs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No se encontraron alumnos',
                                  style: TextStyle(
                                    color: _accentColor.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: alumnosDocs.length,
                              itemBuilder: (context, index) {
                                final alumnoDoc = alumnosDocs[index];
                                final alumnoData =
                                    alumnoDoc.data() as Map<String, dynamic>;
                                final alumnoId = alumnoDoc.id;
                                final alumnoNombre =
                                    alumnoData['nombre'] ?? 'Sin nombre';
                                final alumnoGrado = alumnoData['grado'] ?? '';
                                final isSelected = alumnosSeleccionados
                                    .contains(alumnoId);

                                return CheckboxListTile(
                                  title: Text(
                                    alumnoNombre,
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    alumnoGrado,
                                    style: TextStyle(
                                      color: _accentColor.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

                    // BOTÓN DE GUARDAR PROTEGIDO CONTRA DOBLE CLIC
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: _cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: guardandoReporte
                          ? null
                          : () async {
                              final descripcion = descripcionController.text
                                  .trim();

                              if (razonSeleccionada == null ||
                                  alumnosSeleccionados.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Selecciona una razón y al menos un alumno',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setStateModal(() => guardandoReporte = true);

                              try {
                                final alumnosQuery = await _alumnosRef.get();
                                List<String> nombresAlumnos = [];
                                String gradoDelAlumno = 'General'; // Grado por defecto si no se encuentra

                                for (var doc in alumnosQuery.docs) {
                                  if (alumnosSeleccionados.contains(doc.id)) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    nombresAlumnos.add(data['nombre'] ?? '');
                                    // Tomamos el grado del alumno seleccionado (o el primero que encuentre)
                                    if (data['grado'] != null) {
                                      gradoDelAlumno = data['grado'];
                                    }
                                  }
                                }

                                if (docId == null) {
                                  await _reportesRef.add({
                                    'razon': razonSeleccionada,
                                    'tipo': tipoSeleccionado ?? 'Falta Leve',
                                    'descripcion': descripcion,
                                    'alumnosIds': alumnosSeleccionados,
                                    'alumnosNombres': nombresAlumnos,
                                    'grado': gradoDelAlumno, // <-- ¡Guardamos el grado aquí!
                                    'creadoPor': _userName,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await _reportesRef.doc(docId).update({
                                    'razon': razonSeleccionada,
                                    'tipo': tipoSeleccionado ?? 'Falta Leve',
                                    'descripcion': descripcion,
                                    'alumnosIds': alumnosSeleccionados,
                                    'alumnosNombres': nombresAlumnos,
                                    'grado': gradoDelAlumno, // <-- Actualizamos el grado también
                                  });
                                }

                                if (!mounted) return;
                                Navigator.pop(context);
                              } catch (e) {
                                setStateModal(() => guardandoReporte = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al guardar: $e'),
                                  ),
                                );
                              }
                            },
                      child: guardandoReporte
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              docId == null
                                  ? 'Guardar Reporte'
                                  : 'Actualizar Reporte',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
        content: Text(
          '¿Estás seguro de eliminar este registro?',
          style: TextStyle(color: _accentColor.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: _accentColor.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _reportesRef.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
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
            const SizedBox(height: 30),
            _buildDrawerItem(
              icon: Icons.menu_book,
              title: 'Gestión Alumnos',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlumnosScreen(),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase().trim()),
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
                stream: _reportesRef
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay reportes de faltas registrados.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final razon = (data['razon'] ?? '').toLowerCase();
                    final descripcion = (data['descripcion'] ?? '')
                        .toLowerCase();
                    final gradoReporte = (data['grado'] ?? '')
                        .toString()
                        .toLowerCase();

                    final List<dynamic> nombresAlumnos =
                        data['alumnosNombres'] ?? [];
                    final bool coincideAlumno = nombresAlumnos.any(
                      (nombre) => nombre.toString().toLowerCase().contains(
                        _searchQuery,
                      ),
                    );

                    // 1. Condición de búsqueda por texto
                    bool cumpleBusqueda =
                        razon.contains(_searchQuery) ||
                        descripcion.contains(_searchQuery) ||
                        coincideAlumno;

                    // 2. Condición de filtrado por grado del Drawer
                    bool cumpleGrado =
                        _gradoSeleccionadoFiltro == 'Todos' ||
                        gradoReporte.contains(
                          _gradoSeleccionadoFiltro.toLowerCase(),
                        );

                    return cumpleBusqueda && cumpleGrado;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron coincidencias.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final docId = doc.id;
                      final List<dynamic> nombresAlumnos =
                          data['alumnosNombres'] ?? [];

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
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // TARJETA FLEXIBLE PARA QUE EL TEXTO LARGO NUNCA ROMPA LA PANTALLA MÓVIL
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['razon'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Alumnos: ${nombresAlumnos.join(', ')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    data['tipo'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // MENÚ DESPLEGABLE (DROPDOWN DE ACCIONES) PARA MÓVIL
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.black54,
                              ),
                              tooltip: 'Opciones',
                              onSelected: (value) {
                                if (value == 'ver') {
                                  _mostrarDetalleReporte(data);
                                } else if (value == 'pdf') {
                                  _exportarReportePdf(
                                    data,
                                  ); // <-- ¡Aquí invocamos la exportación!
                                } else if (value == 'editar') {
                                  _showReporteDialog(
                                    docId: docId,
                                    currentData: data,
                                  );
                                } else if (value == 'eliminar') {
                                  _deleteReporte(docId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'ver',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        color: Colors.teal,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Ver detalles'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Exportar a PDF'),
                                    ],
                                  ),
                                ),
                                if (_userRole != 'guest') ...[
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Eliminar'),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
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
    print('Construyendo ítem del menú lateral: $title');
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
