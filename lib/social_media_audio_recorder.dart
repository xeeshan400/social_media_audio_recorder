library social_media_audio_recorder;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:social_media_audio_recorder/widget/Flow.dart';
import 'package:social_media_audio_recorder/widget/lottie.dart';

class SocialMediaFilePath {
  SocialMediaFilePath._();

  static init() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    documentPath = "${appDocumentsDir.path}/";
  }

  static String documentPath = '';
}

class RecordButton extends StatefulWidget {
  final AnimationController controller; //animated controller
  final double? timerWidth; // show timer widget with
  final double? lockerHeight; //lock widget height
  final double? size;
  final double? radius;
  final bool? releaseToSend;
  final Color? color;
  final Color? allTextColor;
  final Color? arrowColor;
  final Color? recordButtonColor;
  final Color? recordBgColor;

  final Function(String value) onRecordEnd;
  final Function onRecordStart;
  final Function onCancelRecord;
  const RecordButton(
      {Key? key,
      required this.controller,
        this.releaseToSend=false,
      this.timerWidth,
      this.lockerHeight = 200,
      this.size = 55,
      this.color = Colors.white,
      this.radius = 10,
      required this.onRecordEnd,
      required this.onRecordStart,
      required this.onCancelRecord,
      this.allTextColor,
      this.arrowColor,
      this.recordButtonColor,
      this.recordBgColor, })
      : super(key: key);

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  double timerWidth = 0;

  Animation<double>? buttonScaleAnimation;
  Animation<double>? timerAnimation;
  Animation<double>? lockerAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  Record? record;

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    //init();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        (widget.timerWidth ?? MediaQuery.of(context).size.width - 2 * 8 - 4);
    timerAnimation = Tween<double>(begin: timerWidth + 8, end: 0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: widget.lockerHeight! + 8, end: 0).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    if (record != null) {
      record?.dispose();
    }
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        lockSlider(),
        cancelSlider(),
        audioButton(),
        if (isLocked) timerLocked(),
      ],
    );
  }

  Widget lockSlider() {
    return lockerAnimation!.value == 0.0
        ? Positioned(
            bottom: -lockerAnimation!.value,
            child: Container(
              height: widget.lockerHeight,
              width: widget.size!,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius!),
                color: widget.color,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FaIcon(
                    FontAwesomeIcons.lock,
                    size: 20,
                    color: widget.arrowColor ?? Colors.black,
                  ),
                  const SizedBox(height: 8),
                  FlowShader(
                    direction: Axis.vertical,
                    child: Column(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: widget.arrowColor ?? Colors.black,
                        ),
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: widget.arrowColor ?? Colors.black,
                        ),
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: widget.arrowColor ?? Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget cancelSlider() {
    return Positioned(
      right: -timerAnimation!.value,
      child: Container(
        height: widget.size!,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius!),
          color: widget.color,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showLottie
                  ? const LottieAnimation()
                  : Text(recordDuration,
                      style: TextStyle(
                          color: widget.allTextColor ?? Colors.black)),
              SizedBox(width: widget.size!),
              FlowShader(
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
                child: Row(
                  children: [
                    Icon(Icons.keyboard_arrow_left,
                        color: widget.allTextColor ?? Colors.black),
                    Text(
                      "Slide to cancel",
                      style:
                          TextStyle(color: widget.allTextColor ?? Colors.black),
                    )
                  ],
                ),
              ),
              SizedBox(width: widget.size!),
            ],
          ),
        ),
      ),
    );
  }
  kVibrate()async{
    if (await Vibration.hasVibrator()) {
    Vibration.vibrate();
    }
  }

  Widget timerLocked() {
    return Positioned(
      right: 0,
      child: Container(
        height: widget.size!,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
              widget.radius == null ? 10 : widget.radius!),
          color: widget.color,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 25),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              kVibrate();
              // Vibrate.feedback(FeedbackType.success);
              timer?.cancel();
              timer = null;
              startTime = null;
              recordDuration = "00:00";

              var filePath = await Record().stop(); //Record file

              setState(() {
                isLocked = false;

                widget.onRecordEnd(filePath!);
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(recordDuration,
                    style:
                        TextStyle(color: widget.allTextColor ?? Colors.black)),
                FlowShader(
                  duration: const Duration(seconds: 3),
                  flowColors: [widget.arrowColor ?? Colors.white, Colors.grey],
                  child: Text("Tap lock to stop",
                      style: TextStyle(
                          color: widget.allTextColor ?? Colors.black)),
                ),
                const Center(
                  child: FaIcon(
                    FontAwesomeIcons.lock,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      child: Transform.scale(
        scale: buttonScaleAnimation!.value,
        child: Container(
          height: widget.size!,
          width: widget.size!,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.recordBgColor ?? Theme.of(context).primaryColor,
          ),
          child: Icon(
            Icons.mic,
            color: widget.recordButtonColor ?? Colors.black,
          ),
        ),
      ),
      onLongPressDown: (_) {
        debugPrint("onLongPressDown");
        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        debugPrint("onLongPressEnd");

        if (isCancelled(details.localPosition, context)) {
          kVibrate();
          // Vibrate.feedback(FeedbackType.heavy);

          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";
          setState(() {
            showLottie = true;
          });
          widget.onCancelRecord();

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();
            debugPrint("Cancelled recording");
            var filePath = await record!.stop();

            File(filePath!).delete();

            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();
          kVibrate();
          // Vibrate.feedback(FeedbackType.heavy);
          debugPrint("Locked recording");
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
          widget.onRecordStart();
        } else {
          widget.controller.reverse();

          // Vibrate.feedback(FeedbackType.success);
          kVibrate();
          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";
          var filePath = await record!.stop();
         // print("fuad");
          if(widget.releaseToSend!) {
            widget.onRecordEnd(filePath!);
          }
          else{
             widget.onCancelRecord();
          }
        }
      },
      onLongPressCancel: () {
        debugPrint("onLongPressCancel");
        widget.controller.reverse();
      },
      onLongPress: () async {
        debugPrint("onLongPress");
        kVibrate();
        // Vibrate.feedback(FeedbackType.success);
        if (await Record().hasPermission()) {
          record = Record();
          await record!.start(
            path:
                "${SocialMediaFilePath.documentPath}audio_${DateTime.now().millisecondsSinceEpoch}.acc",
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            samplingRate: 44100,
          );
          startTime = DateTime.now();
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final minDur = DateTime.now().difference(startTime!).inMinutes;
            final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
            String min = minDur < 10 ? "0$minDur" : minDur.toString();
            String sec = secDur < 10 ? "0$secDur" : secDur.toString();
            setState(() {
              recordDuration = "$min:$sec";
            });
          });

          // widget.onRecordStart();
        }
      },
    );
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}
