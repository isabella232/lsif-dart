library updated_files_list;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async';
import 'package:crossdart/src/db_pool.dart';
import 'package:crossdart/src/location.dart';
import 'package:crossdart/src/args.dart';
import 'package:crossdart/src/package_info.dart';
import 'package:crossdart/src/package.dart';
import 'package:crossdart/src/config.dart';
import 'package:crossdart/src/store/db_package_loader.dart';

Future<Null> main(args) async {
  var updatedFilesListArgs = new UpdatedFilesListArgs(args);
  if (!updatedFilesListArgs.runChecks()) {
    return;
  }

  var results = updatedFilesListArgs.results;
  var config = new Config.buildFromFiles(dirroot: results[Config.DIR_ROOT], isDbUsed: true);

  var timestamp = int.parse((await http.get("http://www.crossdart.info/timestamp")).body);

  var packageLoader = new DbPackageLoader(config);
  var datetime = new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  Iterable<PackageInfo> _allPackageInfos = (await packageLoader.getAllPackageInfos(datetime));

  for (var packageInfo in _allPackageInfos) {
    Package package = await buildFromFileSystem(config, packageInfo);
    for (var path in package.paths) {
      var location = new Location(config, package, path);
      if (new File(location.writePath).existsSync()) {
        print(location.writePath.replaceAll(config.outputPath, ""));
      }
    }
    var indexPath = p.join(config.gcsPrefix, packageInfo.name, "index.html");
    if (new File(p.join(config.outputPath, indexPath)).existsSync()) {
      print("/" + indexPath);
    }
  }

  deallocDbPool();
}
