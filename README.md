# Getting started with Hasura and Flutter

For those who aren't familiar with Flutter yet, Flutter is an open-source mobile application development framework created by Google, which allows you to build beautiful native apps on iOS and Android from a single codebase. Just like Hasura, Flutter has many great features that improve both developer and user experience. Just take 2 examples: Hot Reload helps you iterate with different designs really fast, without losing the state of your app. Skia (the 2D graphics engine used by Chrome) and all the built-in widgets provide performant, beautiful and customizable UIs.

Hasura and Flutter are a really good match for building 3factor apps. In this tutorial, I will show you how to get started with this powerful duo. We are going to port the voting app in my [last tutorial](https://blog.hasura.io/authentication-and-authorization-using-hasura-and-firebase/) to iOS and Android. The main goal is to show you how to integrate Hasura into Flutter apps, so we are only going to implement the basic voting features.

## Prerequisites

You need to know Hasura and a little bit of Flutter to get started. Since you are reading this article, I assume you are already familiar with Hasura. For Flutter, I recommend going through the [official doc](https://flutter.dev/docs/get-started/install) to learn how to install and build a simple demo app with Flutter.

## First thing first

Create a new flutter project is pretty simple. Just run `flutter create hasura_vote_flutter` and you are good to go. We need to add a GraphQL library first. Believe it or not, this might be the trickiest part of this tutorial. Since Flutter is in its early stages, there isn't a mature library like Apollo or Relay for the web. I picked [flutter-graphql](https://github.com/snowballdigital/flutter-graphql) just because it works for this project. I expect as time goes on a great GraphQL library for Flutter will appear. By the way, all of us can help to make this happen!

Back to the topic. Open `pubspec.yaml` and add the dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^0.1.2

  flutter_graphql: ^1.0.0-rc.3
```

If you are using IDEs recommended by the official doc, the package will be installed automatically. Otherwise, just run `flutter packages get` in the command line.

## Prepare GraphQL documents

No matter which GraphQL library you use, the process is similar. You write some GraphQL documents and the library helps you send them and get some result back. Create two files `queries.dart` and `mutations.dart` in the `lib` folder same as your `main.dart` file. Then copy and paste the two documents from our last tutorial.

`queries.dart`:

```dart
const readProgrammingLanguages = '''
  query ReadProgrammingLanguages {
    programming_language(order_by: { vote_count: desc }) {
      name
      vote_count
    }
  }
''';
```

`mutations.dart`:

```dart
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
```

This might seems a little bit redundant. But as the amazing ecosystem of GraphQL keeps going, I expect more code-sharing between Flutter and Web in the future.

## Hook up the client

The auto-generated `main.dart` includes a simple counter app. Run it to make sure everything works. Then replace it with code below:

```dart
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
      body: Container(),
    );
  }
}
```

![Image of empty screen](https://raw.githubusercontent.com/thezjy/hasura_vote_flutter/master/empty.png)

Much cleaner! Let's focus on the `MyApp` widget first, which initializes our GraphQL client. We don't need authentication in this project, so a simple HttpLink will do. The URI here is the same as in the last tutorial. If you deployed your own version, use your URI instead. We then make `GraphQLProvider` at the top of our widget tree, in order to use the `Query` and `Mutation` widget in the children.

## Add Query

Because Flutter takes inspiration from React to provide a tree-like structure to build UI, the workflow of adding GraphQL data is very similar to that of Apollo React. Just wrap the children with a `Query` widget:

```dart
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

            final List<dynamic> pls = result.data['programming_language'];

            return ListView.builder(
              itemCount: pls.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> pl = pls[index];
                final String name = pl["name"];
                final int voteCount = pl["vote_count"];

                return ListTile(
                  title: Text('$name - $voteCount'),
                  trailing: Icon(Icons.thumb_up),
                  onTap: () {},
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

Nothing surprising here. We hook up the `ReadProgrammingLanguages` query and use that data to build a List. Hit save and you should see the list appear in you developing device. But since we haven't added the `Vote` mutation yet, clicking the list item will do nothing. What's more, because the subscription API of this `flutter-graphql` is not stable yet, we use polling to achieve real-time. Visit the [Web version](https://hasura-vote.now.sh/) and make some change, you should see real-time updates on your Flutter app.

![Image of list](https://raw.githubusercontent.com/thezjy/hasura_vote_flutter/master/list.png)

## Add Mutation

Finally, let's add the `Vote` mutation to make our app fully functional. Change the `return` part of `_MyHomePageState` like this:

```dart
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
```

We use our prepared mutation to vote and update the data manually when the result comes back. At this stage, the app should work correctly. Try playing with it and see the change reflect on both the Flutter app and the Web app.

## Wrapping Up

Good developer tools simplify common tasks but also provide ways to customize when in need. To me, Flutter and Hasura are two of the best examples of this quality. In this tutorial, we build a fairly simple real-time voting app. Utilizing the power of Hasura and Flutter, there really is no limit on what kinds of amazing apps you can build.
