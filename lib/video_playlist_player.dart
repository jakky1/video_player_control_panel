// ignore_for_file: depend_on_referenced_packages
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'video_player_control_panel.dart';


class JkVideoPlaylistPlayer extends StatefulWidget {
  final List<String> playlist;
  final bool isLooping;
  final bool autoplay;
  final Color? bgColor;

  /// set to 'true' if running on AndroidTV / AppleTV
  /// to make buttons layout are the same with desktop
  /// and use D-pad (left/up/right/down) to switch focus between buttons
  final bool isTV;

  const JkVideoPlaylistPlayer({
    super.key,
    required this.playlist,
    this.isLooping = false,
    this.autoplay = true,
    this.isTV = false,
    this.bgColor,
  });

  @override
  State<StatefulWidget> createState() => _JkVideoPlaylistPlayerState();
}

class _JkVideoPlaylistPlayerState extends State<JkVideoPlaylistPlayer> {

  VideoPlayerController? controller;
  int nowPlayIndex = 0;
  bool isFirstPlay = true;

  void playPrevVideo() {
    if (nowPlayIndex <= 0) return;
    playVideo(--nowPlayIndex);
  }

  void playNextVideo() {
    if (nowPlayIndex >= widget.playlist.length - 1) return;
    playVideo(++nowPlayIndex);
  }

  void playVideo(int index) {
    nowPlayIndex = index;
    controller?.dispose();

    var path = widget.playlist[index];
    controller = VideoPlayerController.network(path);

    //var captionFile = Future.value(SubRipCaptionFile(generateCaptionFileContent()));
    //controller!.setClosedCaptionFile(captionFile);

    setState(() {});
    controller!.initialize().then((value) {
      if (!controller!.value.isInitialized) {
        log("controller.initialize() failed");
        return;
      }

      if (!kIsWeb) controller!.play(); // NOTE: web not allowed auto play without user interaction
    }).catchError((e) {
      log("controller.initialize() error occurs: $e");
    });

    if (isFirstPlay) {
      if (widget.autoplay) controller!.play();
      isFirstPlay = false;
    }
  }

  @override
  void initState() {
    super.initState();
    playVideo(0);
  }

  @override
  void didUpdateWidget(JkVideoPlaylistPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JkVideoControlPanel(
      controller!,
      showClosedCaptionButton: true,
      showFullscreenButton: true,
      showVolumeButton: true,
      isTV: widget.isTV,
      bgColor: widget.bgColor,
      onPrevClicked: (nowPlayIndex <= 0) ? null :  () {
        playPrevVideo();
      },
      onNextClicked: (nowPlayIndex + 1 >= widget.playlist.length) ? null : () {
        playNextVideo();
      },
      onPlayEnded: () {
        if (nowPlayIndex + 1 >= widget.playlist.length) {
          // end of playlist
          if (widget.isLooping) {
            if (widget.playlist.length == 1) {
              controller!.seekTo(Duration.zero);
              controller!.play();
            } else {
              playVideo(0);
            }
          }
        } else {
          playNextVideo();
        }
      },
    );
  }
}
