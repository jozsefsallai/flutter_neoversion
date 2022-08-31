// ignore_for_file: dead_code

// credits: https://github.com/timtraversy/new_version/blob/master/example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:neoversion/neoversion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();

    final neoVersion = NeoVersion(
      androidAppId: 'app.somus.social',
      iOSAppId: 'app.somus.social',
    );

    const simpleBehavior = true;

    if (simpleBehavior) {
      basicStatusCheck(neoVersion);
    } else {
      advancedStatusCheck(neoVersion);
    }
  }

  basicStatusCheck(NeoVersion neoVersion) {
    neoVersion.showAlertIfNecessary(context: context);
  }

  advancedStatusCheck(NeoVersion neoVersion) async {
    final status = await neoVersion.getVersionStatus();
    debugPrint(status.appStoreUrl);
    debugPrint(status.localVersion);
    debugPrint(status.appStoreVersion);
    debugPrint(status.needsUpdate.toString());
    neoVersion.showUpdateDialog(
      context: context,
      status: status,
      title: 'Custom Title',
      dialogText: (String local, String appstore, bool dismissable) =>
          'Custom Text - local: $local, appstore: $appstore, dismissable: $dismissable',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Example App for NeoVersion"),
      ),
    );
  }
}
