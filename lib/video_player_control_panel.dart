// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:sprintf/sprintf.dart';

import 'package:video_player/video_player.dart';


// ignore: must_be_immutable
class JkVideoControlPanel extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showFullscreenButton; // not shown in web
  final bool showClosedCaptionButton;
  final bool showVolumeButton; // only show in desktop
  late bool _isFullscreen;
  ValueNotifier<bool>? _showClosedCaptions;

  JkVideoControlPanel(this.controller, {
    super.key, 
    this.showFullscreenButton = true,
    this.showClosedCaptionButton = true,
    this.showVolumeButton = true,
    }) : _isFullscreen = false;

  static JkVideoControlPanel _fullscreen(VideoPlayerController controller, {Key? key, required ValueNotifier<bool>? showClosedCaptions, required bool showVolumeButton}) {
    var c = JkVideoControlPanel(controller, key: key, showVolumeButton: showVolumeButton);
    c._isFullscreen = true;
    c._showClosedCaptions = showClosedCaptions;
    return c;
  }
  
  @override
  State<JkVideoControlPanel> createState() => _JkVideoControlPanelState();
}

class _JkVideoControlPanelState extends State<JkVideoControlPanel> with TickerProviderStateMixin {

  final bool isDesktop = kIsWeb || Platform.isWindows;
  final focusNode = FocusScopeNode();

  late final AnimationController panelAnimController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  late final panelAnimation = panelAnimController.drive(Tween<double>(begin: 0.0, end: 1.0));
  late final AnimationController volumeAnimController = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
  late final volumeAnimation = volumeAnimController.drive(Tween<double>(begin: 0.0, end: 1.0));

  final displayPosition = ValueNotifier<int>(0); // position to display for user, when user dragging seek bar, this value changed by user dragging, not changed by player's position

  final duration = ValueNotifier<Duration>(Duration.zero);
  final playing = ValueNotifier<bool>(false);
  final buffering = ValueNotifier<bool>(false);
  final volumeValue = ValueNotifier<double>(1.0);
  
  final hasClosedCaptionFile = ValueNotifier<bool>(false);
  late final ValueNotifier<bool> showClosedCaptions;
  final currentCaption = ValueNotifier<String>("");
  
  bool isMouseMode = false;
  bool isFullScreen = false;
  final mouseVisibility = ValueNotifier<bool>(true);
  
  bool isDraggingVolumeBar = false;
  bool isMouseInVolumeBar = false;

  void onPlayerValueChanged() { 
    final playerValue = widget.controller.value;

    duration.value = playerValue.duration;
    playing.value = playerValue.isPlaying;
    buffering.value = playerValue.isBuffering;
    displayPosition.value = playerValue.position.inMilliseconds;
    volumeValue.value = playerValue.volume;

    hasClosedCaptionFile.value = widget.controller.closedCaptionFile != null;
    currentCaption.value = playerValue.caption.text;
  }

  double volumeBeforeMute = 1.0;
  void toggleVolumeMute() {
    if (volumeValue.value > 0) {
      volumeBeforeMute = math.max(volumeValue.value, 0.3);
      widget.controller.setVolume(0);
    } else {
      widget.controller.setVolume(volumeBeforeMute);
    }
  }

