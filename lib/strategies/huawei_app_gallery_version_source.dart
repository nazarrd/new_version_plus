import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:new_version_plus/model/version_status.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'version_source.dart';

/// Queries Huawei AppGallery's public endpoint to obtain the store version.
///
/// AppGallery exposes each app under a numeric id prefixed with `C`
/// (e.g. `https://appgallery.huawei.com/app/C100000000`). Pass the numeric
/// portion as [appGalleryId] — without the leading `C`.
class HuaweiAppGalleryVersionSource implements VersionSource {
  /// Numeric AppGallery app id, without the leading "C".
  /// Find it in the AppGallery URL: `/app/C<id>`.
  final String appGalleryId;

  /// Locale string (e.g. `en_US`, `zh_CN`). Controls which localized
  /// metadata AppGallery returns.
  final String locale;

  /// Forces [storeVersion] to always resolve to this value. Useful for
  /// testing the update flow before publishing a new release.
  final String? forceAppVersion;

  HuaweiAppGalleryVersionSource({
    required this.appGalleryId,
    this.locale = 'en_US',
    this.forceAppVersion,
  });

  @override
  Future<VersionStatus?> checkVersion(PackageInfo packageInfo) async {
    final uri = Uri.https(
      'web-drcn.hispace.dbankcloud.com',
      '/uowap/index',
      {
        'method': 'internal.getTabDetail',
        'serviceType': '20',
        'reqPageNum': '1',
        'uri': 'app|C$appGalleryId',
        'maxResults': '25',
        'locale': locale,
      },
    );

    http.Response response;
    try {
      response = await http.get(uri);
    } catch (e) {
      debugPrint('Failed to query Huawei AppGallery\n$e');
      return null;
    }

    if (response.statusCode != 200) {
      debugPrint('Failed to query Huawei AppGallery: ${response.statusCode}');
      return null;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to parse Huawei AppGallery response\n$e');
      return null;
    }

    final app = _extractApp(decoded);
    if (app == null) {
      debugPrint("Can't find an app in AppGallery with the id: C$appGalleryId");
      return null;
    }

    final rawStoreVersion = forceAppVersion ?? app['versionName'] as String?;
    if (rawStoreVersion == null || rawStoreVersion.isEmpty) {
      debugPrint('AppGallery response missing versionName for C$appGalleryId');
      return null;
    }

    return VersionStatus(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(rawStoreVersion),
      originalStoreVersion: rawStoreVersion,
      appStoreLink: 'https://appgallery.huawei.com/app/C$appGalleryId',
      releaseNotes: app['newFeatures'] as String?,
    );
  }

  /// AppGallery nests the app payload under `layoutData[i].dataList[0]`.
  /// The index varies by section, so walk until we find one with a version.
  Map<String, dynamic>? _extractApp(Map<String, dynamic> json) {
    final layoutData = json['layoutData'];
    if (layoutData is! List) return null;
    for (final section in layoutData) {
      if (section is! Map) continue;
      final dataList = section['dataList'];
      if (dataList is! List || dataList.isEmpty) continue;
      final first = dataList.first;
      if (first is Map<String, dynamic> && first['versionName'] is String) {
        return first;
      }
    }
    return null;
  }

  String _getCleanVersion(String version) =>
      RegExp(r'\d+(\.\d+)?(\.\d+)?').stringMatch(version) ?? '0.0.0';
}
