import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

void main() => runApp(const MyApp());

// Color palette
class C {
  static const bg = Color(0xFFF4F6FB);
  static const primary = Color(0xFF1040A0);
  static const accent = Color(0xFF1565C0);
  static const card = Color(0xFFFFFFFF);
  static const inputFill = Color(0xFFEDF1FA);
  static const label = Color(0xFF3D5580);
  static const muted = Color(0xFF8A97B0);
  static const dark = Color(0xFF1A2140);
  static const divider = Color(0xFFE2E8F4);
  static const green = Color(0xFF1B5E20);
  static const greenBg = Color(0xFFE8F5E9);
  static const amber = Color(0xFFBF360C);
  static const amberBg = Color(0xFFFFF3E0);
  static const red = Color(0xFFB71C1C);
  static const redBg = Color(0xFFFFEBEE);
}

//  App start poiint
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPA Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.primary,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: C.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.red, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: C.red, width: 1.5),
          ),
          errorStyle: const TextStyle(fontSize: 11),
          hintStyle: const TextStyle(color: C.muted, fontSize: 13),
        ),
      ),
      home: const HomePage(),
    );
  }
}

//  Result helper
class _Result {
  final double gpa;
  _Result(this.gpa);

  String get letter {
    if (gpa >= 3.7) return 'A';
    if (gpa >= 3.3) return 'A−';
    if (gpa >= 3.0) return 'B+';
    if (gpa >= 2.7) return 'B';
    if (gpa >= 2.3) return 'B−';
    if (gpa >= 2.0) return 'C+';
    if (gpa >= 1.7) return 'C';
    if (gpa >= 1.3) return 'C−';
    if (gpa >= 1.0) return 'D';
    return 'F';
  }

  String get standing {
    if (gpa >= 3.7) return 'Excellent standing';
    if (gpa >= 3.0) return 'Good standing';
    if (gpa >= 2.0) return 'Satisfactory standing';
    return 'Needs improvement';
  }

  Color get color {
    if (gpa >= 3.5) return C.green;
    if (gpa >= 2.5) return C.amber;
    return C.red;
  }

  Color get bgColor {
    if (gpa >= 3.5) return C.greenBg;
    if (gpa >= 2.5) return C.amberBg;
    return C.redBg;
  }

  double get pct => (gpa / 4.0).clamp(0.0, 1.0);
}

