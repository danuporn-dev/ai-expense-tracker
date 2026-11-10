import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: api.user?['name'] ?? '');
  final currentPassword = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  Uint8List? preview = api.avatarBytes;
  XFile? avatar;
  bool busy = false, picking = false, hidden = true;

  @override
  void dispose() {
    name.dispose();
    currentPassword.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> pickPhoto(ImageSource source) async {
    setState(() => picking = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024)
        throw ApiException('รูปโปรไฟล์ต้องมีขนาดไม่เกิน 2 MB');
      if (mounted)
        setState(() {
          avatar = photo;
          preview = bytes;
        });
    } catch (_) {
      if (mounted)
        snack(
          context,
          'เลือกรูปไม่ได้ กรุณาใช้รูปขนาดไม่เกิน 2 MB และอนุญาตการเข้าถึงกล้องหรือรูปภาพ',
          error: true,
        );
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await api.updateProfile(
        name: name.text.trim(),
        avatar: avatar,
        password: password.text,
        currentPassword: currentPassword.text,
      );
      if (!mounted) return;
      password.clear();
      currentPassword.clear();
      confirm.clear();
      setState(() {
        avatar = null;
        preview = api.avatarBytes;
      });
      snack(context, 'บันทึกข้อมูลส่วนตัวแล้ว');
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('แก้ไขข้อมูลส่วนตัว')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Panel(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: softPink, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: softPink,
                            backgroundImage:
                                preview == null ? null : MemoryImage(preview!),
                            child:
                                preview == null
                                    ? const Icon(
                                      Icons.person_outline,
                                      size: 48,
                                      color: primary,
                                    )
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'รูปโปรไฟล์',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed:
                                  busy || picking
                                      ? null
                                      : () => pickPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('เลือกรูป'),
                            ),
                            TextButton.icon(
                              onPressed:
                                  busy || picking
                                      ? null
                                      : () => pickPhoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('ถ่ายรูป'),
                            ),
                          ],
                        ),
                        if (picking) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'ข้อมูลส่วนตัว',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: name,
                          enabled: !busy,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อ',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator:
                              (s) =>
                                  (s ?? '').trim().isEmpty ? 'กรอกชื่อ' : null,
                        ),
                        const SizedBox(height: 8),
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'อีเมล',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          child: Text(
                            '${api.user?['email'] ?? ''}',
                            style: const TextStyle(color: muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'เปลี่ยนรหัสผ่าน',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'เว้นว่างหากไม่ต้องการเปลี่ยนรหัสผ่าน',
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: currentPassword,
                          enabled: !busy,
                          obscureText: hidden,
                          decoration: const InputDecoration(
                            labelText: 'รหัสผ่านปัจจุบัน',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator:
                              (s) =>
                                  password.text.isNotEmpty && (s ?? '').isEmpty
                                      ? 'กรอกรหัสผ่านปัจจุบัน'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: password,
                          enabled: !busy,
                          obscureText: hidden,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่านใหม่',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              tooltip: hidden ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                              onPressed: () => setState(() => hidden = !hidden),
                              icon: Icon(
                                hidden
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator:
                              (s) =>
                                  (s ?? '').isNotEmpty &&
                                          (s!.length < 8 || s.length > 128)
                                      ? 'รหัสผ่านต้องมี 8–128 ตัวอักษร'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: confirm,
                          enabled: !busy,
                          obscureText: hidden,
                          decoration: const InputDecoration(
                            labelText: 'ยืนยันรหัสผ่านใหม่',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator:
                              (s) =>
                                  (s ?? '') != password.text
                                      ? 'รหัสผ่านไม่ตรงกัน'
                                      : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: busy || picking ? null : save,
                    icon:
                        busy
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.save_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(busy ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
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
