import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
        primarySwatch: Colors.blue,
      ),
      home: mainPage(title: 'Giphy Gif'),
    );
  }
}

Future<List<GiphyJSON>> fetchGif(http.Client client) async {
  final response = await client.get(
      'https://api.giphy.com/v1/gifs/trending?api_key=fztKWf4stguXu9hkFujkKRSov4uyyi65&limit=25&rating=G');
  return compute(parseGif, response.body);
}

List<GiphyJSON>  parseGif(String responseBody) {
  //final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  final parsed = json.decode(responseBody);
  final parsedData = parsed['data'].cast<Map<String, dynamic>>();

  return parsedData.map<GiphyJSON>((json) => GiphyJSON.fromJson(json)).toList();
}

class GiphyJSON {
  final String id;
  final String title;
  final String thumnailImage;

  GiphyJSON({this.id, this.title, this.thumnailImage});
  
 factory GiphyJSON.fromJson(Map<String, dynamic> json) {
    return GiphyJSON(
      id: json['id'],
      title: json['title'],
      thumnailImage: json['images']['preview_webp']['url'],
    );
  }

}

class mainPage extends StatelessWidget {
  final String title;

  mainPage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<GiphyJSON>>(
        future: fetchGif(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? GifList(gif: snapshot.data,)
              : Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class GifList extends StatelessWidget {
  final List<GiphyJSON> gif;

  GifList({Key key, this.gif}) : super(key: key);

  @override
  Widget build(BuildContext context) {
     return GridView.builder(
       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
         crossAxisSpacing: 5,
         mainAxisSpacing: 5
       ),
       itemCount: gif.length,
       itemBuilder: (context, index ){
          return Image.network(gif[index].thumnailImage,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
          );
       },
     );
  }
}
