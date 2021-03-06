import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:json_object/json_object.dart';
import 'package:w_transport/w_transport_vm.dart' show configureWTransportForVM;

ArgResults argResults;

void main(List<String> arguments) {
  final ArgParser argParser = new ArgParser()
    ..addOption('name', abbr: 'n', help: 'Please specify your Cloudinary Cloud Name')
    ..addOption('key', abbr: 'k', help: 'Please specify your Cloudinary API KEY')
    ..addOption('secret', abbr: 's', help: 'Please specify your Cloudinary API SECRET')
    ..addFlag('help', abbr: 'h', negatable: false, help: "Displays this help information.");

  argResults = argParser.parse(arguments);

  final String CLOUD_NAME = argResults['name'];
  final String API_KEY = argResults['key'];
  final String API_SECRET = argResults['secret'];

  if (argResults['help']) {
    printHelp(argParser);
    exit(2);
  } else if (CLOUD_NAME == null) {
    handleError(argParser, "Missing required argument: name\nUse either --name=<Cloudinary Cloud Name> OR -n<Cloudinary Cloud Name>");
  } else if (API_KEY == null) {
    handleError(argParser, "Missing required argument: key\nUse either --key=<Cloudinary APP KEY> OR -k<Cloudinary APP KEY>");
  } else if (API_SECRET == null) {
    handleError(argParser, "Missing required argument: secret\nUse either --secret=<Cloudinary APP SECRET> OR -s<Cloudinary APP SECRET>");
  } else {
    configureWTransportForVM();
    downloadPictures(CLOUD_NAME, API_KEY, API_SECRET);
  }
}

void handleError(ArgParser argParser, String msg) {
  stderr.writeln(red(msg));
  printHelp(argParser);
  exit(2);
}

void printHelp(ArgParser argParser) {
  print("${yellow('===== HELP =====')} \n${argParser.usage}\n");
}

Future downloadPictures(String CLOUD_NAME, String API_KEY, String API_SECRET) async {
  // SET UP THE URL
  String apiUrl = 'https://' + API_KEY + ':' + API_SECRET + '@api.cloudinary.com/v1_1/' + CLOUD_NAME + '/resources/image?max_results=500';

  // DELETE THE DIRECTORY
  try {
    await new Directory('backup/' + CLOUD_NAME).delete(recursive: true);
  } catch (e) {}

  // CREATE A DIRECTORY
  var directory = await new Directory('backup/' + CLOUD_NAME).create(recursive: true);
  print('Creating directory ${directory.path}');

  // GET ALL THE INFORMATION THAT WE NEED
  var resp = await http.get(Uri.parse(apiUrl));
  if (resp.statusCode != 200) {
    print("There has been an error either with your cloud name or the authentication. Please fix it.");
    exit(2);
  }
  var response = new JsonObject.fromJsonString(resp.body);
  var cl_images = response.resources;

  var size = 0;
  for (var image in cl_images) {
    var name = image.public_id;
    var format = image.format;
    var url = image.url;

    // Download the actual image.
    var image_request = await http.get(Uri.parse(url));

    File file = await new File('${directory.path}/' + name + '.' + format);
    File saved = await file.writeAsBytes(image_request.bodyBytes);

    var file_size = await saved.lengthSync();

    size += file_size;

    int parsed_file_size = ((file_size / 1024) / 1024).round();
    int parsed_size = ((size / 1024) / 1024).round();
    print('File ${file.path} saved. File Size: ${parsed_file_size}MB. Total Size: ${green(parsed_size.toString() + 'MB')}');
  }
  int parsed_size = ((size / 1024) / 1024).round();
  print(green("Completed!! A total of ($parsed_size) MB have been used."));
  exit(1);
}

/// Yellow AnsiPen
AnsiPen yellow(String text) {
  AnsiPen yellow = new AnsiPen()..yellow();
  return yellow(text);
}


/// Red AnsiPen
AnsiPen red(String text) {
  AnsiPen red = new AnsiPen()..red();
  return red(text);
}

/// Green AnsiPen
AnsiPen green(String text) {
  AnsiPen green = new AnsiPen()..green();
  return green(text);
}
