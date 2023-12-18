import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    loadModel();
    initCamera();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var _numOfRenderedFrame = 0.obs;

  List<dynamic>? recognitions = [];

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.max);

      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          // if camera started streaming [numOfRenderedFrame] will increase according on how many frames was rendered
          _numOfRenderedFrame++;

          //if number of rendered frames reached specified value then call object detector method then reset [_numOfRenderedFrame] to 0
          if (_numOfRenderedFrame.value == 30) {
            objectDetector(image);
            _numOfRenderedFrame(0);
          }

          update(); //update state
        });
      });

      isCameraInitialized(true);

      update();
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false);
  }

  objectDetector(CameraImage image) async {
    try {
      // Output format: x, y, w, h are between [0, 1]. You can scale x, w by the width and y, h by the height of the image.
      recognitions = await Tflite.detectObjectOnFrame(
          bytesList: image.planes.map((e) {
            return e.bytes;
          }).toList(),
          model: "SSDMobileNet",
          imageHeight: image.height,
          imageWidth: image.width,
          numResultsPerClass: 5, // defaults to 5
          threshold: 0.5, // defaults to 0.1
          asynch: true // defaults to true
          );

      update(); //update state
    } catch (e) {
      //catch interpreter busy
    }
  }
}
