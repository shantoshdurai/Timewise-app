import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? selectedDepartmentId;
  String? selectedYearId;
  String? selectedSectionId;

  Future<void> _saveAndContinue() async {
    if (selectedDepartmentId != null &&
        selectedYearId != null &&
        selectedSectionId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('departmentId', selectedDepartmentId!);
      await prefs.setString('yearId', selectedYearId!);
      await prefs.setString('sectionId', selectedSectionId!);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make a selection for all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Department Dropdown
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('departments').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error loading departments');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No departments found');
                }

                final departmentItems = snapshot.data!.docs.map((doc) {
                  final name = (doc.data() as Map<String, dynamic>)['name'] ?? doc.id;
                  return DropdownMenuItem(value: doc.id, child: Text(name));
                }).toList();

                return DropdownButtonFormField<String>(
                  value: selectedDepartmentId,
                  items: departmentItems,
                  onChanged: (value) {
                    setState(() {
                      selectedDepartmentId = value;
                      selectedYearId = null;
                      selectedSectionId = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Year Dropdown
            if (selectedDepartmentId != null)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('departments')
                    .doc(selectedDepartmentId)
                    .collection('years')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading years');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No years found for this department');
                  }

                  final yearItems = snapshot.data!.docs.map((doc) {
                    final name = (doc.data() as Map<String, dynamic>)['name'] ?? doc.id;
                    return DropdownMenuItem(value: doc.id, child: Text(name));
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: selectedYearId,
                    items: yearItems,
                    onChanged: (value) {
                      setState(() {
                        selectedYearId = value;
                        selectedSectionId = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Section Dropdown
            if (selectedDepartmentId != null && selectedYearId != null)
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('departments')
                    .doc(selectedDepartmentId)
                    .collection('years')
                    .doc(selectedYearId)
                    .collection('sections')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading sections');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No sections found');
                  }

                  final sectionItems = snapshot.data!.docs.map((doc) {
                    final name = (doc.data() as Map<String, dynamic>)['name'] ?? doc.id;
                    return DropdownMenuItem(value: doc.id, child: Text(name));
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: selectedSectionId,
                    items: sectionItems,
                    onChanged: (value) {
                      setState(() {
                        selectedSectionId = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAndContinue,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

