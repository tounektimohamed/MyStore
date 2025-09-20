import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/product.dart';
import '../../services/product_service.dart';

class AddEditProduct extends StatefulWidget {
  final Product? product;

  AddEditProduct({this.product});

  @override
  _AddEditProductState createState() => _AddEditProductState();
}

class _AddEditProductState extends State<AddEditProduct> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si on modifie un produit existant, pré-remplir les champs
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _base64Image = widget.product!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Réduire la taille pour éviter les données trop volumineuses
      maxHeight: 800,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      
      // Convertir l'image en base64
      final bytes = await _imageFile!.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Créer un nouveau produit ou mettre à jour l'existant
        Product product;
        if (widget.product != null) {
          // Modification d'un produit existant
          product = Product(
            id: widget.product!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            price: double.parse(_priceController.text),
            stock: int.parse(_stockController.text),
            imageUrl: _base64Image ?? widget.product!.imageUrl,
          );
          await ProductService().updateProduct(product);
        } else {
          // Création d'un nouveau produit
          product = Product(
            id: '', // L'ID sera généré par Firestore
            name: _nameController.text,
            description: _descriptionController.text,
            price: double.parse(_priceController.text),
            stock: int.parse(_stockController.text),
            imageUrl: _base64Image ?? '',
          );
          await ProductService().addProduct(product);
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePreview() {
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      return Image.memory(
        base64Decode(_base64Image!),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Ajouter produit' : 'Modifier produit'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nom'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: 'Prix'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildImagePreview(),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Choisir une image'),
                    ),
                    SizedBox(height: 16),
                    if (_base64Image != null && _base64Image!.isNotEmpty)
                      Text(
                        'Taille de l\'image: ${(_base64Image!.length / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}