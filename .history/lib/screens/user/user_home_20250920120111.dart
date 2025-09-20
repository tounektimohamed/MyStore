import 'package:flutter/material.dart';
import 'package:store/screens/admin/admin_home.dart';
import 'package:store/screens/admin/product_list.dart';
import 'package:store/screens/user/product_list.dart';
import 'package:store/services/auth_service.dart';

class UserHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boutique en Ligne'),
        actions: [
          // Icône pour accéder au panel admin
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () async {
              // Vérifier si l'utilisateur est admin
              final user = await AuthService().getCurrentUser();
              if (user != null) {
                // Rediriger vers le panel admin
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminHome()),
                );
              } else {
                // Demander la connexion admin
                _showAdminLoginDialog(context);
              }
            },
            tooltip: 'Panel Administrateur',
          ),
        ],
      ),
      body: UserProductList(),
    );
  }

  // Dialog pour la connexion admin
  void _showAdminLoginDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connexion Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email admin',
                  hintText: 'admin@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await AuthService().signInWithEmailAndPassword(
                    emailController.text,
                    passwordController.text,
                  );
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminHome()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur de connexion: $e')),
                  );
                }
              },
              child: Text('Se connecter'),
            ),
          ],
        );
      },
    );
  }
}