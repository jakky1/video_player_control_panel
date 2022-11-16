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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  late VideoPlayerController controller;

  @override
  void initState() {   
    super.initState();
   
    //controller = VideoPlayerController.file(File("E:\\test_youtube.mp4"));
    controller = VideoPlayerController.network("https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_30mb.mp4");

    var captionFile = Future.value(SubRipCaptionFile(generateCaptionFileContent()));
    controller.setClosedCaptionFile(captionFile);

    controller.initialize().then((value) {
      if (!kIsWeb) controller.play(); // NOTE: web not allowed auto play without user interaction
      setState(() {});
      if (!controller.value.isInitialized) {
        log("controller.initialize() failed");
      }
    }).catchError((e) {
      log("controller.initialize() error occurs: $e");
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        
        body: JkVideoControlPanel(controller, 
          showClosedCaptionButton: true, 
          showFullscreenButton: true,
          showVolumeButton: true
        ),
      ),
    );
  }
}
