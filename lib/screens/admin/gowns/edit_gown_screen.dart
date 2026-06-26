import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/category_model.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/field_label.dart';
import 'package:smart_rent/core/widgets/gown_form_field.dart';
import 'package:smart_rent/services/category_service.dart';
import 'package:smart_rent/services/gown_service.dart';

class EditGownScreen extends StatefulWidget {
  final GownModel gown;

  const EditGownScreen({super.key, required this.gown});

  @override
  State<EditGownScreen> createState() => _EditGownScreenState();
}

class _EditGownScreenState extends State<EditGownScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — pre-filled from existing gown
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  // Category
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _loadingCategories = true;

  // Status — preserved from current gown, no longer editable via UI
  late String _selectedStatus;

  // Measurements — pre-filled from existing gown, admin can add more
  late final List<Map<String, dynamic>> _measurements;

  // Images
  // Existing Cloudinary URLs the admin wants to keep
  late List<String> _retainedImageUrls;
  // Newly picked local images
  final List<File> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final gown = widget.gown;

    _nameController = TextEditingController(text: gown.name);
    _colorController = TextEditingController(text: gown.color);
    _priceController =
        TextEditingController(text: gown.rentalPrice.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: gown.description);

    _selectedStatus = gown.status;
    _retainedImageUrls = List<String>.from(gown.imageUrls);

    // Build measurement fields from existing data, preserve order
    // Default labels we always show
    final defaultLabels = [
      'Bust',
      'Waist',
      'Hips',
      'Shoulder Width',
      'Hollow to Hem',
      'Armhole',
      'Sleeve Length',
      'Neck Circumference',
      'Back Width',
      'Height',
    ];

    _measurements = [];

    // Add default labels first, pre-filled if they exist
    for (final label in defaultLabels) {
      _measurements.add({
        'label': label,
        'controller': TextEditingController(
          text: gown.measurements[label] ?? '',
        ),
      });
    }

    // Add any extra measurement keys not in the default list
    for (final entry in gown.measurements.entries) {
      if (!defaultLabels.contains(entry.key)) {
        _measurements.add({
          'label': entry.key,
          'controller': TextEditingController(text: entry.value),
        });
      }
    }

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

        // Match existing category by name
        try {
          _selectedCategory = _categories.firstWhere(
            (c) => c.name == widget.gown.category,
          );
        } catch (_) {
          _selectedCategory = null;
        }
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      PermissionStatus status;

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }

        if (status.isPermanentlyDenied) {
          _showPermissionDialog();
          return;
        }

        if (!status.isGranted) return;
      }

      final totalImages = _retainedImageUrls.length + _newImages.length;
      final remaining = 5 - totalImages;
      if (remaining <= 0) return;

      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty && mounted) {
        setState(() {
          for (final img in picked) {
            if (_retainedImageUrls.length + _newImages.length < 5) {
              _newImages.add(File(img.path));
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

  // Remove an existing Cloudinary image from the retained list
  void _removeRetainedImage(int index) {
    setState(() => _retainedImageUrls.removeAt(index));
  }

  // Remove a newly picked local image
  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

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

                Navigator.pop(context);
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnackbar('Please select a category');
      return;
    }

    // Check for duplicate name (case-insensitive hard block, excludes self)
    final duplicateCode = await GownService.checkDuplicateName(
      _nameController.text.trim(),
      excludeId: widget.gown.id,
    );

    if (duplicateCode != null && mounted) {
      _showSnackbar('A gown named "${_nameController.text.trim()}" already exists ($duplicateCode). Please choose a different name.');
      return;
    }

    setState(() => _isSaving = true);

    // Build measurements map — only include non-empty values
    final Map<String, String> measurementsMap = {};
    for (final m in _measurements) {
      final value = (m['controller'] as TextEditingController).text.trim();
      if (value.isNotEmpty) {
        measurementsMap[m['label'] as String] = value;
      }
    }

    final success = await GownService.updateGown(
      gownId: widget.gown.id,
      code: widget.gown.code,
      name: _nameController.text.trim(),
      category: _selectedCategory!.name,
      color: _titleCase(_colorController.text.trim()),
      measurements: measurementsMap,
      rentalPrice: double.tryParse(_priceController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      retainedImageUrls: _retainedImageUrls,
      newImages: _newImages,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _showSnackbar('Gown updated successfully');
        Navigator.pop(context, true); // return true so detail screen knows
      } else {
        _showSnackbar('Failed to update gown. Please try again.');
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

  /// Normalizes a string to Title Case (each word capitalized).
  /// "off-white" → "Off-White", "IVORY" → "Ivory"
  String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input.split(RegExp(r'[\s\-]')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(input.contains('-') ? '-' : ' ');
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final totalImages = _retainedImageUrls.length + _newImages.length;

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
        title: Text(
          'Edit Gown',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(r.s(24), r.s(16), r.s(24), r.s(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Gown Code — read only
                FieldLabel(label: 'GOWN CODE'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    widget.gown.code,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                    final name = val.trim();
                    if (name.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (!RegExp(r'[a-zA-Z].*[a-zA-Z]').hasMatch(name)) {
                      return 'Name must contain at least 2 letters';
                    }
                    if (!RegExp(r'^[a-zA-Z]').hasMatch(name)) {
                      return 'Name must start with a letter';
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
                          Container(
                            height: 48,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<dynamic>(
                                isExpanded: true,
                                value: _selectedCategory,
                                hint: Text(
                                  _loadingCategories
                                      ? 'Loading...'
                                      : 'Select',
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
                                onChanged: _loadingCategories
                                    ? null
                                    : (value) {
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
                              final color = val.trim();
                              if (!RegExp(r'^[a-zA-Z]').hasMatch(color)) {
                                return 'Must start with a letter';
                              }
                              if (color.replaceAll(RegExp(r'[^a-zA-Z]'), '').length < 2) {
                                return 'Must contain at least 2 letters';
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
                          Icon(Icons.add,
                              color: AppColors.primary, size: 16),
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

                // Images
                FieldLabel(label: 'GOWN IMAGES'),
                const SizedBox(height: 4),
                const Text(
                  'Tap × to remove an existing image. New images will be uploaded on save.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Existing Cloudinary images
                    ..._retainedImageUrls.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              entry.value,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: AppColors.surfaceGrey,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeRetainedImage(entry.key),
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

                    // Newly picked local images
                    ..._newImages.asMap().entries.map((entry) {
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
                          // "NEW" label
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.defaultForeground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(entry.key),
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

                    // Add image button — only show if under 5 total
                    if (totalImages < 5)
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
                          side:
                              const BorderSide(color: AppColors.primary),
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
                        onPressed: _isSaving ? null : _saveChanges,
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
                                'Save Changes',
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