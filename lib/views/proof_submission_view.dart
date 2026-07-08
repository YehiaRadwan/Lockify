import 'package:flutter/material.dart';

class ProofSubmissionData {
  const ProofSubmissionData({
    required this.proofType,
    required this.proofDetails,
    required this.estimatedWorkMinutes,
  });

  final String proofType;
  final String proofDetails;
  final int estimatedWorkMinutes;
}

class ProofSubmissionView extends StatefulWidget {
  const ProofSubmissionView({
    required this.predictedUnlockFor,
    required this.onSubmit,
    super.key,
  });

  final int Function(int estimateMinutes) predictedUnlockFor;
  final Future<void> Function(ProofSubmissionData data) onSubmit;

  @override
  State<ProofSubmissionView> createState() => _ProofSubmissionViewState();
}

class _ProofSubmissionViewState extends State<ProofSubmissionView> {
  static const _proofTypes = <String>['Text Proof', 'Photo Upload', 'Document Upload'];

  final TextEditingController _detailsController = TextEditingController();
  String _selectedProofType = _proofTypes.first;
  int _estimateMinutes = 30;
  bool _submitting = false;

  int get _predictedUnlockMinutes => widget.predictedUnlockFor(_estimateMinutes);

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
    });

    await widget.onSubmit(
      ProofSubmissionData(
        proofType: _selectedProofType,
        proofDetails: _detailsController.text,
        estimatedWorkMinutes: _estimateMinutes,
      ),
    );

    if (!mounted) return;

    setState(() {
      _submitting = false;
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proof of Work')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _selectedProofType,
            decoration: const InputDecoration(labelText: 'Proof Type'),
            items: _proofTypes
                .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedProofType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detailsController,
            minLines: 5,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Proof details',
              hintText: 'Add notes or describe your proof submission',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Photo/document support is placeholder-only in this MVP.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Text('Estimated work: $_estimateMinutes min'),
          Slider(
            value: _estimateMinutes.toDouble(),
            min: 5,
            max: 240,
            divisions: 47,
            label: '$_estimateMinutes',
            onChanged: (value) {
              setState(() {
                _estimateMinutes = value.round();
              });
            },
          ),
          Text(
            'Predicted unlock: $_predictedUnlockMinutes min',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Grant Timed Unlock'),
          ),
        ],
      ),
    );
  }
}
