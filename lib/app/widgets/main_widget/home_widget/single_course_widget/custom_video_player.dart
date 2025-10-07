import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'full_screen_video_page.dart'; // استيراد صفحة ملء الشاشة
import 'dart:async'; // استيراد مكتبة Timer

class PodVideoPlayerDev extends StatefulWidget {
  final String type;
  final String url;
  final String name;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const PodVideoPlayerDev(this.url, this.type, this.routeObserver,
      {super.key, required this.name});

  @override
  State<PodVideoPlayerDev> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<PodVideoPlayerDev> {
  double _watermarkPositionX = 0.0; // متغير لتحديد مكان العلامة المائية أفقياً
  double _watermarkPositionY = 0.0; // متغير لتحديد مكان العلامة المائية رأسياً
  late Timer _timer;
  late YoutubePlayerController _controller;

  // دالة لتبديل الوضع بين ملء الشاشة والوضع الطبيعي
  void _toggleFullScreen() {
    // حفظ حالة التشغيل الحالية
    final wasPlaying = _controller.value.isPlaying;
    final currentPosition = _controller.value.position;

    // الانتقال إلى صفحة ملء الشاشة مع تمرير البيانات المطلوبة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(
          url: widget.url,
          name: widget.name,
          initialPosition: currentPosition,
          wasPlaying: wasPlaying,
        ),
      ),
    ).then((result) {
      // إعادة تعيين الحالة بعد العودة من ملء الشاشة
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      // تحديث حالة الفيديو إذا تم إرجاع بيانات
      if (result != null && result is Map<String, dynamic>) {
        final position = result['position'] as Duration?;
        final wasPlaying = result['isPlaying'] as bool?;

        if (position != null) {
          _controller.seekTo(position);
        }
        if (wasPlaying != null && wasPlaying) {
          _controller.play();
        }
      }
    });
  }
  // final _headsetPlugin = HeadsetEvent();
  // HeadsetState? _headsetState;

  @override
  void initState() {
    super.initState();

    // Initialize YoutubePlayerController
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(widget.url) ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );

    ///Request Permissions (Required for Android 12)
    // _headsetPlugin.requestPermission();

    // /// if headset is plugged
    // _headsetPlugin.getCurrentState.then((_val) {
    //   setState(() {
    //     _headsetState = _val;
    //     print(_headsetState);
    //     print("_headsetState1");
    //   });
    // });

    // /// Detect the moment headset is plugged or unplugged
    // _headsetPlugin.setListener((_val) {
    //   setState(() {
    //     _headsetState = _val;
    //     print(_headsetState);
    //     print("_headsetState2");
    //   });
    // });

    // إعداد الـ Timer لتحريك العلامة المائية كل 3 ثواني
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        // التبديل بين مكانين مختلفين للعلامة المائية: من الزاوية العلوية اليسرى إلى المنتصف
        if (_watermarkPositionX == 0.0 && _watermarkPositionY == 0.0) {
          _watermarkPositionX = 0.5; // التحرك نحو المنتصف أفقياً
          _watermarkPositionY = 0.5; // التحرك نحو المنتصف رأسياً
        } else {
          _watermarkPositionX = 0.0; // العودة إلى الزاوية العلوية اليسرى أفقياً
          _watermarkPositionY = 0.0; // العودة إلى الزاوية العلوية اليسرى رأسياً
        }
      });
    });
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    // إلغاء الـ Timer عند تدمير الـ widget لتجنب التسريبات
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 400, // ارتفاع العرض الطبيعي
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: MediaQuery.of(context).size.width,
                  child: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.blue,
                    onReady: () {
                      // Player is ready
                    },
                    bottomActions: [
                      const CurrentPosition(),
                      const ProgressBar(isExpanded: true),
                      const RemainingDuration(),
                      const PlaybackSpeedButton(),
                      IconButton(
                        icon: const Icon(Icons.fullscreen),
                        onPressed: _toggleFullScreen,
                      ),
                    ],
                  ),
                ),
                // العلامة المائية
                AnimatedPositioned(
                  duration: const Duration(seconds: 1),
                  left: _watermarkPositionX == 0.0
                      ? 0
                      : (MediaQuery.of(context).size.width / 2) - 100,
                  top: _watermarkPositionY == 0.0 ? 0 : (250 / 2) - 50,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.transparent,
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
