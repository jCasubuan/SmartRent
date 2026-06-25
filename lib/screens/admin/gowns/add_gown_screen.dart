import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/category_model.dart';
import 'package:smart_rent/core/widgets/field_label.dart';
import 'package:smart_rent/core/widgets/gown_form_field.dart';
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
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-]")),
            ],
            decoration: const InputDecoration(
              hintText: 'e.g. Thigh Circumference',
              counterText: '',
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
                if (controller.text.trim().length >= 2) {
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
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-]")),
            ],
            decoration: const InputDecoration(
              hintText: 'e.g. Wedding',
              counterText: '',
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
                final text = controller.text.trim();
                if (text.isEmpty || text.length < 2) return;

                // Check locally first for immediate feedback
                final duplicate = _categories.any((c) =>
                    c.name.trim().toLowerCase() == text.toLowerCase());
                if (duplicate) {
                  Navigator.pop(context);
                  _showSnackbar('Category "$text" already exists');
                  return;
                }

                // Close dialog first
                Navigator.pop(context);

                // Show loading indicator while saving
                setState(() => _loadingCategories = true);

                final newCategory = await CategoryService.addCategory(text);

                if (mounted) {
                  setState(() {
                    _loadingCategories = false;
                    if (newCategory != null) {
                      _categories.add(newCategory);
                      _selectedCategory = newCategory;
                    } else {
                      _showSnackbar('Category "$text" already exists');
                    }
                  });
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

  // ── Measurement validation ──────────────────────────────────────────────────

  static const _measurementLimits = <String, (double, double)>{
    'Bust': (50, 200),
    'Waist': (40, 180),
    'Hips': (50, 200),
    'Shoulder Width': (25, 70),
    'Hollow to Hem': (80, 200),
    'Armhole': (15, 60),
    'Sleeve Length': (20, 100),
    'Neck Circumference': (25, 60),
    'Back Width': (25, 60),
    'Height': (100, 220),
  };

  String? _validateMeasurement(String? val, String label) {
    if (val == null || val.trim().isEmpty) return null; // optional field
    final num = double.tryParse(val.trim());
    if (num == null) return 'Invalid';

    final limits = _measurementLimits[label];
    final min = limits?.$1 ?? 1;
    final max = limits?.$2 ?? 300;

    if (num < min) return 'Min ${min.toInt()} cm';
    if (num > max) return 'Max ${max.toInt()} cm';
    return null;
  }

  Future<void> _saveGown() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackbar('Please select a category');
      return;
    }

    // Check for duplicate name
    final duplicateCode = await GownService.checkDuplicateName(
      _nameController.text.trim(),
    );

    if (duplicateCode != null && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Duplicate Name',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Text(
            'A gown named "${_nameController.text.trim()}" already exists ($duplicateCode). Save anyway?',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                    color: AppColors.textMid, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.defaultForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Save Anyway',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (proceed != true) return;
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
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
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
                FieldLabel(label: 'GOWN NAME', isRequired: true),
                const SizedBox(height: 8),
                GownFormField(
                  controller: _nameController,
                  hint: 'Enter gown name',
                  prefixIcon: Icons.checkroom_outlined,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r"[a-zA-Z0-9\s\-']")),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter gown name';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
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
                          FieldLabel(label: 'CATEGORY', isRequired: true),
                          const SizedBox(height: 8),
                          // _loadingCategories
                          //     ? const SizedBox(
                          //         height: 48,
                          //         child: Center(
                          //           child: CircularProgressIndicator(
                          //             strokeWidth: 2,
                          //             color: AppColors.primary,
                          //           ),
                          //         ),
                          //       )
                          //     : 
                              
                              Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<dynamic>(
                                      isExpanded: true,
                                      value: _selectedCategory,
                                      hint: Text(
                                        _loadingCategories ? 'Loading...' : 'Select',
                                        style: const TextStyle(
                                          color: AppColors.inputHint,
                                          fontSize: 14,
                                        ),
                                      ),
                                      icon: _loadingCategories
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: AppColors.textLight,
                                            ),
                                      items: _loadingCategories
                                          ? null
                                          : [
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
                                              const DropdownMenuItem(
                                                value: 'add_new',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.add, color: AppColors.primary, size: 18),
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
                                      onChanged: _loadingCategories
                                          ? null
                                          : (value) {
                                              if (value == 'add_new') {
                                                _addCategoryDialog();
                                              } else {
                                                setState(() =>
                                                    _selectedCategory = value as CategoryModel);
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
                          FieldLabel(label: 'COLOR', isRequired: true),
                          const SizedBox(height: 8),
                          GownFormField(
                            controller: _colorController,
                            hint: 'e.g. White',
                            maxLength: 30,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-Z\s\-]")),
                            ],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Price
                FieldLabel(label: 'RENTAL PRICE (₱)', isRequired: true),
                const SizedBox(height: 8),
                GownFormField(
                  controller: _priceController,
                  hint: 'e.g. 5000',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter rental price';
                    }
                    final price = double.tryParse(val.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    if (price < 100) {
                      return 'Minimum rental price is ₱100';
                    }
                    if (price > 999999) {
                      return 'Maximum rental price is ₱999,999';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description
                FieldLabel(label: 'DESCRIPTION'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 300,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                        RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE00}-\u{FEFF}]', unicode: true)),
                  ],
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: const TextStyle(
                        color: AppColors.inputHint, fontSize: 14),
                    counterText: '',
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
                    FieldLabel(label: 'MEASUREMENTS (cm)'),
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
                    final label = m['label'] as String;
                    return TextFormField(
                      controller:
                          m['controller'] as TextEditingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (val) => _validateMeasurement(val, label),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textDark),
                      decoration: InputDecoration(
                        labelText: label,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.error, width: 1.5),
                        ),
                        errorStyle: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Image Picker
                FieldLabel(label: 'GOWN IMAGES'),
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
                                  color: AppColors.overlayDarker,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: AppColors.defaultForeground, size: 14),
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
                            color: AppColors.surfaceGrey,
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
                          foregroundColor: AppColors.defaultForeground,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.6),
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
                                  color: AppColors.defaultForeground,
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