  void doClickFullScreenButton() {
    if (!widget._isFullscreen) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) {
          return Material(child: JkVideoControlPanel._fullscreen(widget.controller, key: widget.key, showClosedCaptions: showClosedCaptions, showVolumeButton: widget.showVolumeButton));
        },
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
    FullScreenWindow.setFullScreen(!widget._isFullscreen);
  }

  double iconSize = 10;
  double textSize = 5;
  void evaluateTextIconSize() async {
    var size = await FullScreenWindow.getScreenSize(context);
    double min = math.min(size.width, size.height);
    if (kIsWeb || Platform.isWindows) {
      iconSize = min / 30;
    } else { // android / iOS
      iconSize = min / 15;
    }

    textSize = iconSize * 0.55; 
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    showClosedCaptions = widget._showClosedCaptions ?? ValueNotifier<bool>(true);
    widget.controller.addListener(onPlayerValueChanged);
    evaluateTextIconSize();
    onPlayerValueChanged();
  }

  @override
  void didUpdateWidget(JkVideoControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onPlayerValueChanged);
      widget.controller.addListener(onPlayerValueChanged);
      setState(() {});
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    widget.controller.removeListener(onPlayerValueChanged);
    panelAnimController.dispose();
    volumeAnimController.dispose();
    super.dispose();
  }

  String duration2TimeStr(Duration duration) {
    if (widget.controller.value.duration.inHours > 0) {
      return sprintf("%02d:%02d:%02d", [duration.inHours, duration.inMinutes % 60, duration.inSeconds % 60]);
    } 
    return sprintf("%02d:%02d", [duration.inMinutes % 60, duration.inSeconds % 60]);
  }

  Timer? _showPanelTimer;
  void showPanel() {
    mouseVisibility.value = true;
    panelAnimController.forward();
    _showPanelTimer?.cancel();
    _showPanelTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (isMouseInVolumeBar || isDraggingVolumeBar) return;
      if (!playing.value) return; //don't auto hide when paused
      mouseVisibility.value = false;
      panelAnimController.reverse();
    });
  }

  bool isPanelShown() => panelAnimController.value > 0;
  void togglePanel() {
    if (isPanelShown()) {
      _showPanelTimer?.cancel();
      panelAnimController.reverse();
    } else {
      showPanel();
    }
  }

  void togglePlayPause() {
    if (!widget.controller.value.isInitialized) return;
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void incrementalSeek(int ms) async {
    showPanel();
    int dst = displayPosition.value + ms;
    if (dst < 0) {
      dst = 0;
    } else if (dst >= widget.controller.value.duration.inMilliseconds) {
      return;
    }

    displayPosition.value = dst;
    await widget.controller.seekTo(Duration(milliseconds: displayPosition.value));
  }

  Widget createPlayPauseButton(bool isCircle, double size) {
    return ValueListenableBuilder<bool>(
      valueListenable: playing,
      builder: (context, value, child) {
        return IconButton(
          iconSize: size,
          icon: Icon(
            isCircle ? (value ? Icons.pause_circle : Icons.play_circle)
                     : (value ? Icons.pause : Icons.play_arrow),
            color: Colors.white
          ),
          onPressed: () {
            if (isMouseMode) {
              togglePlayPause();
            } else {
              if (isPanelShown()) {
                togglePlayPause();
                showPanel();
              } else {
                togglePanel();
              }
            }
          },
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget durationText = ValueListenableBuilder<Duration>(
      valueListenable: duration,
      builder: (context, value, child) {
        return Text(duration2TimeStr(value), style: TextStyle(fontSize: textSize, color: Colors.white));
      },
    );

    Widget positionText = ValueListenableBuilder<int>(
      valueListenable: displayPosition,
      builder: (context, value, child) {
        var duration = Duration(milliseconds: value);
        return Text(duration2TimeStr(duration), style: TextStyle(fontSize: textSize, color: Colors.white));
      },
    );

    Widget seekBar = ValueListenableBuilder<int>(
      valueListenable: displayPosition,
      builder: (context, value, child) {
        return Slider(
          value: displayPosition.value < 0 ? 0 : displayPosition.value.toDouble(), 
          min: 0, 
          max: duration.value.inMilliseconds.toDouble(), 
          onChanged: (double value) {  
            showPanel();
            displayPosition.value = value.toInt();
            widget.controller.seekTo(Duration(milliseconds: value.toInt()));
          },
        );
      },
    );

    seekBar = SliderTheme(
      data: const SliderThemeData(
          thumbColor: Colors.white,
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white70,
          trackHeight: 1,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: SizedBox(height: iconSize / 3, child: seekBar),
    );

    Widget fullscreenButton = IconButton(
      color: Colors.white,
      iconSize: iconSize,
      icon: Icon(widget._isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
      onPressed: () => doClickFullScreenButton(),
    );

    Widget closedCaptionButton = ValueListenableBuilder(
      valueListenable: hasClosedCaptionFile, 
      builder: (context, value, child) {
        if (!value) return const SizedBox.shrink();
        return ValueListenableBuilder(
          valueListenable: showClosedCaptions,
          builder: (context, value, child) {
            return IconButton(
              color: Colors.white,
              iconSize: iconSize,
              icon: Icon(value ? Icons.subtitles : Icons.subtitles_off_outlined),
              onPressed: () {
                showClosedCaptions.value = !showClosedCaptions.value;
                showPanel();
              },
            );
          }
        );
      },
    );
    

    Widget volumePanel = MouseRegion(
      onEnter: (_) {
        volumeAnimController.forward();
        isMouseInVolumeBar = true;
      },
      onExit: (_) {
        if (!isDraggingVolumeBar) volumeAnimController.reverse();
        isMouseInVolumeBar = false;
        showPanel();
      },
      child: Stack(children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: volumeAnimation, 
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.transparent),
                borderRadius: const BorderRadius.all(Radius.circular(100))
              ),
            ),
          ),
        ),
        Row(children: [
          SizeTransition(
            axis: Axis.horizontal,
            sizeFactor: volumeAnimation,
            child: ValueListenableBuilder<double>(
              valueListenable: volumeValue,
              builder: (context, value, child) {
                return Slider(
                  min: 0,
                  max: 100,
                  value: value * 100,
                  divisions: 100,
                  onChangeStart: (_) => isDraggingVolumeBar = true,
                  onChangeEnd: (_) {
                    isDraggingVolumeBar = false;
                    if (!isMouseInVolumeBar) volumeAnimController.reverse();
                  },
                  onChanged: (value) {
                    widget.controller.setVolume(value / 100);
                    showPanel(); // keep panel visible during dragging volume bar
                  }
                );                
              },
            ),
          ),
          ValueListenableBuilder<double>(
              valueListenable: volumeValue,
              builder: (context, value, child) {
                bool isMute = value <= 0;
                return IconButton(
                  color: isMute ? Colors.red : Colors.white,
                  iconSize: iconSize,
                  icon: Icon(isMute ? Icons.volume_off : Icons.volume_up),
                  onPressed: () => toggleVolumeMute(),
                );
              },
          ),
        ]),
      ]),
    );

    Widget bottomPanel = Column(children: [
      Row(children: [
        if (isDesktop) createPlayPauseButton(false, iconSize),
        positionText,
        Text(" / ", style: TextStyle(fontSize: textSize, color: Colors.white)),
        durationText,
        const Spacer(),
        if (isDesktop && widget.showVolumeButton) volumePanel,
        if (widget.showClosedCaptionButton) closedCaptionButton,
        if (widget.showFullscreenButton && !kIsWeb) fullscreenButton, //TODO: fullscreen makes video black after exit fullscreen in web environment, so remove it
      ],),
      
      seekBar,
    ]);

    bottomPanel = Container(
      padding: EdgeInsets.all(iconSize / 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          //colors: !isDesktop ? <Color>[Colors.transparent, Colors.transparent] : <Color>[Colors.transparent, Colors.black87]),
          colors: <Color>[Colors.transparent, isDesktop ? Colors.black87 : Colors.transparent]),
      ),
      child: bottomPanel,
    );

    int lastTapDownTime = 0;
    Widget gestureWidget = GestureDetector(
      onTapUp: (details) {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastTapDownTime > 300) {
          if (isMouseMode) {
            togglePlayPause();
          } else {
            togglePanel();
          }
        } else {
          var width = context.size!.width;
          if (details.localPosition.dx < width / 2) {
            incrementalSeek(-5000);
          } else {
            incrementalSeek(5000);
          }
        }
        showPanel();
        lastTapDownTime = now;
        focusNode.requestFocus();
      },
    );

    Widget bufferingWidget = ValueListenableBuilder<bool>(
      valueListenable: buffering, 
      builder: (context, value, child) {
        if (value) {
          return Center(
            child: SizedBox(
              width: iconSize * 3,
              height: iconSize * 3,
              child: const CircularProgressIndicator(),
            ),
          );
        } else {
          return Container();
        }
      }
    );

    Widget panelWidget = Stack(
      alignment: Alignment.center,
      children: [
        if (!isDesktop) Container(color: Colors.black38),
        gestureWidget,
        if (!isDesktop) Center(
          child: SizedBox(
            width: 80, 
            height: 80, 
            child: createPlayPauseButton(true, iconSize * 2)
          ),
        ),      
        Positioned(left: 0, bottom: 0, right: 0, child: bottomPanel),
      ], 
    );
    
    panelWidget = FadeTransition(opacity: panelAnimation, child: panelWidget);

    panelWidget = FocusScope(
      autofocus: true,
      node: focusNode,
      child: panelWidget,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) return KeyEventResult.handled;
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (!widget.controller.value.isInitialized) return KeyEventResult.handled;
          if (event is KeyDownEvent) {
            showPanel();
            togglePlayPause();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
          if (event is KeyDownEvent && widget.showFullscreenButton) {
            doClickFullScreenButton();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (event is KeyDownEvent && widget._isFullscreen) {
            doClickFullScreenButton();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          incrementalSeek(-5000);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          incrementalSeek(5000);
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          if (event is KeyDownEvent && isDesktop) {
            toggleVolumeMute();
            showPanel();
          }
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;        
      },
    );

    panelWidget = ValueListenableBuilder<bool>(
      valueListenable: mouseVisibility, 
      builder: ((context, value, child) {
        return MouseRegion(
          // TODO: this not work... 
          // issue: https://github.com/flutter/flutter/issues/76622
          // because when set cursor to [none] after mouse freeze 2 seconds,
          // mouse must move 1 pixel to make MouseRegion apply the cursor settings...
          cursor: mouseVisibility.value ? SystemMouseCursors.basic : SystemMouseCursors.none,
          child: child,
          onHover: (_) => showPanel(),
          onEnter: (_) => isMouseMode = true,
          onExit: (_) => isMouseMode = false,
        );
      }),
      child: panelWidget,
    );    

    Widget closedCaptionWidget = ValueListenableBuilder<bool>(
      valueListenable: showClosedCaptions,
      builder: (context, value, child) {
        if (!value) return const SizedBox.shrink();
        return ValueListenableBuilder<String>(
          valueListenable: currentCaption, 
          builder: (context, value, child) {
            double videoDisplayHeight = MediaQuery.of(context).size.height;
            double textSize = videoDisplayHeight / 20;
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.all(textSize),
                child: Text(value, maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: textSize, color: Colors.white, backgroundColor: Colors.black54)),
              ),           
            );
          },
        );        
      }
    );    

    Widget videoWidget = VideoPlayer(widget.controller);
    if (!kIsWeb && Platform.isAndroid) {
      // package [video_player_android] provide a widget that not follow the video's aspectRatio
      // so we wrap it by AspectRatio here.
      videoWidget = Center(
        child: AspectRatio(
          aspectRatio: widget.controller.value.aspectRatio,
          child: videoWidget,
        ),
      );
    }

    Widget allWidgets = Stack(
      children: [
        Container(color: Colors.black), // video_player open file need time, so put a black bg here
        videoWidget,
        closedCaptionWidget,
        bufferingWidget,
        panelWidget,
      ],
    );

    return allWidgets;
  }
}
