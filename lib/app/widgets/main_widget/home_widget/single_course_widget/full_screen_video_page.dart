import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String url;
  final String name;
  final Duration initialPosition;
  final bool wasPlaying;

  const FullScreenVideoPage({
    super.key,
    required this.url,
    required this.name,
    required this.initialPosition,
    required this.wasPlaying,
  });

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  double _watermarkPositionX = 0.0; // متغير لتحديد مكان العلامة المائية أفقياً
  double _watermarkPositionY = 0.0; // متغير لتحديد مكان العلامة المائية رأسياً
  late Timer _timer;
  late YoutubePlayerController _controller;
  bool _hasSetInitialState = false;

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

    // Set initial position and playing state after controller is ready
    _controller.addListener(() {
      if (_controller.value.isReady && !_hasSetInitialState) {
        _hasSetInitialState = true;
        // Seek to the position from the previous player
        _controller.seekTo(widget.initialPosition);
        // Start playing if it was playing before
        if (widget.wasPlaying) {
          _controller.play();
        }
      }
    });

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
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // إلغاء الـ Timer عند تدمير الـ widget لتجنب التسريبات
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التأكد من تعديل اتجاه الشاشة إلى الوضع الأفقي (Landscape)
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky); // إخفاء شريط الحالة والأزرار

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Handle back button press
          final currentPosition = _controller.value.position;
          final isPlaying = _controller.value.isPlaying;

          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

          Navigator.pop(context, {
            'position': currentPosition,
            'isPlaying': isPlaying,
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height, // ملء الشاشة ارتفاعًا
                  width: MediaQuery.of(context).size.width, // ملء الشاشة عرضًا
                  child: GestureDetector(
                    onTap: () {
                      // Toggle play/pause on tap
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    },
                    onDoubleTapDown: (details) {
                      // Seek forward/backward on double tap
                      final screenWidth = MediaQuery.of(context).size.width;
                      final tapPosition = details.globalPosition.dx;

                      if (tapPosition < screenWidth / 2) {
                        // Double tap on left side - seek backward 10 seconds
                        final newPosition = _controller.value.position -
                            const Duration(seconds: 10);
                        _controller.seekTo(newPosition > Duration.zero
                            ? newPosition
                            : Duration.zero);
                      } else {
                        // Double tap on right side - seek forward 10 seconds
                        final newPosition = _controller.value.position +
                            const Duration(seconds: 10);
                        _controller.seekTo(newPosition);
                      }
                    },
                    child: YoutubePlayer(
                      controller: _controller,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.blue,
                      onReady: () {
                        // Player is ready
                      },
                      bottomActions: const [
                        CurrentPosition(),
                        ProgressBar(isExpanded: true),
                        RemainingDuration(),
                        PlaybackSpeedButton(),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    // إعادة الوضع الرأسي عند العودة
                    SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitUp]);
                    SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge); // عرض شريط الحالة والأزرار

                    // إرجاع البيانات الحالية للفيديو عند العودة
                    final currentPosition = _controller.value.position;
                    final isPlaying = _controller.value.isPlaying;

                    // العودة للصفحة السابقة مع البيانات
                    Navigator.pop(context, {
                      'position': currentPosition,
                      'isPlaying': isPlaying,
                    });
                  },
                ),
              ),
              // إضافة العلامة المائية في وسط الشاشة عند التبديل إلى وضع ملء الشاشة
              AnimatedPositioned(
                duration: const Duration(seconds: 1), // مدة الحركة
                // الحساب لتحديد مكان العلامة المائية أفقيًا ورأسيًا في وسط الفيديو
                right: _watermarkPositionX == 0.0
                    ? 20 // الزاوية العلوية اليسرى
                    : (MediaQuery.of(context).size.width / 2) -
                        100, // المنتصف أفقياً (للسهولة، قمنا بطرح 100 لأن عرض النص سيكون 200 تقريبًا)
                top: _watermarkPositionY ==
                        (MediaQuery.of(context).size.height / 2)
                    ? 20 // الزاوية العلوية اليسرى
                    : (MediaQuery.of(context).size.height / 2) -
                        50, // المنتصف رأسياً (حيث أن ارتفاع الشاشة هو 250، نقوم بتحديد المنتصف عن طريق الحساب)
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.transparent,
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 10, // حجم الخط
                      color: Colors.black.withOpacity(0.5), // شفافية النص
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
