class LabReport {
  final String id;
  final String patientId;
  final String doctorId;
  final String phcId;
  final String patientName;
  final String testName;
  final String? resultText;
  final String status; // 'pending' or 'completed'
  final DateTime? timestamp;
  final List<Map<String, dynamic>>? tableData;
  final String? linkedRecordId;
  final String? imageUrl;

  LabReport({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.phcId,
    required this.patientName,
    required this.testName,
    this.resultText,
    required this.status,
    this.timestamp,
    this.tableData,
    this.linkedRecordId,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'phcId': phcId,
      'patientName': patientName,
      'testName': testName,
      'resultText': resultText,
      'status': status,
      'timestamp': timestamp?.toIso8601String(),
      'tableData': tableData,
      'linkedRecordId': linkedRecordId,
      'imageUrl': imageUrl,
    };
  }

  factory LabReport.fromMap(Map<String, dynamic> map, String id) {
    return LabReport(
      id: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      phcId: map['phcId'] ?? '',
      patientName: map['patientName'] ?? 'Unknown Patient',
      testName: map['testName'] ?? '',
      resultText: map['resultText'],
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
      tableData: map['tableData'] != null ? List<Map<String, dynamic>>.from(map['tableData']) : null,
      linkedRecordId: map['linkedRecordId'],
      imageUrl: map['imageUrl'],
    );
  }
}
