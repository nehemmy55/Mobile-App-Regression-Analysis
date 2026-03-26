import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://mobile-app-regression-analysis-936b.onrender.com";

  // health to wake Render
  static Future<void> _wakeUp() async {
    try {
      await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 60));
    } catch (_) {}
  }

  // Returns the predicted GPA
  static Future<double> predictGPA(Map<String, dynamic> data) async {
    await _wakeUp();

    final response = await http
        .post(
          Uri.parse("$baseUrl/predict"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(data),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception(
            "Request timed out. The server may be starting up — please try again.",
          ),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return (json["predicted_GPA"] as num).toDouble();
    } else {
      String detail = "Prediction failed (${response.statusCode})";
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json.containsKey("detail")) {
          final d = json["detail"];
          detail = d is List
              ? (d as List).map((e) => e["msg"] ?? e.toString()).join("\n")
              : d.toString();
        }
      } catch (_) {}
      throw Exception(detail);
    }
  }
}
