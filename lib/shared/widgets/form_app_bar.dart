import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

/// App bar das telas de form (Cadastro, Novo Medicamento, etc.) — back × no
/// canto e título centralizado. SKILL §10.2.
class FormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FormAppBar({super.key, required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              InkWell(
                onTap: onClose ?? () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.appSurfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    color: context.appTextPrimary,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.45,
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}
