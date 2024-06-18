import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:activos_fijos/views/save_activo.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTflite();
  }

  @override
  void dispose() {
    cameraController.dispose();
    Tflite.close();
    super.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;
  var label = "";
  var val = "";
  var imagePath = "".obs;
  var modelLoaded = false.obs;
  var isCapturing = false.obs;

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      await cameraController.initialize().then((value) {
        cameraCount = 0;
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 10 == 0) {
            cameraCount = 0;
            if (modelLoaded.value) {
              objectDetector(image);
            }
          }
          update();
        });
        update();
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  initTflite() async {
    try {
      await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/label.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false,
      );
      modelLoaded(true);
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  objectDetector(CameraImage image) async {
    try {
      print("Running model on frame");
      var detector = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((e) {
          return e.bytes;
        }).toList(),
        asynch: true,
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 1,
        rotation: 90,
        threshold: 0.4,
      );

      if (detector != null && detector.isNotEmpty) {
        var ourDetectedObject = detector.first;
        print("Result is $detector");

        print("Detected object keys: ${ourDetectedObject.keys}");

        if (ourDetectedObject.containsKey('label') &&
            ourDetectedObject.containsKey('confidence')) {
          val = ourDetectedObject['label'];

          if (ourDetectedObject['confidence'] * 100 > 45) {
            label = ourDetectedObject['label'].toString();
            if (label == "notebook" && !isCapturing.value) {
              // Verifica el estado de captura
              label = "COMPUTADORA";
              isCapturing(true); // Marca que una captura está en progreso
              await captureAndSendImage();
              isCapturing(false); // Marca que la captura ha terminado
              //cameraController.resumePreview();
              cameraController.pausePreview();
            }
            print(label);
          }
          update();
        } else {
          print("Required keys not found in detected object");
        }
      } else {
        print("Detector is empty or null");
      }
    } catch (e) {
      print("Error running model on frame: $e");
    }
  }

  Future<void> captureAndSendImage() async {
    try {
      print("Capturing image...");
      final image = await cameraController.takePicture();
      imagePath(image.path);
      await sendImageToServer(image.path);
      Get.to(() => SaveActivo(nombre: label, imagePath: imagePath.value));
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<void> sendImageToServer(String imagePath) async {
    var uri =
        Uri.parse('https://back-microservicio-mobilexd.fly.dev/add-activo');
    var request = http.MultipartRequest('POST', uri);
    request.fields['nombre'] = label;

    var mimeTypeData = lookupMimeType(imagePath)!.split('/');
    var file = await http.MultipartFile.fromPath(
      'urlPhoto',
      imagePath,
      contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
    );
    request.files.add(file);

    try {
      var response = await request.send();
      print("----------------------ENVIADO");
      if (response.statusCode == 200) {
        print('Image uploaded successfully');
      } else {
        print('Image upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }
}
