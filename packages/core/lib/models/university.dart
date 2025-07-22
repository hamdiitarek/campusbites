class University {
  final String id;
  final String name;
  final String emailDomain;

  const University({
    required this.id,
    required this.name,
    required this.emailDomain,
  });

  @override
  String toString() {
    return name;
  }

  //list of universities with their email domains
  static List<University> get sampleUniversities => [
        const University(
          id: '1',
          name: 'Egypt University of Informatics',
          emailDomain: 'students.eui.edu.eg',
        ),
        const University(
          id: '2',
          name: 'German University in Cairo',
          emailDomain: 'guc.edu.eg',
        ),
      ];
}
