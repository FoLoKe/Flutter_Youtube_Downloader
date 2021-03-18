import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:ext_storage/ext_storage.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoLoKe\'s yt downloader',
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
      home: MyHomePage(title: 'FoLoKe\'s YouTube Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String debug = '';

  void getPermission() async {
    print("getPermission");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    print(statuses[Permission.storage]);
  }

  @override
  void initState() {
    getPermission();
    super.initState();
  }

  final myController = TextEditingController();
  Image thumbnail = Image(image: AssetImage('images/yt.jpg'));
  var title = '';
  var id;
  var author = '';
  var len = '';
  var qualityList;

  void getInfo(String text) async {
    try {
      setState(() {
        debug = 'FETCHING INFO';
      });
      var yt = YoutubeExplode();
      var video = await yt.videos.get(myController.text);

      title = video.title;
      id = video.id;
      thumbnail = Image.network(video.thumbnails.highResUrl);
      author = video.author;
      len = video.duration.toString();
      var manifest = await yt.videos.streamsClient.getManifest(id);

      qualityList = toList(manifest.muxed);
      setState(() {
        selectedQuality = manifest.muxed.withHighestBitrate();
      });

      setState(() {
        debug = 'READY TO DOWNLOAD';
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        debug = e.toString();
      });
    }
  }

  List<DropdownMenuItem<MuxedStreamInfo>> toList(Iterable<MuxedStreamInfo> infos) {
    List<DropdownMenuItem<MuxedStreamInfo>> list =  [];
    for(MuxedStreamInfo info in infos) {
      list.add(DropdownMenuItem(value: info, child: Text(info.videoQualityLabel),));
    }
    return list;
  }

  void download() async {
    try {
      setState(() {
        debug = 'FETCHING INFO';
      });
      var yt = YoutubeExplode();
      var video = await yt.videos.get(id);
      var title = video.title;

      if (selectedQuality != null) {
        var qualityLabel = selectedQuality.videoQualityLabel;
        setState(() {
          debug = 'DOWNLOADING $qualityLabel $title)';
        });
        // Get the actual stream
        var stream = yt.videos.streamsClient.get(selectedQuality);

        String path =
        await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_DOWNLOADS);
        print(path);

        // Open a file for writing.
        var file = File('$path/$title-$qualityLabel.mp4');
        var fileStream = file.openWrite();

        // Pipe all the content of the stream into the file.
        await stream.pipe(fileStream);

        // Close the file.
        await fileStream.flush();
        await fileStream.close();
        setState(() {
          debug = title + ' saved to Downloads folder';
        });
        print('done');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  MuxedStreamInfo selectedQuality;

  onChange(MuxedStreamInfo info) {
    setState(() {
      selectedQuality = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Enter yt link here:'),
            Row(children: <Widget>[
              Flexible(child:
                Padding(child: 
                  TextField(controller: myController),
                  padding: EdgeInsets.all(10.0),
                ), flex: 3,
              ),
              Flexible(child:
              ElevatedButton(onPressed: () {
                getInfo(myController.text);
              }, child: Text("Fetch info")),
                flex: 1,
                fit: FlexFit.loose,
              )
            ]
            ),
            Text('$debug'),

            Padding(padding: EdgeInsets.all(10.0), child:
              Row(children: [
                Flexible(child: thumbnail, flex: 1),
                Flexible(child: Padding
                  (child: Column(
                      children: [
                        Text("title: $title", maxLines: 1, overflow: TextOverflow.ellipsis,),
                        Text("author $author",  maxLines: 1, overflow: TextOverflow.ellipsis,),
                        Text("length $len",  maxLines: 1, overflow: TextOverflow.ellipsis,)
                      ], crossAxisAlignment: CrossAxisAlignment.start,
                    ), padding: EdgeInsets.all(5),
                  ), flex: 2
                ),
              ], crossAxisAlignment: CrossAxisAlignment.start,),
            ),

            Padding(child: Row(children: [
              Flexible(child:
                DropdownButton(
                  items: qualityList,
                  value: selectedQuality,
                  onChanged: onChange,
                ),
                flex: 1,
                fit: FlexFit.loose,
              ),
              Flexible(child:
                ElevatedButton(
                    onPressed: () {
                      download();
                    },
                    child: Text("DOWNLOAD")
                ), flex: 1,
              ),
            ], mainAxisAlignment: MainAxisAlignment.center,
            ), padding: EdgeInsets.all(10.0),
            ),
          ],
        ),
      ),
    );
  }
}