// home screen
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ageCt = TextEditingController();
  final _studyCt = TextEditingController();
  final _absencesCt = TextEditingController();

  int _gender = 1;
  int _ethnicity = 1;
  int _parentalEducation = 3;
  int _parentalSupport = 3;
  int _tutoring = 1;
  int _extracurricular = 1;
  int _sports = 0;
  int _music = 0;
  int _volunteering = 0;

  bool _isLoading = false;
  String _loadMsg = 'Predicting…';
  _Result? _result;
  String? _error;

  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ageCt.dispose();
    _studyCt.dispose();
    _absencesCt.dispose();
    _anim.dispose();
    super.dispose();
  }

  // Predict
  Future<void> predict() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
      _loadMsg = 'Waking up server…';
    });

    final data = {
      "Age": int.parse(_ageCt.text.trim()),
      "Gender": _gender,
      "Ethnicity": _ethnicity,
      "ParentalEducation": _parentalEducation,
      "StudyTimeWeekly": double.parse(_studyCt.text.trim()),
      "Absences": int.parse(_absencesCt.text.trim()),
      "Tutoring": _tutoring,
      "ParentalSupport": _parentalSupport,
      "Extracurricular": _extracurricular,
      "Sports": _sports,
      "Music": _music,
      "Volunteering": _volunteering,
    };

    try {
      setState(() => _loadMsg = 'Running model…');
      final gpa = await ApiService.predictGPA(data);
      setState(() => _result = _Result(gpa));
      _anim.forward(from: 0);
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Validators
  String? _vAge(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < 15 || n > 25) return 'Age must be 15 – 25';
    return null;
  }

  String? _vStudy(String? v) {
    final n = double.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < 0 || n > 50) return 'Must be 0 – 50 hrs/week';
    return null;
  }

  String? _vAbsences(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < 0 || n > 100) return 'Must be 0 – 100';
    return null;
  }

  //  UI helpers
  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 15, color: C.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: C.accent,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: C.divider, thickness: 1)),
      ],
    ),
  );

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: C.label,
        letterSpacing: 0.1,
      ),
    ),
  );

  Widget _textInput({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required TextInputType keyboard,
    required String? Function(String?) validator,
    List<TextInputFormatter>? fmt,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel(label),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        inputFormatters: fmt,
        style: const TextStyle(fontSize: 14, color: C.dark),
        decoration: InputDecoration(hintText: hint),
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChange,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel(label),
      DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChange,
        dropdownColor: C.card,
        style: const TextStyle(fontSize: 14, color: C.dark),
        decoration: const InputDecoration(),
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _toggle(String label, int value, ValueChanged<int> onChange) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: C.dark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _Chip(
              active: value == 1,
              onTap: () => onChange(value == 1 ? 0 : 1),
            ),
          ],
        ),
      );

  // Result card
  Widget _resultCard(_Result r) => FadeTransition(
    opacity: _fade,
    child: Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: r.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'PREDICTED GPA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: r.color.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                r.gpa.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: r.color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '/ 4.0',
                    style: TextStyle(
                      fontSize: 15,
                      color: r.color.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.letter,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: r.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: r.pct,
              minHeight: 7,
              backgroundColor: r.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(r.color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            r.standing,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: r.color,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _errorCard(String msg) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: C.redBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: C.red.withOpacity(0.25), width: 1.2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: C.red, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(color: C.red, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );

  // build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GPA Predictor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter student details to predict academic GPA',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: C.muted),
                ),
                const SizedBox(height: 22),

                //  Demographics inputs
                _sectionHeader('DEMOGRAPHICS', Icons.person_outline),
                _textInput(
                  label: 'Age',
                  ctrl: _ageCt,
                  hint: '15 – 25',
                  keyboard: TextInputType.number,
                  validator: _vAge,
                  fmt: [FilteringTextInputFormatter.digitsOnly],
                ),
                _dropdown<int>(
                  label: 'Gender',
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Female')),
                    DropdownMenuItem(value: 1, child: Text('Male')),
                  ],
                  onChange: (v) => setState(() => _gender = v!),
                ),
                _dropdown<int>(
                  label: 'Ethnicity',
                  value: _ethnicity,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Group 0')),
                    DropdownMenuItem(value: 1, child: Text('Group 1')),
                    DropdownMenuItem(value: 2, child: Text('Group 2')),
                    DropdownMenuItem(value: 3, child: Text('Group 3')),
                  ],
                  onChange: (v) => setState(() => _ethnicity = v!),
                ),
                _dropdown<int>(
                  label: 'Parental Education',
                  value: _parentalEducation,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('None')),
                    DropdownMenuItem(value: 1, child: Text('High School')),
                    DropdownMenuItem(value: 2, child: Text('Some College')),
                    DropdownMenuItem(
                      value: 3,
                      child: Text("Bachelor's Degree"),
                    ),
                    DropdownMenuItem(value: 4, child: Text('Graduate Degree')),
                  ],
                  onChange: (v) => setState(() => _parentalEducation = v!),
                ),

                // Academic inputs
                _sectionHeader('ACADEMIC', Icons.school_outlined),
                _textInput(
                  label: 'Weekly Study Time (hours)',
                  ctrl: _studyCt,
                  hint: '0 – 50',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _vStudy,
                ),
                _textInput(
                  label: 'Number of Absences',
                  ctrl: _absencesCt,
                  hint: '0 – 100',
                  keyboard: TextInputType.number,
                  validator: _vAbsences,
                  fmt: [FilteringTextInputFormatter.digitsOnly],
                ),
                _dropdown<int>(
                  label: 'Parental Support Level',
                  value: _parentalSupport,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('None')),
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Moderate')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                    DropdownMenuItem(value: 4, child: Text('Very High')),
                  ],
                  onChange: (v) => setState(() => _parentalSupport = v!),
                ),

                //  Activities list
                _sectionHeader('ACTIVITIES & SUPPORT', Icons.star_outline),
                Container(
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.divider, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _toggle(
                        'Tutoring',
                        _tutoring,
                        (v) => setState(() => _tutoring = v),
                      ),
                      const Divider(height: 1, color: C.divider),
                      _toggle(
                        'Extracurricular Activities',
                        _extracurricular,
                        (v) => setState(() => _extracurricular = v),
                      ),
                      const Divider(height: 1, color: C.divider),
                      _toggle(
                        'Sports',
                        _sports,
                        (v) => setState(() => _sports = v),
                      ),
                      const Divider(height: 1, color: C.divider),
                      _toggle(
                        'Music',
                        _music,
                        (v) => setState(() => _music = v),
                      ),
                      const Divider(height: 1, color: C.divider),
                      _toggle(
                        'Volunteering',
                        _volunteering,
                        (v) => setState(() => _volunteering = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Predict button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : predict,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: C.primary.withOpacity(0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: C.primary.withOpacity(0.35),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _loadMsg,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Text('Predict GPA'),
                  ),
                ),
                const SizedBox(height: 20),

                if (_result != null) _resultCard(_result!),
                if (_error != null) _errorCard(_error!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 68,
        height: 30,
        decoration: BoxDecoration(
          color: active ? C.primary.withOpacity(0.11) : C.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? C.primary : C.divider, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          active ? 'Yes' : 'No',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? C.primary : C.muted,
          ),
        ),
      ),
    );
  }
}
