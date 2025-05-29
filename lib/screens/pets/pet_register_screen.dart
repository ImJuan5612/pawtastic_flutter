import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/models/pet.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/services/storage_service.dart';
import 'package:pawtastic/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class PetRegisterScreen extends StatefulWidget {
  const PetRegisterScreen({super.key});

  @override
  State<PetRegisterScreen> createState() => _PetRegisterScreenState();
}

class _PetRegisterScreenState extends State<PetRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  File? _selectedImage;
  String? _selectedImageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? image = await ImageService.pickImage(
        source: source,
        context: context,
      );

      if (image != null) {
        setState(() => _selectedImage = image);
        setState(() => _isUploading = true);

        // Subir la imagen a Supabase
        final imageUrl = await StorageService.uploadImage(
          imageFile: image,
          bucket: 'pets',
          folder: 'avatars',
        );

        if (imageUrl != null) {
          setState(() => _selectedImageUrl = imageUrl);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _registerPet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final pet = Pet(
        id: '', // Se generará en la base de datos
        name: _nameController.text,
        species: _speciesController.text,
        breed: _breedController.text,
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        userId: userId,
        imageUrl: _selectedImageUrl,
      );

      await Provider.of<PetProvider>(context, listen: false).addPet(pet);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mascota registrada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar mascota: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Mascota'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.background.withBlue(250),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Cuéntanos sobre tu mascota!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa la información para registrar a tu compañero peludo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isUploading
                              ? Center(
                                  child: Lottie.asset(
                                    'assets/animations/pet-loading.json',
                                    width: 100,
                                    height: 100,
                                  ),
                                )
                              : ClipOval(
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: theme.colorScheme.surface,
                                          child: Icon(
                                            Icons.pets_rounded,
                                            size: 64,
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                ),
                        ),
                      ),
                      if (_selectedImage == null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildInputField(
                  controller: _nameController,
                  label: 'Nombre',
                  hint: '¿Cómo se llama tu mascota?',
                  icon: Icons.pets_rounded,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _speciesController,
                  label: 'Especie',
                  hint: 'Ej: Perro, Gato, etc.',
                  icon: Icons.category_rounded,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _breedController,
                  label: 'Raza',
                  hint: 'Ej: Labrador, Siamés, etc.',
                  icon: Icons.pets_rounded,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _ageController,
                        label: 'Edad',
                        hint: 'Años',
                        icon: Icons.cake_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _weightController,
                        label: 'Peso',
                        hint: 'Kg',
                        icon: Icons.monitor_weight_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _registerPet,
                    child: Text(
                      'Registrar Mascota',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        if (keyboardType == TextInputType.number) {
          if (double.tryParse(value) == null) {
            return 'Ingrese un número válido';
          }
        }
        return null;
      },
    );
  }
}
