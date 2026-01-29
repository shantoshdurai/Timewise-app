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

  List<DropdownMenuItem<String>> departmentItems = [];
  List<DropdownMenuItem<String>> yearItems = [];
  List<DropdownMenuItem<String>> sectionItems = [];

  bool areYearsLoading = false;
  bool areSectionsLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    print("Fetching departments...");
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('departments').get();
      print("Found ${snapshot.docs.length} departments.");
      final items = snapshot.docs.map((doc) {
        // Assuming each department doc has a 'name' field for display
        final name = (doc.data())['name'] ?? doc.id;
        print("Department: $name (ID: ${doc.id})");
        return DropdownMenuItem(value: doc.id, child: Text(name));
      }).toList();
      setState(() {
        departmentItems = items;
      });
    } catch (e) {
      print("Error fetching departments: $e");
    }
  }

  Future<void> _fetchYears(String departmentId) async {
    setState(() {
      areYearsLoading = true;
      selectedYearId = null;
      selectedSectionId = null;
      yearItems = [];
      sectionItems = [];
    });
    final snapshot = await FirebaseFirestore.instance
        .collection('departments')
        .doc(departmentId)
        .collection('years')
        .get();
    final items = snapshot.docs.map((doc) {
      final name = (doc.data())['name'] ?? doc.id;
      return DropdownMenuItem(value: doc.id, child: Text(name));
    }).toList();
    setState(() {
      yearItems = items;
      areYearsLoading = false;
    });
  }

  Future<void> _fetchSections(String departmentId, String yearId) async {
    setState(() {
      areSectionsLoading = true;
      selectedSectionId = null;
      sectionItems = [];
    });
    final snapshot = await FirebaseFirestore.instance
        .collection('departments')
        .doc(departmentId)
        .collection('years')
        .doc(yearId)
        .collection('sections')
        .get();
    final items = snapshot.docs.map((doc) {
      final name = (doc.data())['name'] ?? doc.id;
      return DropdownMenuItem(value: doc.id, child: Text(name));
    }).toList();
    setState(() {
      sectionItems = items;
      areSectionsLoading = false;
    });
  }

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
      // Show error
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
            DropdownButtonFormField<String>(
              value: selectedDepartmentId,
              items: departmentItems,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedDepartmentId = value;
                  });
                  _fetchYears(value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (areYearsLoading) const Center(child: CircularProgressIndicator()),
            if (!areYearsLoading && selectedDepartmentId != null)
              DropdownButtonFormField<String>(
                value: selectedYearId,
                items: yearItems,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedYearId = value;
                    });
                    _fetchSections(selectedDepartmentId!, value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            if (areSectionsLoading) const Center(child: CircularProgressIndicator()),
            if (!areSectionsLoading && selectedYearId != null)
              DropdownButtonFormField<String>(
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
