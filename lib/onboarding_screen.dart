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

  bool isInitialLoading = true;
  bool areYearsLoading = false;
  bool areSectionsLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('departments').get();
      final items = snapshot.docs.map((doc) {
        final name = (doc.data())['name'] ?? doc.id;
        return DropdownMenuItem(value: doc.id, child: Text(name));
      }).toList();

      if (mounted) {
        setState(() {
          departmentItems = items;
          isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isInitialLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching departments: $e')),
        );
      }
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
    if(mounted) {
      setState(() {
        yearItems = items;
        areYearsLoading = false;
      });
    }
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
    if(mounted) {
      setState(() {
        sectionItems = items;
        areSectionsLoading = false;
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make a selection for all fields.')),
      );
    }
  }

  Widget _buildBody() {
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: selectedDepartmentId,
            items: departmentItems,
            onChanged: (value) {
              if (value != null) {
                _fetchYears(value);
                setState(() {
                  selectedDepartmentId = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedDepartmentId != null)
            areYearsLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
              value: selectedYearId,
              items: yearItems,
              onChanged: (value) {
                if (value != null) {
                  _fetchSections(selectedDepartmentId!, value);
                  setState(() {
                    selectedYearId = value;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          if (selectedYearId != null)
            areSectionsLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
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
          const Spacer(),
          ElevatedButton(
            onPressed: (selectedDepartmentId == null || selectedYearId == null || selectedSectionId == null) ? null : _saveAndContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Class"),
      ),
      body: _buildBody(),
    );
  }
}