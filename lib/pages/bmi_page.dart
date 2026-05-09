import 'package:flutter/material.dart';

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {

  final name = TextEditingController();
  final age = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();

  String gender = "Laki-laki";
  double? result;

  void calculate() {
    final h = double.tryParse(height.text);
    final w = double.tryParse(weight.text);

    if (h != null && w != null) {
      setState(() {
        result = w / ((h / 100) * (h / 100));
      });
    }
  }

  Widget input(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Cek BMI")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text("Hitung Indeks Massa Tubuh Anda",
                style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  input("Nama Lengkap", name),
                  input("Usia", age),

                  DropdownButtonFormField(
                    value: gender,
                    items: ["Laki-laki", "Perempuan"]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => gender = v!),
                    decoration: const InputDecoration(labelText: "Jenis Kelamin"),
                  ),

                  const SizedBox(height: 15),

                  input("Tinggi Badan (cm)", height),
                  input("Berat Badan (kg)", weight),

                  ElevatedButton(
                    onPressed: calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Hitung BMI"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (result != null)
              Text("BMI: ${result!.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}