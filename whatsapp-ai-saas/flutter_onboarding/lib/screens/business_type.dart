import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/onboarding_controller.dart';
import '../helper/ui_helper/custom_widget.dart';
import '../helper/ui_helper/progress_view.dart';
import '../helper/utils/app_loger.dart';
import '../helper/utils/shared_preference.dart';
import '../api/api.dart';
import '../theme/business_info_theme.dart';

class BusinessTypeScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BusinessTypeScreen({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  final controller = Get.find<OnboardingController>();
  final _selectedType = ''.obs;
  final _isLoading = false.obs;

  final _descriptionController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingSelection();
  }

  Future<void> _loadExistingSelection() async {
    final tid = await StoreUserData().getTenantId();
    await controller.fetchOnboardingData(tid);
    final data = controller.data;
    if (data != null && data.businessType != null) {
      _selectedType(data.businessType ?? '');
      _descriptionController.text = data.businessDescription ?? '';
      _customTypeController.text = data.customBusinessType ?? '';
      _categoryController.text = data.businessCategory ?? '';
    }
  }

  Future<void> _submit() async {
    // --- VALIDATION 1: Business type must be selected ---
    if (_selectedType.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a business type',
        backgroundColor: Colors.red[100], // background color
        colorText: Colors.black, // text color
        borderColor: Colors.red[500], // border color
        borderWidth: 1.5, // border width
      );
      return;
    }

    // --- VALIDATION 2: For "Other", mandatory fields must be filled ---
    if (_selectedType.value == 'other') {
      if (_customTypeController.text.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter your Business Type',
          backgroundColor: Colors.red[100], // background color
          colorText: Colors.black, // text color
          borderColor: Colors.red[500], // border color
          borderWidth: 1, // border width
        );
        return;
      }
      if (_categoryController.text.trim().isEmpty) {
        Get.snackbar('Error', 'Please enter your Business Category');
        return;
      }
    }

    try {
      _isLoading(true);
      final tid = await StoreUserData().getTenantId();

      final result = await controller.submitBusinessType(
        tenantId: tid,
        businessType: _selectedType.value,
        description: _descriptionController.text.trim(),
        customBusinessType: _customTypeController.text.trim(),
        businessCategory: _categoryController.text.trim(),
      );

      if (result['status'] == 'success') {
        Get.snackbar('Success', 'Business type saved');
        widget.onNext();
      } else {
        Get.snackbar(
          'Error',
          result['detail'] ?? 'Failed to save business type',
          backgroundColor: Colors.red[100], // background color
          colorText: Colors.black, // text color
          borderColor: Colors.red[500], // border color
          borderWidth: 1, // border width
        );
      }
    } catch (e) {
      AppLogger.log('Error: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red[100], // background color
        colorText: Colors.black, // text color
        borderColor: Colors.red[500], // border color
        borderWidth: 1, // border width
      );
    } finally {
      _isLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      {'key': 'products', 'label': 'Products'},
      {'key': 'services', 'label': 'Services'},
      {'key': 'professional', 'label': 'Professional'},
      {'key': 'other', 'label': 'Other'},
    ];

    final theme = Theme.of(context).extension<BusinessInfoTheme>() ??
        BusinessInfoTheme.light;

    return Obx(() => WillPopScope(
          onWillPop: () async {
            widget.onBack();
            return false;
          },
          child: Stack(
            children: [
              Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: theme.borderRadius,
                              ),
                              child: Icon(
                                Icons.category,
                                color: Colors.blue[700],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Select Business Type",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Choose the category that best describes your business",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: types.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, index) {
                            final item = types[index];
                            final selected = _selectedType.value == item['key'];
                            return GestureDetector(
                              onTap: () {
                                _selectedType(item['key']!);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: selected
                                      ? Colors.blue[100]!
                                      : Colors.grey.shade200,
                                  border: Border.all(
                                    color: selected
                                        ? Colors.blue[700]!
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    item['label']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        if (_selectedType.value.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedType.value == 'other') ...[
                                const SizedBox(height: 20),
                                // Business Type
                                CustomWidgets.buildTextField2(
                                  context: context,
                                  controller: _customTypeController,
                                  label: "Business Type *",
                                  hint: "Enter your business type",
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.words,
                                  maxLength: 100,
                                ),

                                SizedBox(height: 20),
                                CustomWidgets.buildTextField2(
                                  context: context,
                                  controller: _categoryController,
                                  label: "Business Category *",
                                  hint: "Enter business category",
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.words,
                                  maxLength: 100,
                                ),
                              ],

                              SizedBox(height: 20),
                              //Others
                              CustomWidgets.buildTextField2(
                                  context: context,
                                  controller: _descriptionController,
                                  label: "Description",
                                  hint: "Describe your business...",
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.words,
                                  maxLength: 100,
                                  maxLines: 3),
                              SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: CustomWidgets.buildGradientButton(
                                  context: context,
                                  onPressed: _isLoading.value ? null : _submit,
                                  text: "Submit & Continue",
                                  isLoading: _isLoading.value,
                                  icon: Icons.save,
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading.value) CustomProgressView(progressText: 'Loading'),
            ],
          ),
        ));
  }
}
