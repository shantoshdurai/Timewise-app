import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTANT:
// To run this script, you need to have a Firebase project configured.
// This script assumes you have a 'google-services.json' file in your 'android/app' directory.

const jsonData = '''
[
  {
    "section": "24AIDSA1",
    "room": "701",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs.Jeraldine Ruby",
    "day": "Monday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA1",
    "room": "701",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Dr.P.Thangavel",
    "day": "Monday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA1",
    "room": "701",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "Mr.Jeeva",
    "day": "Monday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA1",
    "room": "701",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Dr.V.Ramya",
    "day": "Monday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA1",
    "room": "701",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mrs.N.Radha",
    "day": "Monday",
    "startTime": "02:15",
    "endTime": "03:05"
  },
  {
    "section": "24AIDSA2",
    "room": "702",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Mrs.S.Anitha",
    "day": "Monday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA2",
    "room": "702",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mr.J.Manivannan",
    "day": "Monday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA2",
    "room": "702",
    "subject": "Introduction to Computational Biology",
    "code": "240EC912",
    "mentor": "Ms.M.Kowsalya",
    "day": "Monday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA2",
    "room": "702",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs.Jeraldine Ruby",
    "day": "Monday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA2",
    "room": "702",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "Mr.K.Jeeva",
    "day": "Monday",
    "startTime": "12:05",
    "endTime": "12:55"
  },
  {
    "section": "24AIDSA3",
    "room": "703",
    "subject": "Design Thinking",
    "code": "24CSE303",
    "mentor": "Dr.A.Justin Diraviam",
    "day": "Monday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA3",
    "room": "703",
    "subject": "Environmental Science",
    "code": "24MAC003",
    "mentor": "Dr.R.Elancheran",
    "day": "Monday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA3",
    "room": "703",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.P.Sudha",
    "day": "Monday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA3",
    "room": "703",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "Mrs.G.Mahalakshmi",
    "day": "Monday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA3",
    "room": "703",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs. R.Priyadharshini",
    "day": "Monday",
    "startTime": "12:05",
    "endTime": "12:55"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "NF5",
    "day": "Monday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs.N.Subashini",
    "day": "Monday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Introduction to Computational Biology",
    "code": "240EC912",
    "mentor": "Mrs.K.Bharathi",
    "day": "Monday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mrs.Keerthanasri",
    "day": "Monday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Mrs.Kalpana",
    "day": "Monday",
    "startTime": "12:05",
    "endTime": "12:55"
  },
  {
    "section": "24AIDSA5",
    "room": "705",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mr.V.V.Sabeer",
    "day": "Monday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA5",
    "room": "705",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Mrs.S.Anitha",
    "day": "Monday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA5",
    "room": "705",
    "subject": "Environmental Science",
    "code": "24MAC003",
    "mentor": "Dr. C. Bhaskar",
    "day": "Monday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA5",
    "room": "705",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.P.Sudha",
    "day": "Monday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA5",
    "room": "705",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Dr.R.Abinaya",
    "day": "Monday",
    "startTime": "12:05",
    "endTime": "12:55"
  },
  {
    "section": "24AIDSB1",
    "room": "701",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "New Faculty 4",
    "day": "Monday",
    "startTime": "01:25",
    "endTime": "02:15"
  },
  {
    "section": "24AIDSB1",
    "room": "701",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.N.Pavithra",
    "day": "Monday",
    "startTime": "02:15",
    "endTime": "03:05"
  },
  {
    "section": "24AIDSB1",
    "room": "701",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "Mrs.G.Mahalakshmi",
    "day": "Monday",
    "startTime": "03:20",
    "endTime": "04:10"
  },
  {
    "section": "24AIDSB1",
    "room": "701",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Dr.V.Ramya",
    "day": "Monday",
    "startTime": "04:10",
    "endTime": "05:00"
  },
  {
    "section": "24AIDSB2",
    "room": "702",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Mr.B. Shanawaz Baig",
    "day": "Monday",
    "startTime": "01:25",
    "endTime": "02:15"
  },
  {
    "section": "24AIDSB2",
    "room": "702",
    "subject": "Introduction to Computational Biology",
    "code": "240EC912",
    "mentor": "Ms.J.Jane Yazhini",
    "day": "Monday",
    "startTime": "02:15",
    "endTime": "03:05"
  },
  {
    "section": "24AIDSB2",
    "room": "702",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mrs. Keerthanasri",
    "day": "Monday",
    "startTime": "03:20",
    "endTime": "04:10"
  },
  {
    "section": "24AIDSB2",
    "room": "702",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "Mr.K.Jeeva",
    "day": "Monday",
    "startTime": "04:10",
    "endTime": "05:00"
  },
  {
    "section": "24AIDSB2",
    "room": "702",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "New Faculty 2",
    "day": "Monday",
    "startTime": "05:00",
    "endTime": "05:50"
  },
  {
    "section": "24AIDSB3",
    "room": "703",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.P.Sudha",
    "day": "Monday",
    "startTime": "01:25",
    "endTime": "02:15"
  },
  {
    "section": "24AIDSB3",
    "room": "703",
    "subject": "Environmental Science",
    "code": "24MAC003",
    "mentor": "Dr. A. Kalaiyarasi",
    "day": "Monday",
    "startTime": "02:15",
    "endTime": "03:05"
  },
  {
    "section": "24AIDSB3",
    "room": "703",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "NF5",
    "day": "Monday",
    "startTime": "03:20",
    "endTime": "04:10"
  },
  {
    "section": "24AIDSB3",
    "room": "703",
    "subject": "Design Thinking",
    "code": "24CSE303",
    "mentor": "NF7",
    "day": "Monday",
    "startTime": "04:10",
    "endTime": "05:00"
  },
  {
    "section": "24AIDSB4",
    "room": "704",
    "subject": "Design Thinking",
    "code": "24CSE303",
    "mentor": "Mr.J.Manivannan",
    "day": "Monday",
    "startTime": "01:25",
    "endTime": "02:15"
  },
  {
    "section": "24AIDSB4",
    "room": "704",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mr. K. Keerthi Raj",
    "day": "Monday",
    "startTime": "02:15",
    "endTime": "03:05"
  },
  {
    "section": "24AIDSB4",
    "room": "704",
    "subject": "Introduction to Computational Biology",
    "code": "240EC912",
    "mentor": "Ms.J.Jane Yazhini",
    "day": "Monday",
    "startTime": "03:20",
    "endTime": "04:10"
  },
  {
    "section": "24AIDSB4",
    "room": "704",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.N.Pavithra",
    "day": "Monday",
    "startTime": "04:10",
    "endTime": "05:00"
  },
  {
    "section": "24AIDSB4",
    "room": "704",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Dr.V.Ramya",
    "day": "Monday",
    "startTime": "05:00",
    "endTime": "05:50"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mrs.Keerthanasri",
    "day": "Tuesday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Environmental Science",
    "code": "24MAC003",
    "mentor": "Dr.K.Rajalakshmi",
    "day": "Tuesday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs.N.Subashini",
    "day": "Tuesday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.P.Sudha",
    "day": "Tuesday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Design Thinking",
    "code": "24CSE303",
    "mentor": "Mrs.N.Radha",
    "day": "Tuesday",
    "startTime": "12:05",
    "endTime": "12:55"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "NF5",
    "day": "Wednesday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.P.Sudha",
    "day": "Wednesday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Introduction to Computational Biology",
    "code": "240EC912",
    "mentor": "Mrs.K.Bharathi",
    "day": "Wednesday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Introduction to Computational Biology",
    "code": "240EC912",
    "mentor": "Mrs.K.Bharathi",
    "day": "Thursday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Computational Intelligence",
    "code": "24AID502",
    "mentor": "Ms.P.Sudha",
    "day": "Thursday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Mrs.Kalpana",
    "day": "Thursday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs.N.Subashini",
    "day": "Thursday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Design and Analysis of Algorithms",
    "code": "24CSE407",
    "mentor": "NF5",
    "day": "Thursday",
    "startTime": "12:05",
    "endTime": "12:55"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mrs.Keerthanasri",
    "day": "Thursday",
    "startTime": "01:25",
    "endTime": "02:15"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Environmental Science",
    "code": "24MAC003",
    "mentor": "Dr.K.Rajalakshmi",
    "day": "Friday",
    "startTime": "08:30",
    "endTime": "09:20"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Discrete Mathematics",
    "code": "24MAT205",
    "mentor": "Mrs.N.Subashini",
    "day": "Friday",
    "startTime": "09:20",
    "endTime": "10:10"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Operating Systems",
    "code": "24CSE408",
    "mentor": "Mrs.Keerthanasri",
    "day": "Friday",
    "startTime": "10:10",
    "endTime": "11:00"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Design Thinking",
    "code": "24CSE303",
    "mentor": "Mrs.N.Radha",
    "day": "Friday",
    "startTime": "11:15",
    "endTime": "12:05"
  },
  {
    "section": "24AIDSA4",
    "room": "704",
    "subject": "Digital Electronics and Microprocessors",
    "code": "24ECE305",
    "mentor": "Mrs.Kalpana",
    "day": "Friday",
    "startTime": "12:05",
    "endTime": "12:55"
  }
]
''';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final db = FirebaseFirestore.instance;

  await clearOldData(db);
  await importNewData(db);
}

