import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/category_model.dart';
import 'package:smart_rent/services/category_service.dart';
import 'package:smart_rent/services/gown_service.dart';

class AddGownScreen extends StatefulWidget {
  const AddGownScreen({super.key});

  @override
  State<AddGownScreen> createState() => _AddGownScreenState();
}

class _AddGownScreenState extends State<AddGownScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Category
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _loadingCategories = true;

  // Measurements — default list, admin can add more
  final List<Map<String, dynamic>> _measurements = [
    {'label': 'Bust', 'controller': TextEditingController()},
    {'label': 'Waist', 'controller': TextEditingController()},
    {'label': 'Hips', 'controller': TextEditingController()},
    {'label': 'Shoulder Width', 'controller': TextEditingController()},
    {'label': 'Hollow to Hem', 'controller': TextEditingController()},
    {'label': 'Armhole', 'controller': TextEditingController()},
    {'label': 'Sleeve Length', 'controller': TextEditingController()},
    {'label': 'Neck Circumference', 'controller': TextEditingController()},
    {'label': 'Back Width', 'controller': TextEditingController()},
    {'label': 'Height', 'controller': TextEditingController()},
  ];

  // Images
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    for (final m in _measurements) {
      (m['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    }
  }

  // Request gallery/camera permission — one time only
  // Future<bool> _requestPermission() async {
  //   final photos = await Permission.photos.request();
  //   final camera = await Permission.camera.request();

  //   if (photos.isPermanentlyDenied || camera.isPermanentlyDenied) {
  //     if (mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (_) => AlertDialog(
  //           title: const Text('Permission Required'),
  //           content: const Text(
  //             'Please allow SmartRent to access your gallery and camera in Settings.',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel',
  //                   style: TextStyle(color: AppColors.textLight)),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 openAppSettings();
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('Open Settings',
  //                   style: TextStyle(color: AppColors.primary)),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //     return false;
  //   }

  //   return photos.isGranted && camera.isGranted;
  // }

//   Future<bool> _requestPermission() async {
//   final Map<Permission, PermissionStatus> statuses = await [
//     Permission.photos,
//     Permission.camera,
//     Permission.storage,
//   ].request();

//   final photos = statuses[Permission.photos];
//   final camera = statuses[Permission.camera];
//   final storage = statuses[Permission.storage];

//   if (photos!.isPermanentlyDenied ||
//       camera!.isPermanentlyDenied ||
//       storage!.isPermanentlyDenied) {
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text('Permission Required'),
//           content: const Text(
//             'Please allow SmartRent to access your gallery and camera in Settings.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel',
//                   style: TextStyle(color: AppColors.textLight)),
//             ),
//             TextButton(
//               onPressed: () {
//                 openAppSettings();
//                 Navigator.pop(context);
//               },
//               child: const Text('Open Settings',
//                   style: TextStyle(color: AppColors.primary)),
//             ),
//           ],
//         ),
//       );
//     }
//     return false;
//   }

//   return (photos.isGranted || photos.isLimited) &&
//       camera!.isGranted &&
//       (storage.isGranted || storage.isLimited);
// }

  // Future<void> _pickImages() async {
  //   final granted = await _requestPermission();
  //   if (!granted) return;

  //   final picked = await _picker.pickMultiImage(imageQuality: 80);
  //   if (picked.isNotEmpty) {
  //     setState(() {
  //       for (final img in picked) {
  //         if (_selectedImages.length < 5) {
  //           _selectedImages.add(File(img.path));
  //         }
  //       }
  //     });
  //   }
  // }

  Future<void> _pickImages() async {
  try {
    // Request appropriate permission based on Android version
    PermissionStatus status;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        status = await Permission.photos.request();
      } else {
        // Android 12 and below
        status = await Permission.storage.request();
      }

      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return;
      }

      if (!status.isGranted) return;
    }

    // Open gallery
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        for (final img in picked) {
          if (_selectedImages.length < 5) {
            _selectedImages.add(File(img.path));
          }
        }
      });
    }
  } catch (e) {
    _showSnackbar('Could not open gallery. Please try again.');
  }
}

