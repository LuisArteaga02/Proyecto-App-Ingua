import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Generado por el CLI de FlutterFire
import 'features/auth/screens/login_screen.dart'; // Asegúrate de ajustar esta ruta según la estructura de tu proyecto
import 'dashboards/dashboard_screen.dart';

void main() async {
  // 1. Asegura que los bindings de Flutter estén inicializados antes de llamadas asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase usando las opciones de la plataforma actual (Android, Web, etc.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arranca la aplicación
  runApp(const InguaDemeritosApp());
}

class InguaDemeritosApp extends StatelessWidget {
  const InguaDemeritosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InguaDemeritos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Tu pantalla de inicio de sesión conectada como ruta inicial
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras verifica el estado de la caché local de Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Si el usuario ya inició sesión previamente y sigue autenticado
          if (snapshot.hasData) {
            return const DashboardScreen();
          }

          // Si no hay sesión activa, muestra la pantalla de Login
          return const LoginScreen();
        },
      ),
    );
  }
}