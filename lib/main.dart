import 'package:flutter/material.dart';
import 'package:flutter_graphql/flutter_graphql.dart';
import './mutations.dart' as mutations;
import './queries.dart' as queries;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HttpLink link = HttpLink(
      uri: 'https://hasura-vote.herokuapp.com/v1alpha1/graphql',
    );

    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: InMemoryCache(),
        link: link,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: CacheProvider(
        child: MaterialApp(
          title: 'GraphQL Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.orange,
          ),
          home: MyHomePage(),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasura Vote'),
      ),
      body: Container(
        child: Query(
          options: QueryOptions(
            document: queries.readProgrammingLanguages,
            pollInterval: 4,
            // you can optionally override some http options through the contexts
          ),
          builder: (QueryResult result) {
            if (result.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (result.hasErrors) {
              return Text('\nErrors: \n  ' + result.errors.join(',\n  '));
            }

            // result.data can be either a [List<dynamic>] or a [Map<String, dynamic>]
            final List<dynamic> pls = result.data['programming_language'];

            return ListView.builder(
              itemCount: pls.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> pl = pls[index];
                final String name = pl["name"];
                final int voteCount = pl["vote_count"];

                return Mutation(
                  options: MutationOptions(
                    document: mutations.vote,
                  ),
                  builder: (
                    RunMutation vote,
                    QueryResult voteResult,
                  ) {
                    if (voteResult.data != null && voteResult.data.isNotEmpty) {
                      pl['vote_count'] = pl['vote_count'] + 1;
                    }

                    return ListTile(
                      title: Text('$name - $voteCount'),
                      trailing: Icon(Icons.thumb_up),
                      onTap: () {
                        vote(<String, String>{
                          'name': name,
                        });
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
