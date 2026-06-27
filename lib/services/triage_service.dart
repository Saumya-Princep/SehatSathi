class TriageService {
  static const Map<String, List<String>> _specialtyKeywords = {
    'Cardiologist': ['heart', 'chest', 'palpitation', 'bp', 'blood pressure'],
    'Pediatrician': ['child', 'baby', 'infant', 'kids', 'toddler'],
    'Dermatologist': ['skin', 'rash', 'itch', 'acne', 'pimple', 'hair', 'nail'],
    'General Surgeon': ['surgery', 'operation', 'appendix', 'hernia'],
    'Gynecologist': ['pregnancy', 'period', 'women', 'maternity', 'menstruation', 'pregnant'],
    'Urologist': ['urine', 'kidney', 'bladder', 'urinary'],
    'Orthopedic': ['bone', 'joint', 'fracture', 'knee', 'back', 'muscle', 'sprain', 'pain'],
  };

  static String determineSpecialty(String problemDescription) {
    final lowerDesc = problemDescription.toLowerCase();

    for (final entry in _specialtyKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerDesc.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'General Physician';
  }
}
