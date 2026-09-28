import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/business_profile.dart';
import '../../../data/models/quote.dart';
import '../../../services/pdf_service.dart';

class TemplatePickerSheet extends StatefulWidget {
  const TemplatePickerSheet({
    super.key,
    required this.currentTemplateId,
    required this.quote,
    required this.profile,
  });

  final String currentTemplateId;
  final Quote quote;
  final BusinessProfile profile;

  @override
  State<TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<TemplatePickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentTemplateId;
  }

  @override
  Widget build(BuildContext context) {
    final free    = kTemplates.where((t) => !t.isPremium).toList();
    final premium = kTemplates.where((t) => t.isPremium).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          Text('Template', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),

          // Scroll area
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(context, 'Gratuits'),
                  const SizedBox(height: 8),
                  ...free.map((t) => _TemplateTile(
                    info: t,
                    isSelected: _selected == t.id,
                    onTap: () => setState(() => _selected = t.id),
                  )),
                  const SizedBox(height: 12),
                  _sectionLabel(context, 'Premium'),
                  const SizedBox(height: 8),
                  ...premium.map((t) => _TemplateTile(
                    info: t,
                    isSelected: _selected == t.id,
                    onTap: () => setState(() => _selected = t.id),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Appliquer'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 0.8),
  );
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  final TemplateInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withAlpha(30) : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_outlined,
              color: isSelected ? AppColors.primary : AppColors.textDark,
              size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(info.name,
                  style: Theme.of(context).textTheme.titleMedium),
                if (info.isPremium) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Premium', style: TextStyle(
                        color: AppColors.white, fontSize: 10,
                        fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(info.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textDark.withAlpha(160))),
            ],
          )),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
        ]),
      ),
    );
  }
}
