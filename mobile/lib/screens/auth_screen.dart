import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../widgets/wallet_art.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      pass = TextEditingController(),
      confirm = TextEditingController();
  bool register = false, busy = false, hidden = true;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (register) {
        await api.register(name.text.trim(), email.text.trim(), pass.text);
      } else {
        await api.signIn(email.text.trim(), pass.text);
      }
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [softPink, peach],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'A LITTLE CARE FOR YOUR MONEY',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.8,
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const WalletArt(size: 140),
                        const Text(
                          'My Wallet AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: primary,
                            letterSpacing: -.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'ดูแลเงินให้ง่ายขึ้น ทุกวัน',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    register ? 'เริ่มต้นกับบัญชีใหม่' : 'ยินดีต้อนรับกลับมา',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    register
                        ? 'สร้างบัญชี แล้วเริ่มวางแผนการเงินของคุณ'
                        : 'เข้าสู่ระบบเพื่อดูภาพรวมการเงินของคุณ',
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Panel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (register) ...[
                          TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อผู้ใช้',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator:
                                (s) =>
                                    (s ?? '').trim().isEmpty
                                        ? 'กรอกชื่อ'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'อีเมล',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator:
                              (s) =>
                                  (s ?? '').contains('@')
                                      ? null
                                      : 'กรอกอีเมลให้ถูกต้อง',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: pass,
                          obscureText: hidden,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่าน',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
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
                                  (s ?? '').length < 8
                                      ? 'รหัสผ่านอย่างน้อย 8 ตัวอักษร'
                                      : null,
                        ),
                        if (register) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirm,
                            obscureText: hidden,
                            decoration: const InputDecoration(
                              labelText: 'ยืนยันรหัสผ่าน',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            validator:
                                (s) =>
                                    s != pass.text ? 'รหัสผ่านไม่ตรงกัน' : null,
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: busy ? null : submit,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                busy
                                    ? 'กำลังดำเนินการ...'
                                    : register
                                    ? 'สมัครสมาชิก'
                                    : 'เข้าสู่ระบบ',
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              busy
                                  ? null
                                  : () => setState(() => register = !register),
                          child: Text(
                            register
                                ? 'มีบัญชีแล้ว? เข้าสู่ระบบ'
                                : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: muted, size: 14),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'พื้นที่ส่วนตัวสำหรับการเงินของคุณ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    ],
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
