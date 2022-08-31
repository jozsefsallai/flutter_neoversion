library neoversion;

import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:peekanapp/peekanapp.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// A [VersionStatus] is a wrapper class that contains information about an
/// app's local and app store version, as well as its URL on the app store. It
/// can also be used to check if an app needs updating.
class VersionStatus {
  /// The local version of the app, derived from the package's version.
  final String localVersion;

  /// The most recent version of the app in the app store.
  final String appStoreVersion;

  /// The URL of the app's page on the app store.
  final String appStoreUrl;

  VersionStatus(
      {required this.localVersion,
      required this.appStoreVersion,
      required this.appStoreUrl});

  /// Checks if a newer version of the app is available in the app store.
  bool get needsUpdate {
    final local = this.localVersion.split('.').map(int.parse).toList();
    final appStore = this.appStoreVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < appStore.length; ++i) {
      if (local[i] < appStore[i]) {
        return true;
      }

      if (local[i] > appStore[i]) {
        return false;
      }
    }

    return false;
  }
}

/// [NeoVersion] is a class that allows you to check for version updates for an
/// app and prompt the users to update if a newer version is available. It uses
/// the Peek-An-App API to fetch the latest versions from the app stores.
class NeoVersion {
  late PeekanappClient _peekanapp;

  /// The string identifier of the Android app on the Google Play Store.
  String? androidAppId;

  /// The string identifier of the iOS app on the Apple App Store.
  String? iOSAppId;

  NeoVersion({this.androidAppId, this.iOSAppId}) {
    this._peekanapp = PeekanappClient();
  }

  /// Factory method that creates a new [NeoVersion] instance with a different
  /// Peek-An-App API URL.
  factory NeoVersion.withPeekanappApiUrl(String url) {
    return NeoVersion(androidAppId: null, iOSAppId: null)
      .._peekanapp = PeekanappClient.withApiUrl(url);
  }

