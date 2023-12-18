import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_tflite/components/detected_object_box.dart';
import 'package:test_tflite/controller/scan_controller.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;

    List<Widget> renderBoxes(controller) {
      //controller = {
      //   detectedClass: "hot dog",
      //   confidenceInClass: 0.123,
      //   rect: {x: 0.15, y: 0.33, w: 0.80, h: 0.27}
      // };
      List<Widget> boxes = [];

      controller.recognitions?.forEach((val) {
        var x = 0.0, y = 0.0, w = 0.0, h = 0.0;
        var label = "";
        var confidence = 0.0;

        if (val['confidenceInClass'] * 100 > 50) {
          label = val['detectedClass'].toString();
          confidence = val['confidenceInClass'];
          h = val['rect']['h'];
          w = val['rect']['w'];
          x = val['rect']['x'];
          y = val['rect']['y'];
        }

        boxes.add(DetectedObjectBox(
          x: x,
          y: y,
          w: w,
          h: h,
          label: label,
          confidence: confidence,
          width: context.width,
          height: context.height,
        ));
      });

      return boxes;
    }

    return Scaffold(
      body: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          final scale = controller.isCameraInitialized.value
              ? 1 /
                  (controller.cameraController.value.aspectRatio *
                      mediaSize.aspectRatio)
              : 0.0;

          return controller.isCameraInitialized.value
              ? Stack(
                  children: [
                    ClipRect(
                      clipper: _MediaSizeClipper(mediaSize),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topCenter,
                        child: CameraPreview(controller.cameraController),
                      ),
                    ),
                    Stack(
                      children: renderBoxes(controller),
                    )
                  ],
                )
              : const Center(child: Text('Loading Preview...'));
        },
      ),
    );
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
