import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../data/models/store_model.dart';
import '../../data/store_scope.dart';
import '../controllers/store_controller.dart';
import '../widgets/product_form_ui.dart';
import '../widgets/store_form_page.dart';
import '../widgets/store_page_ui.dart';
import 'store_edit_screen.dart';
import 'store_profile_screen.dart' show hhmm;

/// Pengaturan toko: kontak dan jam buka. Status "Buka sekarang" di tab Toko
/// dan di etalase pembeli dihitung server dari jam di sini.
class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _phone = TextEditingController();
  Map<String, DayHours?> _hours = {};
  StoreModel? _original;
  bool _saving = false;
  bool _touched = false;

  bool get _kopdes => ref.read(storeScopeProvider).isKopdes;

  String? _phoneError() =>
      StoreProfileRules.phone(_phone.text, landline: _kopdes);

  /// Jam bawaan saat sebuah hari dinyalakan.
  static const _defaultDay = DayHours('08:00', '17:00');

  @override
  void initState() {
    super.initState();
    ref.listenManual(storeProfileProvider, (_, next) {
      final s = next.valueOrNull;
      if (s == null || _original != null) return;
      setState(() {
        _original = s;
        _phone.text = s.phone;
        _hours = {for (final d in weekDays) d: s.operatingHours?[d]};
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _hoursChanged {
    final o = _original?.operatingHours;
    if (o == null) return _hours.values.any((h) => h != null);
    return weekDays.any((d) => o[d] != _hours[d]);
  }

  bool get _dirty =>
      _original != null &&
      (_phone.text.trim() != _original!.phone || _hoursChanged);

  Future<void> _pickTime(String day, {required bool open}) async {
    final current = _hours[day] ?? _defaultDay;
    final parts = (open ? current.open : current.close).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      helpText: open ? 'JAM BUKA' : 'JAM TUTUP',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final v =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _hours[day] = open
          ? DayHours(v, current.close)
          : DayHours(current.open, v);
    });
  }

  Future<void> _save() async {
    setState(() => _touched = true);
    final phoneError = _phoneError();
    if (phoneError != null || _saving) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      waiting: 'Menyimpan pengaturan…',
      action: () async {
        await saveStoreProfile(
          ref,
          phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          operatingHours: _hoursChanged ? _hours : null,
        );
        return true;
      },
      successTitle: 'Pengaturan Tersimpan',
      successMessage: 'Kontak dan jam buka sudah diperbarui.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storeProfileProvider);
    final phoneError = _touched ? _phoneError() : null;

    return StoreFormPage(
      title: _kopdes ? 'Pengaturan Kopdes' : 'Pengaturan Toko',
      subtitle: 'Kontak dan jam buka',
      dirty: _dirty,
      saving: _saving,
      onSave: _dirty ? _save : null,
      children: [
        if (_original == null)
          async.hasError
              ? SectionError(
                  message: networkErrorMessage(async.error!),
                  onRetry: () => ref.invalidate(storeProfileProvider),
                )
              : const SectionSkeleton(height: 480)
        else ...[
          StoreSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabel('Nomor telepon / WhatsApp', required: true),
                TextField(
                  controller: _phone,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  decoration: productInputDecoration(
                    hint: '0812xxxxxxxx',
                    error: phoneError,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const StoreSectionHeader(
            'Jam buka',
            subtitle: 'Pembeli melihat status Buka atau Tutup dari sini.',
          ),
          StoreSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < weekDays.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.hairlineSoft),
                  _DayRow(
                    day: weekDays[i],
                    hours: _hours[weekDays[i]],
                    onToggle: (open) => setState(
                      () => _hours[weekDays[i]] = open ? _defaultDay : null,
                    ),
                    onPickOpen: () => _pickTime(weekDays[i], open: true),
                    onPickClose: () => _pickTime(weekDays[i], open: false),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final DayHours? hours;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  const _DayRow({
    required this.day,
    required this.hours,
    required this.onToggle,
    required this.onPickOpen,
    required this.onPickClose,
  });

  @override
  Widget build(BuildContext context) {
    final label = weekDayLabels[day]!;
    final h = hours;

    Widget time(String v, VoidCallback onTap, String semantic) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 44),
        backgroundColor: AppColors.surfaceSoft,
        foregroundColor: AppColors.ink,
      ),
      child: Text(hhmm(v), semanticsLabel: '$semantic ${hhmm(v)}'),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        runSpacing: AppSpacing.xs,
        children: [
          // Hari + saklar, dengan kata "Tutup"/"Buka" — bukan saklar saja.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: h != null,
                onChanged: onToggle,
                activeTrackColor: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 72),
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (h == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Tutup',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            // Wrap, bukan Row: pada teks besar di layar 320dp sepasang jam
            // lebih lebar dari barisnya.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                time(h.open, onPickOpen, '$label buka'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('–'),
                ),
                time(h.close, onPickClose, '$label tutup'),
              ],
            ),
        ],
      ),
    );
  }
}
