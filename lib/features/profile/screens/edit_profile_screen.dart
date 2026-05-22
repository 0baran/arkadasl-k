import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _schoolController = TextEditingController();
  final _interestsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();

  List<String> _photoUrls = [];
  List<String> _interests = [];
  DateTime? _birthDate;
  String _selectedGender = 'other';
  String _relationshipGoal = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio;
      _jobTitleController.text = user.jobTitle;
      _schoolController.text = user.school;
      _photoUrls = List.from(user.photoUrls);
      _interests = List.from(user.interests);
      _birthDate = user.birthDate;
      _selectedGender = user.gender;
      _relationshipGoal = user.relationshipGoal;
      _interestsController.text = user.interests.join(', ');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _jobTitleController.dispose();
    _schoolController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photoUrls.length >= AppConstants.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'En fazla ${AppConstants.maxPhotos} fotoğraf ekleyebilirsiniz',
          ),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _isLoading = true;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final imageUrl = await _storageService.uploadProfileImage(
          authProvider.currentUser!.id,
          File(image.path),
        );

        setState(() {
          _photoUrls.add(imageUrl);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _addInterest() {
    final text = _interestsController.text.trim();
    if (text.isNotEmpty && !_interests.contains(text)) {
      setState(() {
        _interests.add(text);
        _interestsController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihinizi seçin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final updatedUser = authProvider.currentUser!.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        school: _schoolController.text.trim(),
        relationshipGoal: _relationshipGoal,
        photoUrls: _photoUrls,
        interests: _interests,
        birthDate: _birthDate,
        gender: _selectedGender,
      );

      await authProvider.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section
              const Text(
                'Fotoğraflar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _photoUrls.length) {
                      return _buildAddPhotoButton();
                    }
                    return _buildPhotoItem(_photoUrls[index], index);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: AppStrings.name,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen isminizi girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Bio Field
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: AppConstants.maxBioLength,
                decoration: const InputDecoration(
                  labelText: AppStrings.bio,
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Job Title Field
              TextFormField(
                controller: _jobTitleController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Meslek',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 16),

              // School Field
              TextFormField(
                controller: _schoolController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Okul',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Relationship Goal
              DropdownButtonFormField<String>(
                value: _relationshipGoal.isEmpty ? null : _relationshipGoal,
                decoration: const InputDecoration(
                  labelText: 'İlişki Hedefi',
                  prefixIcon: Icon(Icons.favorite_border),
                ),
                items: const [
                  DropdownMenuItem(value: 'Ciddi İlişki', child: Text('Ciddi İlişki 💍')),
                  DropdownMenuItem(value: 'Yeni Arkadaşlar', child: Text('Yeni Arkadaşlar 🤝')),
                  DropdownMenuItem(value: 'Henüz Emin Değilim', child: Text('Henüz Emin Değilim 🤔')),
                  DropdownMenuItem(value: 'Sadece Eğlence', child: Text('Sadece Eğlence 🥂')),
                ],
                onChanged: (value) {
                  setState(() {
                    _relationshipGoal = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Birth Date
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Doğum Tarihi',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate != null
                        ? AppUtils.formatDate(_birthDate!)
                        : 'Tarih seçin',
                    style: TextStyle(
                      color: _birthDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gender Selection
              const Text('Cinsiyet'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Erkek'),
                      value: 'male',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Kadın'),
                      value: 'female',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Diğer'),
                      value: 'other',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Interests Section
              const Text(
                'İlgi Alanları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interestsController,
                      decoration: const InputDecoration(
                        hintText: 'İlgi alanı ekleyin',
                        suffixIcon: Icon(Icons.add),
                      ),
                      onFieldSubmitted: (_) => _addInterest(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addInterest,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interests
                    .map(
                      (interest) => Chip(
                        label: Text(interest),
                        onDeleted: () => _removeInterest(interest),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: IconButton(
        icon: Icon(Icons.add_photo_alternate, color: Colors.grey.shade600),
        onPressed: _pickImage,
      ),
    );
  }

  Widget _buildPhotoItem(String url, int index) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _photoUrls.removeAt(index);
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
