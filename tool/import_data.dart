import 'dart:convert';
import 'dart:io'; // <--- ADD THIS LINE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Your JSON data with ALL classes for ALL days
const jsonData = '''
{
  "classes": [
    { "section": "24AIDSA1", "day": "Monday", "startTime": "08:30", "endTime": "09:20", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "701" },
    { "section": "24AIDSA1", "day": "Monday", "startTime": "09:20", "endTime": "10:10", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Dr.P.Thangavel", "room": "701" },
    { "section": "24AIDSA1", "day": "Monday", "startTime": "10:10", "endTime": "11:00", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.Jeeva", "room": "701" },
    { "section": "24AIDSA1", "day": "Monday", "startTime": "11:15", "endTime": "12:05", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "701" },
    { "section": "24AIDSA1", "day": "Monday", "startTime": "02:15", "endTime": "03:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "701" },
    { "section": "24AIDSA1", "day": "Tuesday", "startTime": "08:30", "endTime": "09:20", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "701" },
    { "section": "24AIDSA1", "day": "Tuesday", "startTime": "09:20", "endTime": "10:10", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Dr.M.Santhosh", "room": "701" },
    { "section": "24AIDSA1", "day": "Tuesday", "startTime": "10:10", "endTime": "11:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "701" },
    { "section": "24AIDSA1", "day": "Tuesday", "startTime": "11:15", "endTime": "12:05", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.Keerthanasri", "room": "701" },
    { "section": "24AIDSA1", "day": "Tuesday", "startTime": "12:05", "endTime": "12:55", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. Sharad Porwal", "room": "701" },
    { "section": "24AIDSA1", "day": "Wednesday", "startTime": "09:20", "endTime": "10:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "701" },
    { "section": "24AIDSA1", "day": "Wednesday", "startTime": "10:10", "endTime": "11:00", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Dr.P.Thangavel", "room": "701" },
    { "section": "24AIDSA1", "day": "Wednesday", "startTime": "11:15", "endTime": "12:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.Jeeva", "room": "701" },
    { "section": "24AIDSA1", "day": "Wednesday", "startTime": "12:05", "endTime": "12:55", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "701" },
    { "section": "24AIDSA1", "day": "Thursday", "startTime": "08:30", "endTime": "09:20", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.Jeeva", "room": "701" },
    { "section": "24AIDSA1", "day": "Thursday", "startTime": "09:20", "endTime": "10:10", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Dr.P.Thangavel", "room": "701" },
    { "section": "24AIDSA1", "day": "Thursday", "startTime": "10:10", "endTime": "11:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Dr.M.Santhosh", "room": "701" },
    { "section": "24AIDSA1", "day": "Thursday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "701" },
    { "section": "24AIDSA1", "day": "Thursday", "startTime": "12:05", "endTime": "12:55", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "701" },
    { "section": "24AIDSA1", "day": "Friday", "startTime": "08:30", "endTime": "09:20", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "701" },
    { "section": "24AIDSA1", "day": "Friday", "startTime": "09:20", "endTime": "10:10", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.Keerthanasri", "room": "701" },
    { "section": "24AIDSA1", "day": "Friday", "startTime": "10:10", "endTime": "11:00", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. Sharad Porwal", "room": "701" },
    { "section": "24AIDSA1", "day": "Friday", "startTime": "11:15", "endTime": "12:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "701" },
    { "section": "24AIDSA1", "day": "Friday", "startTime": "12:05", "endTime": "12:55", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Dr.M.Santhosh", "room": "701" },
    { "section": "24AIDSA2", "day": "Monday", "startTime": "08:30", "endTime": "09:20", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "702" },
    { "section": "24AIDSA2", "day": "Monday", "startTime": "09:20", "endTime": "10:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "702" },
    { "section": "24AIDSA2", "day": "Monday", "startTime": "10:10", "endTime": "11:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.M.Kowsalya", "room": "702" },
    { "section": "24AIDSA2", "day": "Monday", "startTime": "11:15", "endTime": "12:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "702" },
    { "section": "24AIDSA2", "day": "Monday", "startTime": "12:05", "endTime": "12:55", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.K.Jeeva", "room": "702" },
    { "section": "24AIDSA2", "day": "Tuesday", "startTime": "08:30", "endTime": "09:20", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.K.Jeeva", "room": "702" },
    { "section": "24AIDSA2", "day": "Tuesday", "startTime": "09:20", "endTime": "10:10", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Mr.P. Karthick Kannan", "room": "702" },
    { "section": "24AIDSA2", "day": "Tuesday", "startTime": "10:10", "endTime": "11:00", "subject": "Design Thinking", "code": "24CSE303", "mentor": "NF7", "room": "702" },
    { "section": "24AIDSA2", "day": "Tuesday", "startTime": "11:15", "endTime": "12:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "702" },
    { "section": "24AIDSA2", "day": "Tuesday", "startTime": "12:05", "endTime": "12:55", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "702" },
    { "section": "24AIDSA2", "day": "Tuesday", "startTime": "04:10", "endTime": "05:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "702" },
    { "section": "24AIDSA2", "day": "Wednesday", "startTime": "09:20", "endTime": "10:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "702" },
    { "section": "24AIDSA2", "day": "Wednesday", "startTime": "10:10", "endTime": "11:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.M.Kowsalya", "room": "702" },
    { "section": "24AIDSA2", "day": "Wednesday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "702" },
    { "section": "24AIDSA2", "day": "Wednesday", "startTime": "12:05", "endTime": "12:55", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "702" },
    { "section": "24AIDSA2", "day": "Thursday", "startTime": "08:30", "endTime": "09:20", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "702" },
    { "section": "24AIDSA2", "day": "Thursday", "startTime": "09:20", "endTime": "10:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "702" },
    { "section": "24AIDSA2", "day": "Thursday", "startTime": "10:10", "endTime": "11:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "702" },
    { "section": "24AIDSA2", "day": "Thursday", "startTime": "11:15", "endTime": "12:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.K.Jeeva", "room": "702" },
    { "section": "24AIDSA2", "day": "Thursday", "startTime": "12:05", "endTime": "12:55", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "702" },
    { "section": "24AIDSA2", "day": "Friday", "startTime": "09:20", "endTime": "10:10", "subject": "Design Thinking", "code": "24CSE303", "mentor": "NF7", "room": "702" },
    { "section": "24AIDSA2", "day": "Friday", "startTime": "10:10", "endTime": "11:00", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.Jeraldine Ruby", "room": "702" },
    { "section": "24AIDSA2", "day": "Friday", "startTime": "11:15", "endTime": "12:05", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.M.Kowsalya", "room": "702" },
    { "section": "24AIDSA2", "day": "Friday", "startTime": "12:05", "endTime": "12:55", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Mr.P. Karthick Kannan", "room": "702" },
    { "section": "24AIDSA3", "day": "Monday", "startTime": "08:30", "endTime": "09:20", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Dr.A.Justin Diraviam", "room": "703" },
    { "section": "24AIDSA3", "day": "Monday", "startTime": "09:20", "endTime": "10:10", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.R.Elancheran", "room": "703" },
    { "section": "24AIDSA3", "day": "Monday", "startTime": "10:10", "endTime": "11:00", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "703" },
    { "section": "24AIDSA3", "day": "Monday", "startTime": "11:15", "endTime": "12:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "703" },
    { "section": "24AIDSA3", "day": "Monday", "startTime": "12:05", "endTime": "12:55", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs. R.Priyadharshini", "room": "703" },
    { "section": "24AIDSA3", "day": "Tuesday", "startTime": "08:30", "endTime": "09:20", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "703" },
    { "section": "24AIDSA3", "day": "Tuesday", "startTime": "09:20", "endTime": "10:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs. R.Priyadharshini", "room": "703" },
    { "section": "24AIDSA3", "day": "Tuesday", "startTime": "10:10", "endTime": "11:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.M.Kowsalya", "room": "703" },
    { "section": "24AIDSA3", "day": "Tuesday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "703" },
    { "section": "24AIDSA3", "day": "Tuesday", "startTime": "12:05", "endTime": "12:55", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.K.Kalpana", "room": "703" },
    { "section": "24AIDSA3", "day": "Wednesday", "startTime": "09:20", "endTime": "10:10", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Dr.A.Justin Diraviam", "room": "703" },
    { "section": "24AIDSA3", "day": "Wednesday", "startTime": "10:10", "endTime": "11:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.K.Kalpana", "room": "703" },
    { "section": "24AIDSA3", "day": "Wednesday", "startTime": "11:15", "endTime": "12:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "703" },
    { "section": "24AIDSA3", "day": "Wednesday", "startTime": "01:25", "endTime": "02:15", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "703" },
    { "section": "24AIDSA3", "day": "Thursday", "startTime": "08:30", "endTime": "09:20", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "703" },
    { "section": "24AIDSA3", "day": "Thursday", "startTime": "09:20", "endTime": "10:10", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "703" },
    { "section": "24AIDSA3", "day": "Thursday", "startTime": "10:10", "endTime": "11:00", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs. R.Priyadharshini", "room": "703" },
    { "section": "24AIDSA3", "day": "Thursday", "startTime": "11:15", "endTime": "12:05", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.M.Kowsalya", "room": "703" },
    { "section": "24AIDSA3", "day": "Thursday", "startTime": "12:05", "endTime": "12:55", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "703" },
    { "section": "24AIDSA3", "day": "Friday", "startTime": "08:30", "endTime": "09:20", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.M.Kowsalya", "room": "703" },
    { "section": "24AIDSA3", "day": "Friday", "startTime": "09:20", "endTime": "10:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.J.Manivannan", "room": "703" },
    { "section": "24AIDSA3", "day": "Friday", "startTime": "10:10", "endTime": "11:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.K.Kalpana", "room": "703" },
    { "section": "24AIDSA3", "day": "Friday", "startTime": "11:15", "endTime": "12:05", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.R.Elancheran", "room": "703" },
    { "section": "24AIDSA3", "day": "Friday", "startTime": "12:05", "endTime": "12:55", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs. R.Priyadharshini", "room": "703" },
    { "section": "24AIDSA4", "day": "Monday", "startTime": "08:30", "endTime": "09:20", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "704" },
    { "section": "24AIDSA4", "day": "Monday", "startTime": "09:20", "endTime": "10:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.N.Subashini", "room": "704" },
    { "section": "24AIDSA4", "day": "Monday", "startTime": "10:10", "endTime": "11:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Mrs.K.Bharathi", "room": "704" },
    { "section": "24AIDSA4", "day": "Monday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.Keerthanasri", "room": "704" },
    { "section": "24AIDSA4", "day": "Monday", "startTime": "12:05", "endTime": "12:55", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.Kalpana", "room": "704" },
    { "section": "24AIDSA4", "day": "Tuesday", "startTime": "08:30", "endTime": "09:20", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.Keerthanasri", "room": "704" },
    { "section": "24AIDSA4", "day": "Tuesday", "startTime": "09:20", "endTime": "10:10", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.K.Rajalakshmi", "room": "704" },
    { "section": "24AIDSA4", "day": "Tuesday", "startTime": "10:10", "endTime": "11:00", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.N.Subashini", "room": "704" },
    { "section": "24AIDSA4", "day": "Tuesday", "startTime": "11:15", "endTime": "12:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "704" },
    { "section": "24AIDSA4", "day": "Tuesday", "startTime": "12:05", "endTime": "12:55", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.N.Radha", "room": "704" },
    { "section": "24AIDSA4", "day": "Wednesday", "startTime": "09:20", "endTime": "10:10", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "704" },
    { "section": "24AIDSA4", "day": "Wednesday", "startTime": "10:10", "endTime": "11:00", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "704" },
    { "section": "24AIDSA4", "day": "Wednesday", "startTime": "11:15", "endTime": "12:05", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Mrs.K.Bharathi", "room": "704" },
    { "section": "24AIDSA4", "day": "Thursday", "startTime": "08:30", "endTime": "09:20", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Mrs.K.Bharathi", "room": "704" },
    { "section": "24AIDSA4", "day": "Thursday", "startTime": "09:20", "endTime": "10:10", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "704" },
    { "section": "24AIDSA4", "day": "Thursday", "startTime": "10:10", "endTime": "11:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.Kalpana", "room": "704" },
    { "section": "24AIDSA4", "day": "Thursday", "startTime": "11:15", "endTime": "12:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.N.Subashini", "room": "704" },
    { "section": "24AIDSA4", "day": "Thursday", "startTime": "12:05", "endTime": "12:55", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "704" },
    { "section": "24AIDSA4", "day": "Thursday", "startTime": "02:15", "endTime": "03:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.Keerthanasri", "room": "704" },
    { "section": "24AIDSA4", "day": "Friday", "startTime": "08:30", "endTime": "09:20", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.K.Rajalakshmi", "room": "704" },
    { "section": "24AIDSA4", "day": "Friday", "startTime": "09:20", "endTime": "10:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mrs.N.Subashini", "room": "704" },
    { "section": "24AIDSA4", "day": "Friday", "startTime": "10:10", "endTime": "11:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.Keerthanasri", "room": "704" },
    { "section": "24AIDSA4", "day": "Friday", "startTime": "11:15", "endTime": "12:05", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.N.Radha", "room": "704" },
    { "section": "24AIDSA4", "day": "Friday", "startTime": "12:05", "endTime": "12:55", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.Kalpana", "room": "704" },
    { "section": "24AIDSA5", "day": "Monday", "startTime": "08:30", "endTime": "09:20", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSA5", "day": "Monday", "startTime": "09:20", "endTime": "10:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "705" },
    { "section": "24AIDSA5", "day": "Monday", "startTime": "10:10", "endTime": "11:00", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. C. Bhaskar", "room": "705" },
    { "section": "24AIDSA5", "day": "Monday", "startTime": "11:15", "endTime": "12:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "705" },
    { "section": "24AIDSA5", "day": "Monday", "startTime": "12:05", "endTime": "12:55", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Dr.R.Abinaya", "room": "705" },
    { "section": "24AIDSA5", "day": "Tuesday", "startTime": "08:30", "endTime": "09:20", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "705" },
    { "section": "24AIDSA5", "day": "Tuesday", "startTime": "09:20", "endTime": "10:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Dr.R.Abinaya", "room": "705" },
    { "section": "24AIDSA5", "day": "Tuesday", "startTime": "10:10", "endTime": "11:00", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.J.Anitha", "room": "705" },
    { "section": "24AIDSA5", "day": "Tuesday", "startTime": "11:15", "endTime": "12:05", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Mr.V.Vikram", "room": "705" },
    { "section": "24AIDSA5", "day": "Tuesday", "startTime": "12:05", "endTime": "12:55", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "705" },
    { "section": "24AIDSA5", "day": "Wednesday", "startTime": "08:30", "endTime": "09:20", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "705" },
    { "section": "24AIDSA5", "day": "Wednesday", "startTime": "09:20", "endTime": "10:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSA5", "day": "Wednesday", "startTime": "10:10", "endTime": "11:00", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "705" },
    { "section": "24AIDSA5", "day": "Wednesday", "startTime": "12:05", "endTime": "12:55", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. C. Bhaskar", "room": "705" },
    { "section": "24AIDSA5", "day": "Thursday", "startTime": "08:30", "endTime": "09:20", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "705" },
    { "section": "24AIDSA5", "day": "Thursday", "startTime": "10:10", "endTime": "11:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Mr.V.Vikram", "room": "705" },
    { "section": "24AIDSA5", "day": "Thursday", "startTime": "11:15", "endTime": "12:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Dr.R.Abinaya", "room": "705" },
    { "section": "24AIDSA5", "day": "Thursday", "startTime": "12:05", "endTime": "12:55", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSA5", "day": "Friday", "startTime": "08:30", "endTime": "09:20", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Dr.R.Abinaya", "room": "705" },
    { "section": "24AIDSA5", "day": "Friday", "startTime": "09:20", "endTime": "10:10", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Mr.V.Vikram", "room": "705" },
    { "section": "24AIDSA5", "day": "Friday", "startTime": "10:10", "endTime": "11:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "705" },
    { "section": "24AIDSA5", "day": "Friday", "startTime": "11:15", "endTime": "12:05", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.J.Anitha", "room": "705" },
    { "section": "24AIDSA5", "day": "Friday", "startTime": "12:05", "endTime": "12:55", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "705" },
    { "section": "24AIDSA5", "day": "Friday", "startTime": "01:25", "endTime": "02:15", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSB1", "day": "Monday", "startTime": "01:25", "endTime": "02:15", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "701" },
    { "section": "24AIDSB1", "day": "Monday", "startTime": "02:15", "endTime": "03:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "701" },
    { "section": "24AIDSB1", "day": "Monday", "startTime": "03:20", "endTime": "04:10", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "701" },
    { "section": "24AIDSB1", "day": "Monday", "startTime": "04:10", "endTime": "05:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "701" },
    { "section": "24AIDSB1", "day": "Tuesday", "startTime": "01:25", "endTime": "02:15", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "701" },
    { "section": "24AIDSB1", "day": "Tuesday", "startTime": "02:15", "endTime": "03:05", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "701" },
    { "section": "24AIDSB1", "day": "Tuesday", "startTime": "03:20", "endTime": "04:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "701" },
    { "section": "24AIDSB1", "day": "Tuesday", "startTime": "04:10", "endTime": "05:00", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "701" },
    { "section": "24AIDSB1", "day": "Tuesday", "startTime": "05:00", "endTime": "05:50", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Mr.A.Azhaguvel", "room": "701" },
    { "section": "24AIDSB1", "day": "Wednesday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "701" },
    { "section": "24AIDSB1", "day": "Wednesday", "startTime": "01:25", "endTime": "02:15", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "701" },
    { "section": "24AIDSB1", "day": "Wednesday", "startTime": "02:15", "endTime": "03:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "701" },
    { "section": "24AIDSB1", "day": "Wednesday", "startTime": "03:20", "endTime": "04:10", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.J.Anitha", "room": "701" },
    { "section": "24AIDSB1", "day": "Wednesday", "startTime": "04:10", "endTime": "05:00", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "701" },
    { "section": "24AIDSB1", "day": "Thursday", "startTime": "01:25", "endTime": "02:15", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "701" },
    { "section": "24AIDSB1", "day": "Thursday", "startTime": "02:15", "endTime": "03:05", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "701" },
    { "section": "24AIDSB1", "day": "Thursday", "startTime": "03:20", "endTime": "04:10", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "701" },
    { "section": "24AIDSB1", "day": "Thursday", "startTime": "04:10", "endTime": "05:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "701" },
    { "section": "24AIDSB1", "day": "Thursday", "startTime": "05:00", "endTime": "05:50", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "701" },
    { "section": "24AIDSB1", "day": "Friday", "startTime": "01:25", "endTime": "02:15", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "701" },
    { "section": "24AIDSB1", "day": "Friday", "startTime": "02:15", "endTime": "03:05", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.J.Anitha", "room": "701" },
    { "section": "24AIDSB1", "day": "Friday", "startTime": "03:20", "endTime": "04:10", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Mr.A.Azhaguvel", "room": "701" },
    { "section": "24AIDSB1", "day": "Friday", "startTime": "04:10", "endTime": "05:00", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "701" },
    { "section": "24AIDSB1", "day": "Friday", "startTime": "05:00", "endTime": "05:50", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "701" },
    { "section": "24AIDSB2", "day": "Monday", "startTime": "01:25", "endTime": "02:15", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Mr.B. Shanawaz Baig", "room": "702" },
    { "section": "24AIDSB2", "day": "Monday", "startTime": "02:15", "endTime": "03:05", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "702" },
    { "section": "24AIDSB2", "day": "Monday", "startTime": "03:20", "endTime": "04:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs. Keerthanasri", "room": "702" },
    { "section": "24AIDSB2", "day": "Monday", "startTime": "04:10", "endTime": "05:00", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.K.Jeeva", "room": "702" },
    { "section": "24AIDSB2", "day": "Monday", "startTime": "05:00", "endTime": "05:50", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 2", "room": "702" },
    { "section": "24AIDSB2", "day": "Tuesday", "startTime": "01:25", "endTime": "02:15", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "702" },
    { "section": "24AIDSB2", "day": "Tuesday", "startTime": "02:15", "endTime": "03:05", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.A.Krishnamoorthy", "room": "702" },
    { "section": "24AIDSB2", "day": "Tuesday", "startTime": "03:20", "endTime": "04:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 2", "room": "702" },
    { "section": "24AIDSB2", "day": "Tuesday", "startTime": "04:10", "endTime": "05:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs. Keerthanasri", "room": "702" },
    { "section": "24AIDSB2", "day": "Tuesday", "startTime": "05:00", "endTime": "05:50", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mr.V.V.Sabeer", "room": "702" },
    { "section": "24AIDSB2", "day": "Wednesday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs. Keerthanasri", "room": "702" },
    { "section": "24AIDSB2", "day": "Wednesday", "startTime": "01:25", "endTime": "02:15", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mr.V.V.Sabeer", "room": "702" },
    { "section": "24AIDSB2", "day": "Wednesday", "startTime": "02:15", "endTime": "03:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.K.Jeeva", "room": "702" },
    { "section": "24AIDSB2", "day": "Wednesday", "startTime": "03:20", "endTime": "04:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "702" },
    { "section": "24AIDSB2", "day": "Wednesday", "startTime": "04:10", "endTime": "05:00", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Mr.B. Shanawaz Baig", "room": "702" },
    { "section": "24AIDSB2", "day": "Thursday", "startTime": "01:25", "endTime": "02:15", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "702" },
    { "section": "24AIDSB2", "day": "Thursday", "startTime": "02:15", "endTime": "03:05", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.S.Anitha", "room": "702" },
    { "section": "24AIDSB2", "day": "Thursday", "startTime": "03:20", "endTime": "04:10", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.A.Krishnamoorthy", "room": "702" },
    { "section": "24AIDSB2", "day": "Thursday", "startTime": "04:10", "endTime": "05:00", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 2", "room": "702" },
    { "section": "24AIDSB2", "day": "Thursday", "startTime": "05:00", "endTime": "05:50", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Mr.B. Shanawaz Baig", "room": "702" },
    { "section": "24AIDSB2", "day": "Friday", "startTime": "01:25", "endTime": "02:15", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 2", "room": "702" },
    { "section": "24AIDSB2", "day": "Friday", "startTime": "02:15", "endTime": "03:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs. Keerthanasri", "room": "702" },
    { "section": "24AIDSB2", "day": "Friday", "startTime": "03:20", "endTime": "04:10", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mr.K.Jeeva", "room": "702" },
    { "section": "24AIDSB2", "day": "Friday", "startTime": "04:10", "endTime": "05:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "702" },
    { "section": "24AIDSB3", "day": "Monday", "startTime": "01:25", "endTime": "02:15", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "703" },
    { "section": "24AIDSB3", "day": "Monday", "startTime": "02:15", "endTime": "03:05", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. A. Kalaiyarasi", "room": "703" },
    { "section": "24AIDSB3", "day": "Monday", "startTime": "03:20", "endTime": "04:10", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "703" },
    { "section": "24AIDSB3", "day": "Monday", "startTime": "04:10", "endTime": "05:00", "subject": "Design Thinking", "code": "24CSE303", "mentor": "NF7", "room": "703" },
    { "section": "24AIDSB3", "day": "Tuesday", "startTime": "01:25", "endTime": "02:15", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.K.Kalpana", "room": "703" },
    { "section": "24AIDSB3", "day": "Tuesday", "startTime": "02:15", "endTime": "03:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 3", "room": "703" },
    { "section": "24AIDSB3", "day": "Tuesday", "startTime": "03:20", "endTime": "04:10", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "703" },
    { "section": "24AIDSB3", "day": "Tuesday", "startTime": "04:10", "endTime": "05:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "703" },
    { "section": "24AIDSB3", "day": "Tuesday", "startTime": "05:00", "endTime": "05:50", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.A.Winny", "room": "703" },
    { "section": "24AIDSB3", "day": "Wednesday", "startTime": "01:25", "endTime": "02:15", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 3", "room": "703" },
    { "section": "24AIDSB3", "day": "Wednesday", "startTime": "02:15", "endTime": "03:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "703" },
    { "section": "24AIDSB3", "day": "Wednesday", "startTime": "03:20", "endTime": "04:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.K.Kalpana", "room": "703" },
    { "section": "24AIDSB3", "day": "Wednesday", "startTime": "04:10", "endTime": "05:00", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. A. Kalaiyarasi", "room": "703" },
    { "section": "24AIDSB3", "day": "Thursday", "startTime": "08:30", "endTime": "09:20", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "703" },
    { "section": "24AIDSB3", "day": "Thursday", "startTime": "01:25", "endTime": "02:15", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "703" },
    { "section": "24AIDSB3", "day": "Thursday", "startTime": "02:15", "endTime": "03:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.P.Sudha", "room": "703" },
    { "section": "24AIDSB3", "day": "Thursday", "startTime": "03:20", "endTime": "04:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 3", "room": "703" },
    { "section": "24AIDSB3", "day": "Thursday", "startTime": "04:10", "endTime": "05:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.A.Winny", "room": "703" },
    { "section": "24AIDSB3", "day": "Thursday", "startTime": "05:00", "endTime": "05:50", "subject": "Design Thinking", "code": "24CSE303", "mentor": "NF7", "room": "703" },
    { "section": "24AIDSB3", "day": "Friday", "startTime": "01:25", "endTime": "02:15", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.A.Winny", "room": "703" },
    { "section": "24AIDSB3", "day": "Friday", "startTime": "02:15", "endTime": "03:05", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mrs.K.Kalpana", "room": "703" },
    { "section": "24AIDSB3", "day": "Friday", "startTime": "03:20", "endTime": "04:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.N.Radha", "room": "703" },
    { "section": "24AIDSB3", "day": "Friday", "startTime": "04:10", "endTime": "05:00", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "703" },
    { "section": "24AIDSB3", "day": "Friday", "startTime": "05:00", "endTime": "05:50", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 3", "room": "703" },
    { "section": "24AIDSB4", "day": "Monday", "startTime": "01:25", "endTime": "02:15", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mr.J.Manivannan", "room": "704" },
    { "section": "24AIDSB4", "day": "Monday", "startTime": "02:15", "endTime": "03:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mr. K. Keerthi Raj", "room": "704" },
    { "section": "24AIDSB4", "day": "Monday", "startTime": "03:20", "endTime": "04:10", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "704" },
    { "section": "24AIDSB4", "day": "Monday", "startTime": "04:10", "endTime": "05:00", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "704" },
    { "section": "24AIDSB4", "day": "Monday", "startTime": "05:00", "endTime": "05:50", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "704" },
    { "section": "24AIDSB4", "day": "Tuesday", "startTime": "01:25", "endTime": "02:15", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "704" },
    { "section": "24AIDSB4", "day": "Tuesday", "startTime": "02:15", "endTime": "03:05", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.L.Bhuvana", "room": "704" },
    { "section": "24AIDSB4", "day": "Tuesday", "startTime": "03:20", "endTime": "04:10", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "704" },
    { "section": "24AIDSB4", "day": "Tuesday", "startTime": "04:10", "endTime": "05:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "704" },
    { "section": "24AIDSB4", "day": "Tuesday", "startTime": "05:00", "endTime": "05:50", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mr. K. Keerthi Raj", "room": "704" },
    { "section": "24AIDSB4", "day": "Wednesday", "startTime": "01:25", "endTime": "02:15", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mr. K. Keerthi Raj", "room": "704" },
    { "section": "24AIDSB4", "day": "Wednesday", "startTime": "02:15", "endTime": "03:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "704" },
    { "section": "24AIDSB4", "day": "Wednesday", "startTime": "03:20", "endTime": "04:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "704" },
    { "section": "24AIDSB4", "day": "Wednesday", "startTime": "04:10", "endTime": "05:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "704" },
    { "section": "24AIDSB4", "day": "Wednesday", "startTime": "05:00", "endTime": "05:50", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "704" },
    { "section": "24AIDSB4", "day": "Thursday", "startTime": "11:15", "endTime": "12:05", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "704" },
    { "section": "24AIDSB4", "day": "Thursday", "startTime": "01:25", "endTime": "02:15", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.J.Jane Yazhini", "room": "704" },
    { "section": "24AIDSB4", "day": "Thursday", "startTime": "02:15", "endTime": "03:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "NF5", "room": "704" },
    { "section": "24AIDSB4", "day": "Thursday", "startTime": "03:20", "endTime": "04:10", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr.L.Bhuvana", "room": "704" },
    { "section": "24AIDSB4", "day": "Thursday", "startTime": "04:10", "endTime": "05:00", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mr.J.Manivannan", "room": "704" },
    { "section": "24AIDSB4", "day": "Friday", "startTime": "01:25", "endTime": "02:15", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Dr.V.Ramya", "room": "704" },
    { "section": "24AIDSB4", "day": "Friday", "startTime": "02:15", "endTime": "03:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "704" },
    { "section": "24AIDSB4", "day": "Friday", "startTime": "03:20", "endTime": "04:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "Mr. K. Keerthi Raj", "room": "704" },
    { "section": "24AIDSB4", "day": "Friday", "startTime": "04:10", "endTime": "05:00", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mrs.M.Suguna", "room": "704" },
    { "section": "24AIDSB5", "day": "Monday", "startTime": "08:30", "endTime": "09:20", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSB5", "day": "Monday", "startTime": "09:20", "endTime": "10:10", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "705" },
    { "section": "24AIDSB5", "day": "Monday", "startTime": "10:10", "endTime": "11:00", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mr.V.Vivek", "room": "705" },
    { "section": "24AIDSB5", "day": "Monday", "startTime": "01:25", "endTime": "02:15", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. C. Bhaskar", "room": "705" },
    { "section": "24AIDSB5", "day": "Monday", "startTime": "02:15", "endTime": "03:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "705" },
    { "section": "24AIDSB5", "day": "Monday", "startTime": "03:20", "endTime": "04:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "705" },
    { "section": "24AIDSB5", "day": "Tuesday", "startTime": "01:25", "endTime": "02:15", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSB5", "day": "Tuesday", "startTime": "02:15", "endTime": "03:05", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "705" },
    { "section": "24AIDSB5", "day": "Tuesday", "startTime": "03:20", "endTime": "04:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mr.V.Vivek", "room": "705" },
    { "section": "24AIDSB5", "day": "Tuesday", "startTime": "04:10", "endTime": "05:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.A.Winny", "room": "705" },
    { "section": "24AIDSB5", "day": "Wednesday", "startTime": "01:25", "endTime": "02:15", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "705" },
    { "section": "24AIDSB5", "day": "Wednesday", "startTime": "02:15", "endTime": "03:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "705" },
    { "section": "24AIDSB5", "day": "Wednesday", "startTime": "03:20", "endTime": "04:10", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSB5", "day": "Wednesday", "startTime": "04:10", "endTime": "05:00", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "705" },
    { "section": "24AIDSB5", "day": "Thursday", "startTime": "01:25", "endTime": "02:15", "subject": "Environmental Science", "code": "24MAC003", "mentor": "Dr. C. Bhaskar", "room": "705" },
    { "section": "24AIDSB5", "day": "Thursday", "startTime": "02:15", "endTime": "03:05", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.J.Anitha", "room": "705" },
    { "section": "24AIDSB5", "day": "Thursday", "startTime": "03:20", "endTime": "04:10", "subject": "Discrete Mathematics", "code": "24MAT205", "mentor": "New Faculty 4", "room": "705" },
    { "section": "24AIDSB5", "day": "Thursday", "startTime": "04:10", "endTime": "05:00", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.A.Winny", "room": "705" },
    { "section": "24AIDSB5", "day": "Friday", "startTime": "11:15", "endTime": "12:05", "subject": "Computational Intelligence", "code": "24AID502", "mentor": "Ms.N.Pavithra", "room": "705" },
    { "section": "24AIDSB5", "day": "Friday", "startTime": "12:05", "endTime": "12:55", "subject": "Operating Systems", "code": "24CSE408", "mentor": "Mr.V.V.Sabeer", "room": "705" },
    { "section": "24AIDSB5", "day": "Friday", "startTime": "01:25", "endTime": "02:15", "subject": "Introduction to Computational Biology", "code": "240EC912", "mentor": "Ms.A.Winny", "room": "705" },
    { "section": "24AIDSB5", "day": "Friday", "startTime": "02:15", "endTime": "03:05", "subject": "Design and Analysis of Algorithms", "code": "24CSE407", "mentor": "Mrs.G.Mahalakshmi", "room": "705" },
    { "section": "24AIDSB5", "day": "Friday", "startTime": "03:20", "endTime": "04:10", "subject": "Digital Electronics and Microprocessors", "code": "24ECE305", "mentor": "Mr.V.Vivek", "room": "705" },
    { "section": "24AIDSB5", "day": "Friday", "startTime": "04:10", "endTime": "05:00", "subject": "Design Thinking", "code": "24CSE303", "mentor": "Mrs.J.Anitha", "room": "705" }
  ]
}
''';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print("--- SCRIPT STARTED ---");

  try {
    // IMPORTANT: Manual database clear is required before running this script
    // await clearAllTimetableData(); // Removed to avoid previous clearing issues
    await importAllData(); // Renamed and modified to import all data
    print("--- SCRIPT COMPLETED SUCCESSFULLY ---");
  } catch (e) {
    print('!!!!!!!!!! AN ERROR OCCURRED !!!!!!!!!!');
    print(e);
    print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
  } finally {
    print("--- SCRIPT FINISHED: CLOSING NOW ---");
    // This will force the app to close after the script is done.
    exit(0);
  }
}

