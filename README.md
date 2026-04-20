## ☕ Support Me

If you find this plugin useful, please consider supporting me:

[![Buy Me a Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/codesfirst)


Note
Original repository: https://pub.dev/packages/new_version

The problem with the original repository is that it will no longer be maintained by the creator, for this reason this repository was created in order to maintain updated code and make respective improvements as long as it is required.

# New Version Plus Plugin 🎉

A Flutter plugin that makes it possible to:

- Check if a user has the most recent version of your app installed.
- Show the user an alert with a link to the appropriate app store page.

See more at the [Dart Packages page.](https://pub.dartlang.org/packages/new_version_plus)

![Screenshots](screenshots/both.png)

## Installation

Add new_version_plus as [a dependency in your `pubspec.yaml` file.](https://flutter.io/using-packages/)

```
dependencies:
  new_version_plus: ^0.0.9
```

## Usage

In `main.dart` (or wherever your app is initialized), create an instance of `NewVersionPlus`.

`final newVersionPlus = NewVersionPlus();`

The plugin will automatically use your Flutter package identifier to check the app store. If your app has a different identifier in the Google Play Store or Apple App Store, you can overwrite this by providing values for `androidId` and/or `iOSId`.

_For iOS:_ If your app is only available outside the U.S. App Store, you will need to set `iOSAppStoreCountry` to the two-letter country code of the store you want to search. See http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for a list of ISO Country Codes.

You can then use the plugin in two ways.

### Quickstart

Calling `showAlertIfNecessary` with your app's `BuildContext` will check if the app can be updated, and will automatically display a platform-specific alert that the user can use to go to the app store.

`newVersionPlus.showAlertIfNecessary(context: context);`

### Advanced 😎

If you want to create a custom alert or use the app version information differently, call `getVersionStatus`. This will return a `Future<VersionStatus>` with information about the local and app store versions of the app.

```
final status = await newVersionPlus.getVersionStatus();
status.canUpdate // (true)
status.localVersion // (1.2.1)
status.storeVersion // (1.2.3)
status.appStoreLink // (https://itunes.apple.com/us/app/google/id284815942?mt=8)
```

If you want to present a customized dialog, you can pass your `VersionStatus` to `showUpdateDialog()`.

```
newVersionPlus.showUpdateDialog(
  context: context,
  versionStatus: status,
  dialogTitle: 'Custom dialog title',
  dialogText: 'Custom dialog text',
  updateButtonText: 'Custom update button text',
  dismissButtonText: 'Custom dismiss button text',
  dismissAction: () => functionToRunAfterDialogDismissed(),
)
```

The option was added so that in the android app you can modify the code of your country, with the variable: `androidPlayStoreCountry`

### Huawei AppGallery

Huawei AppGallery is not supported out of the box. AppGallery's public metadata endpoint now requires a signed `interfaceCode` header that cannot be generated from a standalone client, so there is no reliable way to fetch the store version directly from the device.

The recommended pattern is to use the `ApiVersionSource` strategy and point it at a small backend you control. Your backend can call the official [AppGallery Connect Publishing API](https://developer.huawei.com/consumer/en/doc/AppGallery-connect-References/agcapi-app-info-query-0000001158245301) with your Client ID / Client Secret and return the version in response headers:

```dart
final newVersion = NewVersionPlus(
  versionSource: ApiVersionSource(
    apiUrl: Uri.parse('https://your-backend.example.com/app-version'),
  ),
);
```

Your backend responds with `x-latest-app-version`, `x-force-update`, `x-release-notes`, and `x-store-url` (pointing to `https://appgallery.huawei.com/app/C<id>`). This keeps Huawei credentials off the device and lets the same strategy serve Google Play, App Store, and AppGallery from one place.