Future<void> clearOldData(FirebaseFirestore db) async {
  print('Clearing old "schedule" collection...');
  final scheduleSnapshot = await db.collection('schedule').get();
  for (var doc in scheduleSnapshot.docs) {
    await doc.reference.delete();
  }
  print('Finished clearing "schedule" collection.');

  print('Clearing old "announcements" collection...');
  final announcementsSnapshot = await db.collection('announcements').get();
  for (var doc in announcementsSnapshot.docs) {
    await doc.reference.delete();
  }
  print('Finished clearing "announcements" collection.');
}

Future<void> importNewData(FirebaseFirestore db) async {
  print('Starting data import...');
  final List<dynamic> classes = jsonDecode(jsonData);

  const departmentId = 'school-of-eng-tech';
  const departmentName = 'School of Engineering and Technology';
  const yearId = '2nd-year';
  const yearName = '2nd Year';

  // Create department document
  await db.collection('departments').doc(departmentId).set({'name': departmentName});
  // Create year document
  await db.collection('departments').doc(departmentId).collection('years').doc(yearId).set({'name': yearName});

  for (var classData in classes) {
    final sectionId = (classData['section'] as String).toLowerCase();
    final sectionName = (classData['section'] as String).toUpperCase();
    
    // Create section document
    await db.collection('departments').doc(departmentId).collection('years').doc(yearId).collection('sections').doc(sectionId).set({'name': sectionName});

    // The rest of the data, excluding section, will be the class document.
    final dataToUpload = Map<String, dynamic>.from(classData);
    dataToUpload.remove('section');
    
    await db
        .collection('departments')
        .doc(departmentId)
        .collection('years')
        .doc(yearId)
        .collection('sections')
        .doc(sectionId)
        .collection('schedule')
        .add(dataToUpload);
  }
  print('Finished importing ${classes.length} documents.');
}