  /// A method that returns the version status for the provided app, based on
  /// the app's platform. Currently, only Android and iOS are supported, any
  /// other platform will throw an exception.
  Future<VersionStatus> getVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isIOS) {
      return _getIOSVersionStatus(packageInfo);
    } else if (Platform.isAndroid) {
      return _getAndroidVersionStatus(packageInfo);
    } else {
      throw Exception('Unsupported platform ${Platform.operatingSystem}');
    }
  }

  Future<VersionStatus> _getIOSVersionStatus(PackageInfo packageInfo) async {
    final response = await this
        ._peekanapp
        .getAppVersion(iOSAppId: this.iOSAppId ?? packageInfo.packageName);
    return VersionStatus(
        localVersion: this._normalizeVersion(packageInfo.version),
        appStoreVersion: this._normalizeVersion(response.appstore),
        appStoreUrl: response.meta.appstoreUrl ?? 'unknown');
  }

  Future<VersionStatus> _getAndroidVersionStatus(
      PackageInfo packageInfo) async {
    final response = await this._peekanapp.getAppVersion(
        androidAppId: this.androidAppId ?? packageInfo.packageName);
    return VersionStatus(
        localVersion: this._normalizeVersion(packageInfo.version),
        appStoreVersion: this._normalizeVersion(response.playstore),
        appStoreUrl: response.meta.playstoreUrl ?? 'unknown');
  }

  /// A method that will show an update dialog for the user. You usually don't
  /// want to call this directly, unless you want to manually check the version
  /// status after a [getVersionStatus] call and you want more granular control
  /// over when the dialog is displayed.
  ///
  /// * [context] is the context that the dialog will be displayed in.
  /// * [status] is the [VersionStatus] object that will be used for the version
  ///   information.
  /// * [title] is an optional custom title for the dialog.
  /// * [dialogText] is an [UpdateDialogText] callback function that will be
  ///   called to generate the text of the dialog.
  /// * [updateButtonText] is an optional custom text of the Update button.
  /// * [dismissable] specifies whether the user is allowed to dismiss the
  ///   dialog.
  /// * [dismissButtonText] is an optional custom text of the Dismiss button.
  /// * [onDismissed] is the callback that will be called when the user
  ///   dismisses the dialog.
  Future<void> showUpdateDialog({
    required BuildContext context,
    required VersionStatus status,
    String title = 'Update available',
    UpdateDialogText? dialogText,
    String updateButtonText = 'Update',
    bool dismissable = true,
    String dismissButtonText = 'Dismiss',
    VoidCallback? onDismissed,
  }) async {
    final titleWidget = Text(title);
    final textWidget = Text((dialogText ?? _defaultUpdateDialogText)(
        status.localVersion, status.appStoreVersion, dismissable));

    List<Widget> actions = [];

    if (Platform.isAndroid) {
      actions.add(
        TextButton(
            child: Text(updateButtonText),
            onPressed: () => _onUpdateButtonPressed(
                context, status.appStoreUrl, dismissable)),
      );
    }

    if (Platform.isIOS) {
      actions.add(
        CupertinoDialogAction(
            child: Text(updateButtonText),
            onPressed: () => _onUpdateButtonPressed(
                context, status.appStoreUrl, dismissable)),
      );
    }

    if (dismissable) {
      final dismissAction = onDismissed != null
          ? onDismissed
          : () => _onDismissButtonPressed(context);

      if (Platform.isAndroid) {
        actions.add(
          TextButton(child: Text(dismissButtonText), onPressed: dismissAction),
        );
      }

      if (Platform.isIOS) {
        actions.add(
          CupertinoDialogAction(
              child: Text(dismissButtonText), onPressed: dismissAction),
        );
      }
    }

    await showDialog(
        context: context,
        barrierDismissible: dismissable,
        builder: (BuildContext context) {
          return WillPopScope(
            child: Platform.isAndroid
                ? AlertDialog(
                    title: titleWidget,
                    content: textWidget,
                    actions: actions,
                  )
                : CupertinoAlertDialog(
                    title: titleWidget,
                    content: textWidget,
                    actions: actions,
                  ),
            onWillPop: () => Future.value(dismissable),
          );
        });
  }

  /// Checks if the version status is outdated and prompts the user to update,
  /// if necessary.
  ///
  /// * [context] is the context that the dialog will be displayed in.
  /// * [title] is an optional custom title for the dialog.
  /// * [dialogText] is an [UpdateDialogText] callback function that will be
  ///   called to generate the text of the dialog.
  /// * [updateButtonText] is an optional custom text of the Update button.
  /// * [dismissable] specifies whether the user is allowed to dismiss the
  ///   dialog.
  /// * [dismissButtonText] is an optional custom text of the Dismiss button.
  /// * [onDismissed] is the callback that will be called when the user
  ///   dismisses the dialog.
  Future<void> showAlertIfNecessary(
      {required BuildContext context,
      String title = 'Update available',
      UpdateDialogText? dialogText,
      String updateButtonText = 'Update',
      bool dismissable = true,
      String dismissButtonText = 'Dismiss',
      VoidCallback? onDismissed}) async {
    final VersionStatus? status = await getVersionStatus();
    if (status?.needsUpdate == true) {
      await showUpdateDialog(
          context: context,
          status: status!,
          title: title,
          dialogText: dialogText,
          updateButtonText: updateButtonText,
          dismissable: dismissable,
          dismissButtonText: dismissButtonText,
          onDismissed: onDismissed);
    }
  }

  String _defaultUpdateDialogText(
      String localVersion, String appStoreVersion, bool dismissable) {
    String base =
        'A new version of the app is available for download ($appStoreVersion). Your version is $localVersion.';

    if (dismissable) {
      return base + ' Would you like to update?';
    } else {
      return base + ' Please update to the latest version.';
    }
  }

  void _onUpdateButtonPressed(
      BuildContext context, String appStoreUrl, bool dismissable) {
    this._launchAppStore(appStoreUrl);

    if (dismissable) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _onDismissButtonPressed(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _launchAppStore(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch app store URL: $url';
    }
  }

  String _normalizeVersion(String? raw) {
    if (raw == null) {
      log('Warning: failed to normalize version string: raw version is null',
          level: 900);
      return '0.0.0';
    }

    final match = RegExp(r'\d+(\.\d+)*').firstMatch(raw)?.group(0);

    if (match == null) {
      log('Warning: failed to normalize version string: raw version $raw is invalid',
          level: 900);
      return '0.0.0';
    }

    return match;
  }
}

/// An [UpdateDialogText] is a function that receives the [localVersion], an
/// [appStoreVersion], and a [dismissable] parameters, in that order. This is
/// useful for defining custom dialog text (i.e. for i18n).
typedef UpdateDialogText = String Function(
    String localVersion, String appStoreVersion, bool dismissable);
