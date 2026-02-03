import 'package:flutter/material.dart';

class SubjectUtils {
  static IconData getSubjectIcon(String? subjectName) {
    if (subjectName == null) return Icons.book;

    final lowerSubject = subjectName.toLowerCase();

    if (lowerSubject.contains('math') ||
        lowerSubject.contains('calculus') ||
        lowerSubject.contains('algebra') ||
        lowerSubject.contains('statistic') ||
        lowerSubject.contains('discrete')) {
      return Icons.calculate_rounded;
    }

    if (lowerSubject.contains('computer') ||
        lowerSubject.contains('programming') ||
        lowerSubject.contains('software') ||
        lowerSubject.contains('data') ||
        lowerSubject.contains('intelligence') ||
        lowerSubject.contains('coding') ||
        lowerSubject.contains('network')) {
      return Icons.computer_rounded;
    }

    if (lowerSubject.contains('english') ||
        lowerSubject.contains('literat') ||
        lowerSubject.contains('writing') ||
        lowerSubject.contains('language') ||
        lowerSubject.contains('communication')) {
      return Icons.translate_rounded;
    }

    if (lowerSubject.contains('physic') || lowerSubject.contains('lab')) {
      return Icons.science_rounded;
    }

    if (lowerSubject.contains('chemist') || lowerSubject.contains('biotech')) {
      return Icons.biotech_rounded;
    }

    if (lowerSubject.contains('biolog') ||
        lowerSubject.contains('science') ||
        lowerSubject.contains('environ') ||
        lowerSubject.contains('eco')) {
      return Icons.eco_rounded;
    }

    if (lowerSubject.contains('histor') ||
        lowerSubject.contains('social') ||
        lowerSubject.contains('geograph') ||
        lowerSubject.contains('politi')) {
      return Icons.public_rounded;
    }

    if (lowerSubject.contains('design') ||
        lowerSubject.contains('art') ||
        lowerSubject.contains('graphic') ||
        lowerSubject.contains('draw')) {
      return Icons.palette_rounded;
    }

    if (lowerSubject.contains('busines') ||
        lowerSubject.contains('manage') ||
        lowerSubject.contains('economy') ||
        lowerSubject.contains('account')) {
      return Icons.business_center_rounded;
    }

    if (lowerSubject.contains('sport') ||
        lowerSubject.contains('pe ') ||
        lowerSubject.contains('gym')) {
      return Icons.sports_basketball_rounded;
    }

    if (lowerSubject.contains('logic') || lowerSubject.contains('think')) {
      return Icons.psychology_rounded;
    }

    return Icons.auto_stories_rounded; // Default book-like icon
  }
}
