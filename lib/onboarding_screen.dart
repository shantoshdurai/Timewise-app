import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_firebase_test/providers/user_selection_provider.dart';
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
    // In a real app, you might want to fetch the user's last selection
    // from SharedPreferences here to pre-fill the dropdowns.
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
    try {
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
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          areYearsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSections(String departmentId, String yearId) async {
    setState(() {
      areSectionsLoading = true;
      selectedSectionId = null;
      sectionItems = [];
    });
    try {
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
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          areSectionsLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (selectedDepartmentId != null &&
        selectedYearId != null &&
        selectedSectionId != null) {
      
      await Provider.of<UserSelectionProvider>(context, listen: false)
          .saveSelection(
        departmentId: selectedDepartmentId!,
        yearId: selectedYearId!,
        sectionId: selectedSectionId!,
      );

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
    final theme = Theme.of(context);
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to ClassGrid',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your class to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 32),
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
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 16),
            if (selectedDepartmentId != null)
              areYearsLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
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
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            const SizedBox(height: 16),
            if (selectedYearId != null)
              areSectionsLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : DropdownButtonFormField<String>(
                value: selectedSectionId,
                items: sectionItems,
                onChanged: (value) {
                  setState(() {
                    selectedSectionId = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Section'),
              ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: (selectedDepartmentId == null || selectedYearId == null || selectedSectionId == null) ? null : _saveAndContinue,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Class"),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }
}