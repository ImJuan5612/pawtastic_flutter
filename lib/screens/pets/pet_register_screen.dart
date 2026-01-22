import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pawtastic/config/supabase_config.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/models/pet.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/services/storage_service.dart';
import 'package:pawtastic/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class PetRegisterScreen extends StatefulWidget {
  final Pet? petToEdit;
  const PetRegisterScreen({super.key, this.petToEdit});

  @override
  State<PetRegisterScreen> createState() => _PetRegisterScreenState();
}

class _PetRegisterScreenState extends State<PetRegisterScreen>
    with TickerProviderStateMixin {
  // Añadir TickerProviderStateMixin
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  File? _selectedImage;
  String?
      _existingImageUrl; // Para guardar la URL de la imagen si se está editando
  bool _isUploading = false;

  String? _selectedSpecies; // Para el nuevo selector de especie
  String? _selectedGender;

  late AnimationController _dogAnimationController;
  late AnimationController _catAnimationController;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _dogAnimationController.dispose();
    _catAnimationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dogAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 2), // Aumentamos la duración para que sea más lenta
    );
    _catAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.petToEdit != null) {
      _nameController.text = widget.petToEdit!.name;
      _selectedSpecies = widget.petToEdit!.species;
      _breedController.text = widget.petToEdit!.breed;
      _ageController.text = widget.petToEdit!.age.toString();
      _weightController.text = widget.petToEdit!.weight.toString();
      _existingImageUrl = widget.petToEdit!.imageUrl;
      _selectedGender = widget.petToEdit!.gender;
      // Activar animación si la especie coincide
      _updateAnimationControllerForSpecies(widget.petToEdit!.species);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? image = await ImageService.pickImage(
        source: source,
        context: context,
      );

      if (image != null) {
        setState(() => _selectedImage = image);
        // La imagen ya no se sube aquí.
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
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
    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una especie')),
      );
      return;
    }

    //Validar que se haya seleccionado un sexo.
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un sexo')),
      );
      return;
    }

    setState(() => _isUploading = true);
    String? imageUrlForPet;
    String? oldImageUrlToDelete;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Subir la imagen a Supabase si se seleccionó una
      if (_selectedImage != null) {
        // Si estamos editando y había una imagen previa, marcarla para eliminar
        if (widget.petToEdit != null && widget.petToEdit!.imageUrl != null) {
          oldImageUrlToDelete = widget.petToEdit!.imageUrl;
        }

        try {
          imageUrlForPet = await StorageService.uploadImage(
            imageFile: _selectedImage!,
            bucket: SupabaseConfig.petsBucket,
            folder: SupabaseConfig.avatarsFolder,
          );
          if (imageUrlForPet == null) {
            throw Exception(
                'No se pudo obtener la URL de la imagen después de subirla.');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir la imagen: $e')),
          );
          setState(() => _isUploading = false);
          return; // Detener si la subida de imagen falla
        }
      } else if (widget.petToEdit != null) {
        // Si no se seleccionó una nueva imagen pero estamos editando, mantenemos la existente
        imageUrlForPet = widget.petToEdit!.imageUrl;
      }

      final pet = Pet(
        id: widget.petToEdit?.id ?? '', // Usar ID existente o vacío para nuevo
        name: _nameController.text,
        species: _selectedSpecies!,
        breed: _breedController.text,
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        userId: userId,
        gender: _selectedGender,
        imageUrl: imageUrlForPet, // Usar la nueva URL o la existente
      );

      final petProvider = Provider.of<PetProvider>(context, listen: false);
      if (widget.petToEdit != null) {
        await petProvider.updatePet(pet);
        // Si se subió una nueva imagen y había una antigua, eliminar la antigua
        if (oldImageUrlToDelete != null &&
            oldImageUrlToDelete != imageUrlForPet) {
          // El método _deleteImage en PetProvider ya extrae el path correctamente.
          // StorageService.deleteImage necesita el path relativo.
          // PetProvider._deleteImage se encarga de esto.
          // No es necesario llamar a StorageService.deleteImage directamente aquí
          // si PetProvider.updatePet o un método específico se encarga de ello.
          // Por ahora, PetProvider.updatePet no elimina la imagen antigua.
          // Lo haremos explícitamente si es necesario, o mejoramos PetProvider.
          // PetProvider.deletePet SÍ elimina la imagen.
          // Para update, PetProvider debería manejarlo.
          // Por ahora, asumimos que si imageUrlForPet es diferente de oldImageUrlToDelete,
          // la imagen antigua debe ser eliminada.
          // PetProvider._deleteImage(oldImageUrlToDelete); // Esto lo haría el provider
        }
      } else {
        await petProvider.addPet(pet);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Mascota ${widget.petToEdit != null ? 'actualizada' : 'registrada'} exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error al ${widget.petToEdit != null ? 'actualizar' : 'registrar'} mascota: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.petToEdit != null ? 'Editar Mascota' : 'Nueva Mascota'),
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
                  widget.petToEdit != null
                      ? 'Actualiza los datos de ${widget.petToEdit!.name}'
                      : '¡Cuéntanos sobre tu mascota!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.petToEdit != null
                      ? 'Modifica la información necesaria.'
                      : 'Completa la información para registrar a tu compañero peludo.',
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
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : _existingImageUrl != null
                                    ? Image.network(
                                        // Mostrar imagen existente si se edita
                                        _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _defaultPetIcon(theme),
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
                      if (_selectedImage == null &&
                          _existingImageUrl ==
                              null) // Mostrar solo si no hay ninguna imagen
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
                _buildSpeciesSelector(), // Nuevo selector de especie
                const SizedBox(height: 16),
                _buildGenderSelector(),
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
                    onPressed: _isUploading ? null : _registerPet,
                    child: _isUploading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            widget.petToEdit != null
                                ? 'Guardar Cambios'
                                : 'Registrar Mascota',
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

  Widget _defaultPetIcon(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Icon(
        Icons.pets_rounded,
        size: 64,
        color: theme.colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Especie',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSpeciesChip(
              label: 'Perro',
              lottieAsset:
                  'assets/animations/dog.json', // Podrías usar Lottie aquí
              value: 'Perro',
              animationController: _dogAnimationController,
              color: Colors.brown,
            ),
            _buildSpeciesChip(
              label: 'Gato',
              lottieAsset:
                  'assets/animations/cat.json', // Podrías usar Lottie aquí
              value: 'Gato',
              animationController: _catAnimationController,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeciesChip({
    required String label,
    // required IconData icon,
    required String lottieAsset,
    required AnimationController animationController,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedSpecies == value;

    return GestureDetector(
      // Cambiamos ChoiceChip por GestureDetector para más control
      onTap: () {
        setState(() {
          bool wasSelected = _selectedSpecies == value;

          if (wasSelected) {
            // Deseleccionar
            _selectedSpecies = null;
            animationController.reset();
          } else {
            // Seleccionar
            _selectedSpecies = value;
            animationController.reset();
            animationController.forward(); // Reproducir animación una vez

            // Resetear la animación del otro chip si estaba seleccionada
            if (value == 'Perro') {
              _catAnimationController.reset();
            } else if (value == 'Gato') {
              _dogAnimationController.reset();
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:
            MediaQuery.of(context).size.width * 0.4, // Hacer el chip más ancho
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Ajustar padding
        decoration: BoxDecoration(
          color: isSelected ? color : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : theme.dividerColor,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          // O Row, según tu diseño
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              lottieAsset,
              controller: animationController,
              width: 100, // Ajustar tamaño de la animación
              height: 100, // Ajustar tamaño de la animación
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sexo',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGenderChip(
              label: 'Macho',
              icon: Icons.male_rounded, // Icono para Macho
              value: 'Macho',
              color: Colors.blue,
            ),
            _buildGenderChip(
              label: 'Hembra',
              icon: Icons.female_rounded, // Icono para Hembra
              value: 'Hembra',
              color: Colors.pink,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedGender == value;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4, // Mantenemos un ancho similar
      child: ChoiceChip(
        label: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.onPrimary : color,
              size: 48, // Icono más grande
            ),
            const SizedBox(height: 8), // Más espacio entre icono y texto
            Text(
              label,
              style: TextStyle(
                fontSize: 16, // Tamaño de fuente más grande
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        showCheckmark: false, // Esto es clave para ocultar la palomita
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedGender = selected ? value : null;
          });
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: color,
        // labelStyle ya no es necesario aquí, se define en el Text dentro de la Column
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? color.withOpacity(0.7) : theme.dividerColor,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), // Padding ajustado
        elevation: isSelected ? 5 : 2,
        pressElevation: 6,
      ),
    );
  }
  void _updateAnimationControllerForSpecies(String? species) {
    if (species == 'Perro') {
      _dogAnimationController.forward(); // Reproducir una vez al iniciar si está preseleccionado
    } else if (species == 'Gato') {
      _catAnimationController.forward(); // Reproducir una vez al iniciar si está preseleccionado
    }
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
