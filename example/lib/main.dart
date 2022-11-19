// ignore_for_file: depend_on_referenced_packages
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player_control_panel/video_player_control_panel.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win_plugin.dart';
import 'package:sprintf/sprintf.dart';


void main() {
  if (!kIsWeb && Platform.isWindows) WindowsVideoPlayer.registerWith(); // TODO: we need this line before [video_player_win] been added in official [video_player] by "default_package" in its pubspec.yaml
  runApp(const MyApp());
}

String generateCaptionFileContent() {
  final sb = StringBuffer();
  for (int i=1; i<60*20; i++) {
    int minute = i ~/ 60;
    int second = i % 60;
    sb.writeln("$i");
    sb.writeln(sprintf("00:%02d:%02d,000 --> 00:%02d:%02d,900", [minute, second, minute, second]));
    sb.writeln("this is caption $i");
    sb.writeln("2nd line");
    sb.writeln("");
  }
  return sb.toString();
}

final g_playlist = [
  //"E:/test_youtube.mp4",
  "https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_30mb.mp4",    
  "https://freetestdata.com/wp-content/uploads/2022/02/Free_Test_Data_10MB_MOV.mov",
];

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  VideoPlayerController? controller;
  int nowPlayIndex = 0;

  void playPrevVideo() {
    if (nowPlayIndex <= 0) return;
    playVideo(--nowPlayIndex);
  }

  void playNextVideo() {
    if (nowPlayIndex >= g_playlist.length - 1) return;
    playVideo(++nowPlayIndex);
  }

  void playVideo(int index) {
    controller?.dispose();
    
    var path = g_playlist[index];
    controller = VideoPlayerController.network(path);

    var captionFile = Future.value(SubRipCaptionFile(generateCaptionFileContent()));
    controller!.setClosedCaptionFile(captionFile);

    setState(() {});
    controller!.initialize().then((value) {
      if (!controller!.value.isInitialized) {
        log("controller.initialize() failed");
        return;
      }

      controller!.play(); // NOTE: web not allowed auto play without user interaction
    }).catchError((e) {
      log("controller.initialize() error occurs: $e");
    });
  }

  @override
  void initState() {   
    super.initState();  
    playVideo(0);
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget player = JkVideoControlPanel(controller!, 
      showClosedCaptionButton: true, 
      showFullscreenButton: true,
      showVolumeButton: true,
      onPrevClicked: (nowPlayIndex <= 0) ? null :  () {
        playPrevVideo();
      },
      onNextClicked: (nowPlayIndex >= g_playlist.length - 1) ? null : () {
        playNextVideo();
      },
      onPlayEnded: () {
        playNextVideo();
      },
    );

    Widget player2 = JkVideoPlaylistPlayer(
      playlist: g_playlist,
      isLooping: true,
      autoplay: true,
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example app'),
        ),
        
        body: Row(children: [
          Expanded(child: player),
          //Expanded(child: player2),  // unmark this line to show 2 videos
        ]),
      ),
    );
  }
}
