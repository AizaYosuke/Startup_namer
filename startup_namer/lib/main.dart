import 'dart:async';
import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: RandomWords(storage: FavoriteStorage()),
    );
  }
}

class FavoriteStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/favorite.json');
  }

  Future<List<String>> readFavorite() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();
      String string = contents.substring(1, contents.length - 1);

      return string.split(', ');
    } catch (e) {
      return <String>[];
    }
  }

  Future<File> writeFavorite(Set<String> favorite) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString('$favorite');
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({super.key, required this.storage});

  final FavoriteStorage storage;

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <String>[];
  final _saved = <String>{};
  final _biggerFont = const TextStyle(fontSize: 18);

  @override
  void initState() {
    super.initState();
    widget.storage.readFavorite().then((value) {
      setState(() {
        _saved.addAll(value);
        _suggestions.removeRange(0, _suggestions.length);
        _suggestions.addAll(_saved);
      });
    });
  }

  Future<File> _updateFavorite(bool alreadySaved, int index) {
    setState(() {
      if (alreadySaved) {
        _saved.remove(_suggestions[index]);
      } else {
        _saved.add(_suggestions[index]);
      }
    });

    return widget.storage.writeFavorite(_saved);
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final tiles = _saved.map((pair) {
            return ListTile(
              title: Text(
                pair,
                style: _biggerFont,
              ),
            );
          });
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(
              children: divided,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordPair = WordPair.random().asPascalCase;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return const Divider(); /*2*/

          final index = i ~/ 2; /*3*/
          if (index >= _suggestions.length) {
            final wordPairList = generateWordPairs().take(10);
            final wordsList = <String>[];
            for (var wordPair in wordPairList) {
              wordsList.add(wordPair.asPascalCase);
            }
            _suggestions.addAll(wordsList); /*4*/
          }
          final alreadySaved = _saved.contains(_suggestions[index]);
          return ListTile(
            title: Text(
              _suggestions[index],
              style: _biggerFont,
            ),
            trailing: Icon(
              alreadySaved ? Icons.favorite : Icons.favorite_border,
              color: alreadySaved ? Colors.red : null,
              semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
            ),
            onTap: () {
              _updateFavorite(alreadySaved, index);
            },
          );
        },
      ),
    );
  }
}
