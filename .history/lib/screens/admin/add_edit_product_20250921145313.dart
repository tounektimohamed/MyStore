import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/product.dart';
import '../../services/product_service.dart';

class AddEditProduct extends StatefulWidget {
  final Product? product;

  const AddEditProduct({Key? key, this.product}) : super(key: key);

  @override
  _AddEditProductState createState() => _AddEditProductState();
}

class _AddEditProductState extends State<AddEditProduct> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  Uint8List? _imageBytes;
  String _base64Image = '';
  bool _isLoading = false;
  bool _isWebImage = false;

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
      
      // Vérifier si l'image est une URL web ou base64
      _isWebImage = widget.product!.imageUrl.startsWith('http');
      if (_isWebImage) {
        _imageUrlController.text = widget.product!.imageUrl;
      } else if (widget.product!.imageUrl.isNotEmpty) {
        // Si c'est une image base64, décoder pour l'affichage
        try {
          _imageBytes = base64Decode(widget.product!.imageUrl);
        } catch (e) {
          print('Erreur de décodage base64: $e');
        }
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        
        setState(() {
          _imageBytes = bytes;
          _base64Image = base64Encode(bytes);
          _isWebImage = false;
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _loadImageFromWeb() async {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _base64Image = base64Encode(response.bodyBytes);
          _isWebImage = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement de l\'image (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL invalide ou image non accessible: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl;
      
      // Déterminer la source de l'image
      if (_isWebImage && _imageUrlController.text.isNotEmpty) {
        imageUrl = _imageUrlController.text; // URL web
      } else if (_base64Image.isNotEmpty) {
        imageUrl = _base64Image; // Base64
      } else {
        imageUrl = widget.product?.imageUrl ?? ''; // Garder l'ancienne image
      }

      // Créer un nouveau produit ou mettre à jour l'existant
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        imageUrl: imageUrl,
      );

      if (widget.product != null) {
        await ProductService().updateProduct(product);
      } else {
        await ProductService().addProduct(product);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_isWebImage && _imageUrlController.text.isNotEmpty) {
      return Image.network(
        _imageUrlController.text,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorContainer(),
      );
    } else if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorContainer(),
      );
    } else if (widget.product != null && widget.product!.imageUrl.isNotEmpty) {
      // Afficher l'image existante
      if (widget.product!.imageUrl.startsWith('http')) {
        return Image.network(
          widget.product!.imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorContainer(),
        );
      } else {
        try {
          return Image.memory(
            base64Decode(widget.product!.imageUrl),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildErrorContainer(),
          );
        } catch (e) {
          return _buildErrorContainer();
        }
      }
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

  Widget _buildErrorContainer() {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text('Erreur d\'affichage', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
                    
                    const SizedBox(height: 20),
                    Text('Image du produit', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    // Option 1: URL web
                    TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL de l\'image (web)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: _loadImageFromWeb,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Option 2: Galerie
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choisir depuis la galerie'),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildImagePreview(),
                    
                    const SizedBox(height: 16),
                    if (_base64Image.isNotEmpty && !_isWebImage)
                      Text(
                        'Taille de l\'image: ${(_base64Image.length / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}