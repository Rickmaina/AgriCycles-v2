import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/constants/kenya_locations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/verification_request_model.dart';
import '../../data/services/auth_service.dart';
import '../../domain/validators.dart';
import '../admin/controllers/admin_controller.dart';

class RegisterVehicleScreen extends ConsumerStatefulWidget {
  const RegisterVehicleScreen({super.key});

  @override
  ConsumerState<RegisterVehicleScreen> createState() =>
      _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState
    extends ConsumerState<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _owner = TextEditingController();
  final _plate = TextEditingController();
  final _makeModel = TextEditingController();
  final _capacity = TextEditingController();
  String? _county;
  bool _submitted = false;

  @override
  void dispose() {
    _owner.dispose();
    _plate.dispose();
    _makeModel.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider);
    final applicant = user?.name ?? 'Transport partner';
    final plate = _plate.text.trim().toUpperCase();

    final request = VerificationRequestModel(
      id: 'vr${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.id ?? 'guest',
      applicantName: applicant,
      type: VerificationType.vehicle,
      documentRef: plate,
      plateNumber: plate,
      extraInfo:
          '${_makeModel.text.trim()}, ${_capacity.text.trim()}t capacity',
      county: _county!,
      submittedAt: DateTime.now(),
    );

    ref.read(adminControllerProvider).submit(request);
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _successScreen();
    return _formScreen();
  }

  Widget _successScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle submitted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Awaiting Admin review',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Admin will verify your logbook via the NTSA portal. You will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => setState(() => _submitted = false),
                child: const Text('Submit another vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Register vehicle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Admin verifies every vehicle manually via the NTSA portal (Motor Vehicle Copy of Records or e-Logbook QR).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _owner,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Registered owner name',
                  ),
                  validator: (v) =>
                      Validators.requiredText(v, label: 'Owner'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Plate number',
                    hintText: 'e.g. KDA 342J',
                  ),
                  validator: Validators.plateNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _makeModel,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Make and model',
                    hintText: 'e.g. Isuzu FRR',
                  ),
                  validator: (v) =>
                      Validators.requiredText(v, label: 'Make and model'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacity (tonnes)',
                    suffixText: 't',
                  ),
                  validator: (v) =>
                      Validators.positiveNumber(v, label: 'Capacity'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _county,
                  decoration: const InputDecoration(
                      labelText: 'Operating county'),
                  items: KenyaLocations.counties
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _county = v),
                  validator: Validators.county,
                ),
                const SizedBox(height: 20),
                const _WarningNote(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit for verification'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningNote extends StatelessWidget {
  const _WarningNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber,
              size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You will need to show the e-Logbook QR code or provide a Copy of Records when Admin requests it.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