// Renamed from importMondayData to reflect importing all provided JSON data
Future<void> importAllData() async {
  final firestore = FirebaseFirestore.instance;
  final Map<String, dynamic> data = jsonDecode(jsonData);
  final List<dynamic> classes = data['classes'];

  int importedCount = 0;

  for (var classData in classes) {
    final sectionName = classData['section'];
    if (sectionName == null) continue;

    // Assuming Department is the first 6 chars (e.g., 24AIDS)
    // and Year is based on your previous input '2024'
    final departmentName = 'School of Engineering and Technology';
    final yearName = '2024'; // Using a fixed year for now

    // Get or create department
    final deptRef = firestore.collection('departments').doc(departmentName.replaceAll(' ', '-').toLowerCase());
    await deptRef.set({'name': departmentName}, SetOptions(merge: true));

    // Get or create year
    final yearRef = deptRef.collection('years').doc(yearName);
    await yearRef.set({'name': yearName}, SetOptions(merge: true));

    // Get or create section
    final sectionRef = yearRef.collection('sections').doc(sectionName);
    await sectionRef.set({'name': sectionName}, SetOptions(merge: true));

    // Add class to schedule
    await sectionRef.collection('schedule').add({
      'subject': classData['subject'],
      'code': classData['code'],
      'mentor': classData['mentor'],
      'room': classData['room'],
      'day': classData['day'],
      'startTime': classData['startTime'],
      'endTime': classData['endTime'],
    });
    importedCount++;
    print("Imported class '${classData['subject']}' for section $sectionName on ${classData['day']}");
  }
  print('--- Finished importing $importedCount classes for all days. ---');
}

// Removed clearAllTimetableData as it was causing issues. Manual clear recommended.
/*
Future<void> clearAllTimetableData() async {
  final firestore = FirebaseFirestore.instance;
  print("--- Starting to clear all timetable data ---");

  final departmentsSnapshot = await firestore.collection('departments').get();

  if (departmentsSnapshot.docs.isEmpty) {
    print("No departments found, nothing to clear.");
    return;
  }

  for (var deptDoc in departmentsSnapshot.docs) {
    print("Processing department: ${deptDoc.id}");
    final yearsSnapshot = await deptDoc.reference.collection('years').get();
    for (var yearDoc in yearsSnapshot.docs) {
      print("  Processing year: ${yearDoc.id}");
      final sectionsSnapshot = await yearDoc.reference.collection('sections').get();
      for (var sectionDoc in sectionsSnapshot.docs) {
        print("    Clearing schedule for section: ${sectionDoc.id}");
        final scheduleSnapshot = await sectionDoc.reference.collection('schedule').get();
        for (var classDoc in scheduleSnapshot.docs) {
          await classDoc.reference.delete();
        }
        print("    Finished clearing schedule for section: ${sectionDoc.id}");
      }
    }
  }

  print("--- Finished clearing all timetable data ---");
}
*/