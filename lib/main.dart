import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
      ),
      home: mainPage(title: 'Giphy'),
    );
  }
}

Future<List<GiphyJSON>> fetchGif(http.Client client) async {
  final response = await client.get(
      'https://api.giphy.com/v1/gifs/trending?api_key=YOUR_KEY&limit=25&rating=G');
  return compute(parseGif, response.body);
}

Future<List<GiphyJSON>> fetchStickerTrending(http.Client client) async {
  final response = await client.get(
      'https://api.giphy.com/v1/stickers/trending?api_key=YOUR_KEY&limit=25&rating=G');
  return compute(parseGif, response.body);
}

Future<List<GiphyJSON>> fetchsearch(searchKey) async {
  final response = await http.get(
      'https://api.giphy.com/v1/gifs/search?api_key=YOUR_KEY&q=$searchKey&limit=25&offset=0&rating=G&lang=en');
  if (response.statusCode == 200) {
    return parseGif(response.body);
  } else {
    throw Exception('Failed to load post');
  }
}

List<GiphyJSON> parseGif(String responseBody) {
  //final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  final parsed = json.decode(responseBody);
  final parsedData = parsed['data'].cast<Map<String, dynamic>>();

  return parsedData.map<GiphyJSON>((json) => GiphyJSON.fromJson(json)).toList();
}

class GiphyJSON {
  final String id;
  final String title;
  final String thumnailImage;
  final String source;

  GiphyJSON({this.id, this.title, this.thumnailImage, this.source});

  factory GiphyJSON.fromJson(Map<String, dynamic> json) {
    return GiphyJSON(
        id: json['id'],
        title: json['title'],
        thumnailImage: json['images']['original']['url'],
        source: json['source_tld']);
  }
}

class mainPage extends StatelessWidget {
  final String title;
  final _SearchDelegate _delegate = _SearchDelegate();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  mainPage({Key key, this.title}) : super(key: key);

  Widget fetchtrending() {
    return FutureBuilder<List<GiphyJSON>>(
      future: fetchGif(http.Client()),
      builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error);

        return snapshot.hasData
            ? GifList(
                gif: snapshot.data,
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget fetchSticker() {
    return FutureBuilder<List<GiphyJSON>>(
      future: fetchStickerTrending(http.Client()),
      builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error);

        return snapshot.hasData
            ? GifList(
                gif: snapshot.data,
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: <Widget>[
              IconButton(
                tooltip: 'Search',
                icon: Icon(Icons.search),
                onPressed: () async {
                  final String selected = await showSearch<String>(
                      context: context, delegate: _delegate);
                },
              )
            ],
            bottom: TabBar(
              // controller: tabControl,
              tabs: <Widget>[
                Tab(text: 'Gif'),
                Tab(text: 'Sticker'),
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[fetchtrending(), fetchSticker()],
          ),
        ));
  }
}

class GifList extends StatelessWidget {
  final List<GiphyJSON> gif;
  final bool isDetail;

  GifList({Key key, this.gif, this.isDetail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 5, mainAxisSpacing: 5),
      itemCount: gif.length,
      itemBuilder: (context, index) {
        /* return Image.network(
          gif[index].thumnailImage,
          width: 150,
          height: 150,
          fit: BoxFit.fill,

        ); */
        return GestureDetector(
          child: CachedNetworkImage(
            imageUrl: gif[index].thumnailImage,
            placeholder: new Center(
              child: new CircularProgressIndicator(),
            ),
            errorWidget: new Icon(Icons.error),
            height: 150,
            width: 150,
            fit: BoxFit.fill,
          ),
          onTap: () {
            print('index sekarang $index');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => detailPage(GifData: gif[index])));
          },
        );
      },
    );
  }
}

class detailPage extends StatelessWidget {
  final GiphyJSON GifData;

  detailPage({Key key, this.GifData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(GifData.title),
      ),
      body: Container(
       
        child: Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.album),
                title: Text(GifData.title),
                subtitle: Text(GifData.source),
              ),
              CachedNetworkImage(
                imageUrl: GifData.thumnailImage,
                placeholder: new Center(
                  child: new CircularProgressIndicator(),
                ),
                errorWidget: new Icon(Icons.error),
                //  height: 150,
                //  width: 200,
                fit: BoxFit.fill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchDelegate extends SearchDelegate<String> {
  List<String> _suggestions = <String>['Cat'];

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (query == null || query == '') {
      return Container(
        padding: new EdgeInsets.only(top: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  text: 'Search gif...', style: theme.textTheme.subhead),
            ),
          ],
        ),
      );
    } else {
      return Container(
          padding: new EdgeInsets.only(top: 16.0), child: searchGif());
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: new EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RichText(
            textAlign: TextAlign.center,
            text:
                TextSpan(text: 'Search gif...', style: theme.textTheme.subhead),
          ),
        ],
      ),
    );
  }

  Widget searchGif() {
    return FutureBuilder<List<GiphyJSON>>(
      future: fetchsearch(query),
      builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error);
        return snapshot.hasData
            ? GifList(
                gif: snapshot.data,
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }
}
