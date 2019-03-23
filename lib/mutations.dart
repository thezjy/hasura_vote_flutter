const vote = '''
  mutation Vote(\$name: String!) {
    update_programming_language(
      _inc: { vote_count: 1 }
      where: { name: { _eq: \$name } }
    ) {
{
        vote_count
      }
    }
  }
''';
