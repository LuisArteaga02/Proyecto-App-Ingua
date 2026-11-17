import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  // Paleta de colores del sistema
  final Color _bgColor = const Color(0xFF1A1617);
  final Color _cardColor = const Color(0xFF4A2E35);
  final Color _accentColor = const Color(0xFFF2D6BD);
  final Color _darkCardColor = const Color(0xFF351F24);

  // Referencias a Firestore
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _tiposFaltaRef =
      FirebaseFirestore.instance.collection('tipos_falta');
  final CollectionReference _razonesRef =
      FirebaseFirestore.instance.collection('razones_falta');

  // =========================================================================
  // LÓGICA DE APROBACIÓN Y ROLES DE USUARIOS
  // =========================================================================
  Future<void> _aprobarProfesor(String userId) async {
    try {
      await _usersRef.doc(userId).update({
        'status': 'approved',
        'role': 'profesor', // Unificado a profesor/teacher
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Profesor aprobado exitosamente!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aprobar usuario: $e')),
      );
    }
  }

  Future<void> _cambiarRolUsuario(String userId, String nuevoRol) async {
    try {
      await _usersRef.doc(userId).update({
        'role': nuevoRol,
        'status': 'approved', // Asegurar que quede aprobado al cambiar rol
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado exitosamente a: $nuevoRol')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar rol: $e')),
      );
    }
  }

  // =========================================================================
  // LÓGICA CRUD DE TIPOS DE FALTA
  // =========================================================================
  void _mostrarDialogoTipoFalta({String? docId, String? nombreActual}) {
    final TextEditingController controller =
        TextEditingController(text: nombreActual ?? '');
    bool guardando = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            docId == null ? 'Nuevo Tipo de Falta' : 'Editar Tipo de Falta',
            style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: _accentColor),
            maxLength: 100,
            decoration: InputDecoration(
              labelText: 'Nombre de la falta (ej. Falta Grave)',
              labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
              filled: true,
              fillColor: _darkCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: _accentColor.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _cardColor,
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      final nuevoNombre = controller.text.trim();
                      if (nuevoNombre.isEmpty) return;

                      setStateDialog(() => guardando = true);

                      try {
                        if (docId == null) {
                          await _tiposFaltaRef.add({'nombre': nuevoNombre});
                        } else {
                          final batch = FirebaseFirestore.instance.batch();
                          batch.update(
                              _tiposFaltaRef.doc(docId), {'nombre': nuevoNombre});

                          if (nombreActual != null &&
                              nombreActual != nuevoNombre) {
                            final razonesVinculadas = await _razonesRef
                                .where('tipoFalta', isEqualTo: nombreActual)
                                .get();
                            for (var doc in razonesVinculadas.docs) {
                              batch.update(
                                  doc.reference, {'tipoFalta': nuevoNombre});
                            }
                          }
                          await batch.commit();
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(docId == null
                                ? 'Tipo de falta creado'
                                : 'Tipo de falta actualizado'),
                          ),
                        );
                      } catch (e) {
                        setStateDialog(() => guardando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarTipoFalta(String docId, String nombreFalta) {
    bool eliminando = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            'Eliminar Tipo de Falta',
            style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Seguro que deseas eliminar "$nombreFalta"?\n\nSe eliminarán también todos los motivos anexados a esta categoría.',
            style: TextStyle(color: _accentColor.withOpacity(0.9)),
          ),
          actions: [
            TextButton(
              onPressed: eliminando ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: _accentColor.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: eliminando
                  ? null
                  : () async {
                      setStateDialog(() => eliminando = true);
                      try {
                        final batch = FirebaseFirestore.instance.batch();
                        batch.delete(_tiposFaltaRef.doc(docId));

                        final razonesVinculadas = await _razonesRef
                            .where('tipoFalta', isEqualTo: nombreFalta)
                            .get();
                        for (var doc in razonesVinculadas.docs) {
                          batch.delete(doc.reference);
                        }
                        await batch.commit();

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Tipo de falta y motivos eliminados')),
                        );
                      } catch (e) {
                        setStateDialog(() => eliminando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al eliminar: $e')),
                        );
                      }
                    },
              child: eliminando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Eliminar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // LÓGICA CRUD DE MOTIVOS / RAZONES ANEXADAS
  // =========================================================================
  void _mostrarDialogoMotivo({
    required String tipoFaltaPadre,
    String? motivoDocId,
    String? razonActual,
  }) {
    final TextEditingController controller =
        TextEditingController(text: razonActual ?? '');
    bool guardando = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text(
            motivoDocId == null ? 'Nuevo Motivo' : 'Editar Motivo',
            style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anexado a: $tipoFaltaPadre',
                style: TextStyle(
                  color: _accentColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: TextStyle(color: _accentColor),
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'Descripción del motivo',
                  labelStyle: TextStyle(color: _accentColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: _darkCardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: _accentColor.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _cardColor,
              ),
              onPressed: guardando
                  ? null
                  : () async {
                      final texto = controller.text.trim();
                      if (texto.isEmpty) return;

                      setStateDialog(() => guardando = true);

                      try {
                        if (motivoDocId == null) {
                          await _razonesRef.add({
                            'tipoFalta': tipoFaltaPadre,
                            'razon': texto,
                          });
                        } else {
                          await _razonesRef.doc(motivoDocId).update({
                            'razon': texto,
                          });
                        }

                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(motivoDocId == null
                                ? 'Motivo agregado correctamente'
                                : 'Motivo actualizado correctamente'),
                          ),
                        );
                      } catch (e) {
                        setStateDialog(() => guardando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarMotivo(String docId, String textoMotivo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(
          'Eliminar Motivo',
          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Eliminar el motivo:\n"$textoMotivo"?',
          style: TextStyle(color: _accentColor.withOpacity(0.9)),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: _accentColor.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _razonesRef.doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Motivo eliminado')),
              );
            },
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // INTERFAZ PRINCIPAL CON PESTAÑAS
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _cardColor,
          title: Text(
            'Panel de Administración',
            style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: _accentColor),
          bottom: TabBar(
            indicatorColor: _accentColor,
            indicatorWeight: 3,
            labelColor: _accentColor,
            unselectedLabelColor: _accentColor.withOpacity(0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt), text: 'Usuarios y Roles'),
              Tab(icon: Icon(Icons.gavel), text: 'Faltas y Motivos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabUsuarios(),
            _buildTabFaltasYMotivos(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PESTAÑA 1: GESTIÓN DE USUARIOS, APROBACIONES Y ROLES
  // -------------------------------------------------------------------------
  Widget _buildTabUsuarios() {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aprobación de Solicitudes y Roles',
            style: TextStyle(
              color: _cardColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Acepta solicitudes pendientes de profesores o gestiona permisos.',
            style: TextStyle(color: _cardColor.withOpacity(0.75), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay usuarios registrados.',
                      style: TextStyle(color: _cardColor.withOpacity(0.7)),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = doc.id;
                    final email = data['email'] ?? 'Sin correo';
                    final role = data['role'] ?? 'guest';
                    final status = data['status'] ?? 'approved';
                    final isMe = userId == currentUserId;

                    bool isPending = status == 'pending' || status == 'pendiente';

                    Color roleColor;
                    if (role == 'admin') {
                      roleColor = Colors.redAccent;
                    } else if (role == 'teacher' || role == 'profesor' || role == 'professor') {
                      roleColor = Colors.blueAccent;
                    } else {
                      roleColor = Colors.grey;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isPending
                            ? Border.all(color: Colors.orange, width: 2)
                            : null,
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
                          CircleAvatar(
                            backgroundColor: isPending ? Colors.orange : _cardColor,
                            child: Icon(
                              isPending ? Icons.hourglass_top : Icons.person,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Rol: $role',
                                        style: TextStyle(
                                          color: roleColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isPending)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'PENDIENTE',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isMe) ...[
                            // Botón de aprobación rápida si está pendiente
                            if (isPending)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _aprobarProfesor(userId),
                                child: const Text('Aprobar',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.manage_accounts,
                                  color: _cardColor),
                              tooltip: 'Cambiar rol',
                              onSelected: (nuevoRol) =>
                                  _cambiarRolUsuario(userId, nuevoRol),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'professor',
                                  child: Text('Hacer Profesor'),
                                ),
                                PopupMenuItem(
                                  value: 'admin',
                                  child: Text('Hacer Administrador'),
                                ),
                                PopupMenuItem(
                                  value: 'guest',
                                  child: Text('Degradar a Invitado (Guest)'),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              '(Tú)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
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
    );
  }

  // -------------------------------------------------------------------------
  // PESTAÑA 2: CRUD DE FALTAS Y MOTIVOS ANEXADOS
  // ---------------------------------------------------------
  Widget _buildTabFaltasYMotivos() {
    return Container(
      margin: const EdgeInsets.all(16.0),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catálogo de Faltas',
                      style: TextStyle(
                        color: _cardColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Toca una falta para gestionar sus motivos.',
                      style: TextStyle(
                          color: _cardColor.withOpacity(0.75), fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cardColor,
                  foregroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _mostrarDialogoTipoFalta(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva Falta',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _tiposFaltaRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay tipos de falta configurados.\nPresiona "Nueva Falta" para comenzar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _cardColor.withOpacity(0.7)),
                    ),
                  );
                }

                final tiposDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tiposDocs.length,
                  itemBuilder: (context, index) {
                    final doc = tiposDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final nombreFalta = data['nombre'] ?? 'Sin nombre';

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: _cardColor,
                            child: Icon(Icons.warning_amber_rounded,
                                color: _accentColor, size: 20),
                          ),
                          title: Text(
                            nombreFalta,
                            style: TextStyle(
                              color: _cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                tooltip: 'Editar falta',
                                onPressed: () => _mostrarDialogoTipoFalta(
                                  docId: docId,
                                  nombreActual: nombreFalta,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent, size: 20),
                                tooltip: 'Eliminar falta',
                                onPressed: () => _confirmarEliminarTipoFalta(
                                    docId, nombreFalta),
                              ),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(14),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Motivos anexados:',
                                        style: TextStyle(
                                          color: _cardColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _mostrarDialogoMotivo(
                                          tipoFaltaPadre: nombreFalta,
                                        ),
                                        icon: Icon(Icons.add_circle_outline,
                                            color: _cardColor, size: 18),
                                        label: Text(
                                          'Agregar motivo',
                                          style: TextStyle(
                                            color: _cardColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 8),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _razonesRef
                                        .where('tipoFalta',
                                            isEqualTo: nombreFalta)
                                        .snapshots(),
                                    builder: (context, snapshotRazones) {
                                      if (snapshotRazones.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }

                                      if (!snapshotRazones.hasData ||
                                          snapshotRazones.data!.docs.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8.0),
                                          child: Text(
                                            'Aún no hay motivos registrados para esta falta.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        );
                                      }

                                      final razonesDocs =
                                          snapshotRazones.data!.docs;

                                      return ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: razonesDocs.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, rIndex) {
                                          final rDoc = razonesDocs[rIndex];
                                          final rData = rDoc.data()
                                              as Map<String, dynamic>;
                                          final motivoId = rDoc.id;
                                          final textoRazon =
                                              rData['razon'] ?? '';

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.subdirectory_arrow_right,
                                                    size: 16,
                                                    color: _cardColor
                                                        .withOpacity(0.6)),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    textoRazon,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue,
                                                      size: 18),
                                                  tooltip: 'Editar motivo',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  onPressed: () =>
                                                      _mostrarDialogoMotivo(
                                                    tipoFaltaPadre: nombreFalta,
                                                    motivoDocId: motivoId,
                                                    razonActual: textoRazon,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.redAccent,
                                                      size: 18),
                                                  tooltip: 'Eliminar motivo',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  onPressed: () =>
                                                      _confirmarEliminarMotivo(
                                                          motivoId, textoRazon),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
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
    );
  }
}