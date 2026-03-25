import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GPAPredictorApp());
}

class GPAPredictorApp extends StatelessWidget {
  const GPAPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student GPA Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class PredictionResult {
  final double predictedGpa;

  PredictionResult({required this.predictedGpa});

  // API returns { "predicted_GPA": 3.12 }  ← uppercase GPA
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictedGpa: (json['predicted_GPA'] as num).toDouble(),
    );
  }

  // Derive letter grade locally — no need for an extra API field
  String get letterGrade {
    if (predictedGpa >= 3.7) return 'A';
    if (predictedGpa >= 3.3) return 'A-';
    if (predictedGpa >= 3.0) return 'B+';
    if (predictedGpa >= 2.7) return 'B';
    if (predictedGpa >= 2.3) return 'B-';
    if (predictedGpa >= 2.0) return 'C+';
    if (predictedGpa >= 1.7) return 'C';
    if (predictedGpa >= 1.3) return 'C-';
    if (predictedGpa >= 1.0) return 'D';
    return 'F';
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  static const String _baseUrl =
      'https://mobile-app-regression-analysis-936b.onrender.com';
  static const String _apiUrl =
      'https://mobile-app-regression-analysis-936b.onrender.com/predict';

  final _formKey = GlobalKey<FormState>();

  final _ageCtrl = TextEditingController();
  final _studyTimeCtrl = TextEditingController();
  final _absencesCtrl = TextEditingController();

  int _gender = 0;
  int _ethnicity = 0;
  int _parentalEducation = 2;
  int _parentalSupport = 2;
  int _tutoring = 0;
  int _extracurricular = 0;
  int _sports = 0;
  int _music = 0;
  int _volunteering = 0;

  bool _isLoading = false;
  PredictionResult? _result;
  String? _errorMessage;

  // ── API call ──────────────────────────────────────────────────────────────
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });

    final body = {
      "Age": int.parse(_ageCtrl.text.trim()),
      "Gender": _gender,
      "Ethnicity": _ethnicity,
      "ParentalEducation": _parentalEducation,
      "StudyTimeWeekly": double.parse(_studyTimeCtrl.text.trim()),
      "Absences": int.parse(_absencesCtrl.text.trim()),
      "Tutoring": _tutoring,
      "ParentalSupport": _parentalSupport,
      "Extracurricular": _extracurricular,
      "Sports": _sports,
      "Music": _music,
      "Volunteering": _volunteering,
    };

    try {
      // Wake up Render's free instance before the real call
      try {
        await http
            .get(Uri.parse('$_baseUrl/health'))
            .timeout(const Duration(seconds: 60));
      } catch (_) {} // ignore — we just want the server warm

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60)); // 60s covers cold start

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // ✅ Fixed: fromJson now reads 'predicted_GPA' (uppercase) correctly
        setState(() => _result = PredictionResult.fromJson(json));
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = json['detail'] ?? 'Prediction failed';
        setState(() => _errorMessage = detail.toString());
      }
    } on Exception catch (e) {
      setState(
        () => _errorMessage =
            'Could not reach server. Check your connection.\n$e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Validators ────────────────────────────────────────────────────────────
  String? _validateAge(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < 15 || n > 25) return 'Age must be 15–25';
    return null;
  }

  String? _validateStudyTime(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < 0 || n > 50) return 'Must be 0–50 hrs/week';
    return null;
  }

  String? _validateAbsences(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < 0 || n > 100) return 'Must be 0–100';
    return null;
  }

  Color _gpaColor(double gpa) {
    if (gpa >= 3.5) return const Color(0xFF2E7D32);
    if (gpa >= 2.5) return const Color(0xFFF57F17);
    return const Color(0xFFC62828);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _binaryToggle({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('No')),
            ButtonSegment(value: 1, label: Text('Yes')),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A73E8),
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Student GPA Predictor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFFE8F0FE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Enter student details below to predict their GPA.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionTitle('Demographics'),
                _textField(
                  label: 'Age',
                  controller: _ageCtrl,
                  hint: '15 – 25',
                  keyboardType: TextInputType.number,
                  validator: _validateAge,
                ),
                _dropdownField<int>(
                  label: 'Gender',
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Female')),
                    DropdownMenuItem(value: 1, child: Text('Male')),
                  ],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
                _dropdownField<int>(
                  label: 'Ethnicity',
                  value: _ethnicity,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Group 0')),
                    DropdownMenuItem(value: 1, child: Text('Group 1')),
                    DropdownMenuItem(value: 2, child: Text('Group 2')),
                    DropdownMenuItem(value: 3, child: Text('Group 3')),
                  ],
                  onChanged: (v) => setState(() => _ethnicity = v!),
                ),
                _dropdownField<int>(
                  label: 'Parental Education Level',
                  value: _parentalEducation,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('None')),
                    DropdownMenuItem(value: 1, child: Text('High School')),
                    DropdownMenuItem(value: 2, child: Text('Some College')),
                    DropdownMenuItem(value: 3, child: Text("Bachelor's")),
                    DropdownMenuItem(value: 4, child: Text('Higher')),
                  ],
                  onChanged: (v) => setState(() => _parentalEducation = v!),
                ),

                _sectionTitle('Academic Factors'),
                _textField(
                  label: 'Weekly Study Time (hrs)',
                  controller: _studyTimeCtrl,
                  hint: '0.0 – 50.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateStudyTime,
                ),
                _textField(
                  label: 'Absences',
                  controller: _absencesCtrl,
                  hint: '0 – 100',
                  keyboardType: TextInputType.number,
                  validator: _validateAbsences,
                ),
                _dropdownField<int>(
                  label: 'Parental Support Level',
                  value: _parentalSupport,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('None')),
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Moderate')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                    DropdownMenuItem(value: 4, child: Text('Very High')),
                  ],
                  onChanged: (v) => setState(() => _parentalSupport = v!),
                ),

                _sectionTitle('Activities & Support'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _binaryToggle(
                          label: 'Tutoring',
                          value: _tutoring,
                          onChanged: (v) => setState(() => _tutoring = v),
                        ),
                        const Divider(height: 20),
                        _binaryToggle(
                          label: 'Extracurricular',
                          value: _extracurricular,
                          onChanged: (v) =>
                              setState(() => _extracurricular = v),
                        ),
                        const Divider(height: 20),
                        _binaryToggle(
                          label: 'Sports',
                          value: _sports,
                          onChanged: (v) => setState(() => _sports = v),
                        ),
                        const Divider(height: 20),
                        _binaryToggle(
                          label: 'Music',
                          value: _music,
                          onChanged: (v) => setState(() => _music = v),
                        ),
                        const Divider(height: 20),
                        _binaryToggle(
                          label: 'Volunteering',
                          value: _volunteering,
                          onChanged: (v) => setState(() => _volunteering = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Predict button ────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _predict,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Predict'),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Result display ────────────────────────────────────
                if (_result != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Predicted GPA',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.predictedGpa.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: _gpaColor(_result!.predictedGpa),
                            ),
                          ),
                          // ✅ Fixed: letterGrade is now computed locally
                          Text(
                            'Grade: ${_result!.letterGrade}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _gpaColor(_result!.predictedGpa),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Error display ─────────────────────────────────────
                if (_errorMessage != null)
                  Card(
                    color: const Color(0xFFFFEBEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFC62828),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _studyTimeCtrl.dispose();
    _absencesCtrl.dispose();
    super.dispose();
  }
}
