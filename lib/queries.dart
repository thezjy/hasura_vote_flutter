const readProgrammingLanguages = '''
  query ReadProgrammingLanguages {
    programming_language(order_by: { vote_count: desc }) {
      name
      vote_count
    }
  }
''';
