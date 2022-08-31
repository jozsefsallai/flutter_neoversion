# Flutter NeoVersion

Check if a new version of a Flutter app is available on the app stores. The
plugin uses the [Peek-An-App][peekanapp-url] API to get information about the
latest version.

This plugin is heavily inspired by the [new_version][new-version-plugin-url]
plugin, however, the APIs are NOT backwards-compatible.

## Basic usage

Create a new NeoVersion class instance wherever you want to check for new
versions:

```dart
import 'package:neoversion/neoversion.dart';

final neoVersion = NeoVersion();
```

The package will use the package name from your Flutter project to identify the
app on the app stores, however, you may also pass your own identifiers:

```dart
final neoVersion = NeoVersion(androidAppId: 'com.example.app', iOSAppId: 'com.example.app');
```

Once you have that, you can call the following method to prompt the user if a
new version is available:

```dart
await neoVersion.showAlertIfNecessary(context: context);
```

You can also consume the version status manually and have custom behavior for
the prompts:

```dart
final status = await neoVersion.getVersionStatus();
status.needsUpdate; // (boolean)
status.localVersion; // (string, the currently installed app's version)
status.appStoreVersion; // (string, the latest version on the app store)

await neoVersion.showUpdateDialog(context: context, status: status);
```

## Customization

The plugin's default dialog is very easy to customize. Please refer to the
[API Reference][api-ref] for more information.

## Credits

- [new_version plugin][new-version-plugin-url]

## License

MIT.

[api-ref]: https://pub.dev/documentation/neoversion/latest/
[new-version-plugin-url]: https://github.com/timtraversy/new_version
[peekanapp-url]: https://peekanapp.vercel.app
