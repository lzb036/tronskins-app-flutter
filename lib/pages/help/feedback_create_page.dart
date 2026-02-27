import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';
import 'package:tronskins_app/controllers/help/feedback_controller.dart';
import 'package:tronskins_app/routes/app_routes.dart';

class FeedbackCreatePage extends StatefulWidget {
  const FeedbackCreatePage({super.key});

  @override
  State<FeedbackCreatePage> createState() => _FeedbackCreatePageState();
}

class _FeedbackCreatePageState extends State<FeedbackCreatePage> {
  final FeedbackController controller = Get.isRegistered<FeedbackController>()
      ? Get.find<FeedbackController>()
      : Get.put(FeedbackController());
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  final List<String> _imagePaths = [];
  final List<String> _imageIds = [];

  bool _uploading = false;
  bool _submitting = false;

  String _feedType = '';
  String _ticketId = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _feedType = args['type']?.toString() ?? '';
      _ticketId = args['id']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  bool get _isAddFeedback => _feedType == 'addFeedback';

  Future<void> _pickImage() async {
    if (_uploading || _imagePaths.length >= 1) return;
    setState(() => _uploading = true);
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final id = await controller.uploadImage(
        filePath: file.path,
        isReply: _isAddFeedback,
      );
      if (id != null) {
        setState(() {
          _imagePaths.add(file.path);
          _imageIds.add(id);
        });
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.feedback.message.image_upload_success'.tr,
        );
      } else {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.user.feedback.message.image_upload_failed'.tr,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _imagePaths.length) return;
    setState(() {
      _imagePaths.removeAt(index);
      if (index < _imageIds.length) {
        _imageIds.removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    final context = _contextController.text.trim();
    if (context.isEmpty) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.feedback.message.fill_feedback'.tr,
      );
      return;
    }
    if (!_isAddFeedback && _titleController.text.trim().isEmpty) {
      Get.snackbar(
        'app.system.tips.title'.tr,
        'app.user.feedback.message.fill_feedback'.tr,
      );
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final user = UserStorage.getUserInfo();
      final email = user?.showEmail ?? '';
      final ok = _isAddFeedback
          ? await controller.addReply(
              ticketId: _ticketId,
              context: context,
              ids: _imageIds,
            )
          : await controller.submitFeedback(
              title: _titleController.text.trim(),
              context: context,
              email: email,
              ids: _imageIds,
            );
      if (ok) {
        Get.snackbar(
          'app.system.tips.title'.tr,
          _isAddFeedback
              ? 'app.user.feedback.message.reply_success'.tr
              : 'app.user.feedback.message.submit_success'.tr,
        );
        controller.loadTickets(refresh: true);
        _backToList();
      } else {
        Get.snackbar(
          'app.system.tips.title'.tr,
          'app.system.message.not_open'.tr,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _backToList() {
    var found = false;
    Get.until((route) {
      if (route.settings.name == Routers.FEEDBACK_LIST) {
        found = true;
        return true;
      }
      return false;
    });
    if (!found) {
      Get.offNamed(Routers.FEEDBACK_LIST);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAddFeedback
        ? 'app.user.feedback.additional'.tr
        : 'app.user.feedback.problem'.tr;
    final theme = Theme.of(context);
    final fillColor = theme.colorScheme.surfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isAddFeedback) ...[
                    _buildSectionTitle('app.user.feedback.title'.tr),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _titleController,
                      hint: 'app.user.feedback.title_placeholder'.tr,
                      fillColor: fillColor,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionTitle('app.user.feedback.content'.tr),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _contextController,
                    hint: 'app.user.feedback.problem_placeholder'.tr,
                    fillColor: fillColor,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('app.user.feedback.screenshots'.tr),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ..._imagePaths.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(entry.value),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: -6,
                              top: -6,
                              child: IconButton(
                                onPressed: () => _removeImage(entry.key),
                                icon: const Icon(Icons.cancel, color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      }),
                      if (_imagePaths.length < 1)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              color: fillColor,
                            ),
                            child: _uploading
                                ? const Center(child: CircularProgressIndicator())
                                : Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text('app.user.feedback.submit'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required Color fillColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
