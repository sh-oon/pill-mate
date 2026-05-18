import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({super.key, required this.medicationId});

  final int? medicationId;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _remindBefore = 5;
  int _urgentRepeat = 5;
  int _urgentMaxRepeats = 6;

  bool get _isEdit => widget.medicationId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '약 수정' : '약 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  hintText: '예: 종합비타민',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: '용량 (선택)',
                  hintText: '예: 1정 / 500mg',
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: '복용 시간'),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_time.format(context)),
                trailing: const Icon(Icons.edit),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: '알림 설정'),
              _MinutesField(
                label: '복용 시각 N분 전 사전 알림',
                value: _remindBefore,
                onChanged: (v) => setState(() => _remindBefore = v),
                suffix: '분 전',
              ),
              _MinutesField(
                label: '미복용 시 긴급 반복 간격',
                value: _urgentRepeat,
                onChanged: (v) => setState(() => _urgentRepeat = v),
                suffix: '분마다',
              ),
              _MinutesField(
                label: '긴급 알림 최대 반복 횟수',
                value: _urgentMaxRepeats,
                onChanged: (v) => setState(() => _urgentMaxRepeats = v),
                suffix: '회',
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _save,
                child: Text(_isEdit ? '저장' : '등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: DAO 호출로 medications + schedules insert, 알람 예약 트리거.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('등록 로직은 다음 단계에서 구현 예정입니다.')),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _MinutesField extends StatelessWidget {
  const _MinutesField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.suffix,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('$value $suffix'),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
