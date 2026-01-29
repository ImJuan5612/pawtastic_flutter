import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pawtastic/services/image_service.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/screens/main/home_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Para File
import 'package:supabase_flutter/supabase_flutter.dart'; // Necesario para UserAttributes

class PersonalDataScreen extends StatefulWidget {
  final bool isEditingProfile;
  const PersonalDataScreen({super.key, this.isEditingProfile = false});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImageFile;
  String? _existingAvatarUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditingProfile) {
      _loadProfileData();
    }
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'El campo "$fieldName" es requerido';
    }
    return null;
  }

  // String? _validateName(String? value, String fieldName) { // Ya no se usa esta validación específica
  //   if (value == null || value.isEmpty) {
  //     return 'El campo "$fieldName" es requerido';
  //   }
  //   if (value.trim().split(' ').length < 2) { // Esta validación podría ser muy restrictiva
  //     return 'Ingresa tu nombre completo';
  //   }
  //   return null;
  // }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El campo "Teléfono" es requerido';
    }
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    // final ImagePicker picker = ImagePicker();
    // Usar el ImageService que ya tienes para consistencia y permisos
    // final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    final File? imageFile = await ImageService.pickImage(
      source: source, 
      context: context, 
      imageQuality: 70 // Puedes ajustar la calidad
    );

    if (imageFile != null) {
      setState(() {
        _selectedImageFile = imageFile;
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library), title: const Text('Galería'), onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.gallery); }),
              ListTile(
                leading: const Icon(Icons.photo_camera), title: const Text('Cámara'), onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.camera); },
              ),
            ],
          ),
        );
      });
  }

  Future<String?> _uploadAvatar(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '$userId/profile.$fileExt'; // Guarda en una carpeta con el ID del usuario
    final filePath = fileName; // El bucket 'avatars' ya está implícito

    await Supabase.instance.client.storage.from('avatars').uploadBinary(
        filePath, await imageFile.readAsBytes(),
        fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true));
    return Supabase.instance.client.storage.from('avatars').getPublicUrl(filePath);
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) return;

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', authProvider.user!.id)
          .maybeSingle(); // Usar maybeSingle para manejar si no hay perfil aún

      if (profileResponse != null) {
        _firstNameController.text = profileResponse['nombre'] ?? '';
        _lastNameController.text = profileResponse['apellido'] ?? '';
        _phoneController.text = profileResponse['telefono'] ?? '';
        _addressController.text = profileResponse['direccion'] ?? '';
        _cityController.text = profileResponse['ciudad'] ?? '';
        _postalCodeController.text = profileResponse['codigo_postal'] ?? '';
        if (profileResponse['avatar_url'] != null) {
          setState(() {
            _existingAvatarUrl = profileResponse['avatar_url'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos del perfil: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePersonalData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception("Usuario no autenticado.");
      }

      String? avatarUrl;
      if (_selectedImageFile != null) {
        // Si hay una imagen seleccionada, se sube.
        avatarUrl = await _uploadAvatar(authProvider.user!.id, _selectedImageFile!);
      } else if (widget.isEditingProfile) {
        // Si estamos editando y no se seleccionó nueva imagen, mantenemos la existente.
        avatarUrl = _existingAvatarUrl;
      }


      final profileData = {
        'id': authProvider.user!.id,
        'nombre': _firstNameController.text.trim(),
        'apellido': _lastNameController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _addressController.text.trim(),
        'ciudad': _cityController.text.trim(),
        'codigo_postal': _postalCodeController.text.trim(),
        'email': authProvider.user!.email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        // created_at y updated_at se manejan por defecto en la DB
      };

      // Usar upsert en lugar de insert para manejar conflictos de clave primaria (id)
      // Esto insertará si el id no existe, o actualizará si ya existe.
      await Supabase.instance.client.from('profiles').upsert(
            profileData,
            onConflict: 'id', // Especifica la columna que causa el conflicto
          );

      // Actualizar user_metadata solo con el contenido del campo Nombre(s)
      final displayName = _firstNameController.text.trim();
      await Supabase.instance.client.auth.updateUser(UserAttributes(
        data: {
          'display_name': displayName,
          if (avatarUrl != null) 'avatar_url': avatarUrl, // Opcional: guardar también en metadata
        },
      ));
      // Es buena idea refrescar el usuario en el AuthProvider para que tenga los metadatos actualizados.
      await authProvider.refreshUser(); 

      if (!mounted) return;

      if (widget.isEditingProfile) {
        Navigator.of(context).pop(); // Volver a la pantalla anterior (ProfileTab)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado con éxito')));
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar datos: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.isEditingProfile, // Mostrar botón de atrás si se está editando
        leading: widget.isEditingProfile ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        title: Text(
          widget.isEditingProfile ? 'Editar Perfil' : 'Completa tu Perfil'
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), //_isLoading ? NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 100),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              backgroundImage: _selectedImageFile != null 
                                  ? FileImage(_selectedImageFile!) as ImageProvider
                                  : (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(_existingAvatarUrl!)
                                      : null),
                              child: _selectedImageFile == null
                                  && (_existingAvatarUrl == null || _existingAvatarUrl!.isEmpty)
                                  ? FadeIn( // Para que el icono no aparezca bruscamente si la imagen tarda en cargar
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 60,
                                        color: theme.colorScheme.primary.withOpacity(0.7),
                                      ))
                                  : null,
                            ),
                            Material(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: _isLoading ? null : () => _showImageSourceActionSheet(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.onSecondary, size: 18),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        widget.isEditingProfile 
                            ? 'Actualiza tu información' 
                            : '¡Casi listo!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInDown(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        widget.isEditingProfile 
                            ? 'Mantén tus datos al día.' 
                            : 'Ayúdanos a conocerte un poco mejor.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color:
                              theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      delay: const Duration(milliseconds: 600),
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'Nombre(s)',
                        hint: 'Ej: Ana',
                        icon: Icons.person_outline_rounded,
                        validator: (value) =>
                            _validateNotEmpty(value, 'Nombre(s)'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      delay: const Duration(milliseconds: 700),
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Apellidos',
                        hint: 'Ej: Pérez López',
                        icon: Icons.person_outline_rounded,
                        validator: (value) =>
                            _validateNotEmpty(value, 'Apellidos'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      delay: const Duration(milliseconds: 800),
                      child: _buildTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        hint: 'Ej: +52 5512345678',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      delay: const Duration(milliseconds: 900),
                      child: _buildTextField(
                        controller: _addressController,
                        label: 'Dirección',
                        hint: 'Ej: Calle Falsa 123, Colonia Centro',
                        icon: Icons.location_on_outlined,
                        validator: (value) =>
                            _validateNotEmpty(value, 'Dirección'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      delay: const Duration(milliseconds: 1000),
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'Ciudad',
                        hint: 'Ej: Ciudad de México',
                        icon: Icons.location_city_rounded,
                        validator: (value) =>
                            _validateNotEmpty(value, 'Ciudad'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInDown(
                      delay: const Duration(milliseconds: 1100),
                      child: _buildTextField(
                        controller: _postalCodeController,
                        label: 'Código Postal',
                        hint: 'Ej: 06000',
                        icon: Icons.markunread_mailbox_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validateNotEmpty(value, 'Código Postal'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInDown(
                      delay: const Duration(milliseconds: 1200), // Ajustar delay por el nuevo elemento
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          onPressed: _isLoading ? null : _savePersonalData,
                          label: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(widget.isEditingProfile 
                                  ? 'Guardar Cambios' 
                                  : 'Guardar y Continuar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      enabled: !_isLoading && enabled,
      textCapitalization: textCapitalization,
    );
  }
}