void _showPermissionDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Permission Required'),
      content: const Text(
        'Please allow SmartRent to access your gallery in Settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textLight)),
        ),
        TextButton(
          onPressed: () {
            openAppSettings();
            Navigator.pop(context);
          },
          child: const Text('Open Settings',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
  );
}

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // Add new measurement field dynamically
  void _addMeasurementField() {
    showDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Measurement'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Thigh Circumference',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _measurements.add({
                      'label': controller.text.trim(),
                      'controller': TextEditingController(),
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  // Add new category inline
  void _addCategoryDialog() {
    showDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Wedding',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  final newCategory = await CategoryService.addCategory(
                      controller.text.trim());
                  if (newCategory != null && mounted) {
                    setState(() {
                      _categories.add(newCategory);
                      _selectedCategory = newCategory;
                    });
                  }
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGown() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackbar('Please select a category');
      return;
    }

    setState(() => _isSaving = true);

    // Build measurements map
    final Map<String, String> measurementsMap = {};
    for (final m in _measurements) {
      final value = (m['controller'] as TextEditingController).text.trim();
      if (value.isNotEmpty) {
        measurementsMap[m['label'] as String] = value;
      }
    }

    final success = await GownService.addGown(
      name: _nameController.text.trim(),
      category: _selectedCategory!.name,
      color: _colorController.text.trim(),
      measurements: measurementsMap,
      rentalPrice: double.tryParse(_priceController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim(),
      images: _selectedImages,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _showSnackbar('Gown saved successfully');
        Navigator.pop(context);
      } else {
        _showSnackbar('Failed to save gown. Please try again.');
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Gown',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Gown Name
                _FieldLabel(label: 'GOWN NAME'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _nameController,
                  hint: 'Enter gown name',
                  prefixIcon: Icons.checkroom_outlined,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter gown name'
                      : null,
                ),

                const SizedBox(height: 20),

                // Category + Color row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'CATEGORY'),
                          const SizedBox(height: 8),
                          _loadingCategories
                              ? const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<dynamic>(
                                      isExpanded: true,
                                      value: _selectedCategory,
                                      hint: const Text(
                                        'Select',
                                        style: TextStyle(
                                          color: AppColors.inputHint,
                                          fontSize: 14,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.textLight,
                                      ),
                                      items: [
                                        // Existing categories
                                        ..._categories.map(
                                          (cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(
                                              cat.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Add new category option
                                        const DropdownMenuItem(
                                          value: 'add_new',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add,
                                                  color: AppColors.primary,
                                                  size: 18),
                                              SizedBox(width: 6),
                                              Text(
                                                'Add Category',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == 'add_new') {
                                          _addCategoryDialog();
                                        } else {
                                          setState(() =>
                                              _selectedCategory =
                                                  value as CategoryModel);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Color field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(label: 'COLOR'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _colorController,
                            hint: 'e.g. White',
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Required'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Price
                _FieldLabel(label: 'RENTAL PRICE (₱)'),
                const SizedBox(height: 8),
                _InputField(
                  controller: _priceController,
                  hint: 'e.g. 5000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter rental price';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description
                _FieldLabel(label: 'DESCRIPTION'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: const TextStyle(
                        color: AppColors.inputHint, fontSize: 14),
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Measurements
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FieldLabel(label: 'MEASUREMENTS (cm)'),
                    GestureDetector(
                      onTap: _addMeasurementField,
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: AppColors.primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Add Field',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Measurement fields grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: _measurements.length,
                  itemBuilder: (context, index) {
                    final m = _measurements[index];
                    return TextFormField(
                      controller:
                          m['controller'] as TextEditingController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: m['label'] as String,
                        labelStyle: const TextStyle(
                            fontSize: 12, color: AppColors.textLight),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Image Picker
                _FieldLabel(label: 'GOWN IMAGES'),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Existing selected images
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              entry.value,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Add image button
                    if (_selectedImages.length < 5)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: AppColors.textLight, size: 28),
                              SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // Cancel + Save buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Gown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable field label
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: 0.8,
      ),
    );
  }
}

// Reusable input field
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.inputHint, fontSize: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.inputHint, size: 20)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}