import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Manually bumped alongside pubspec.yaml / setup.iss / CHANGELOG.md on each release.
const String kAppVersion = '2.15.0';

const String _kRepoOwner = 'BigDesigner';
const String _kRepoName = 'gnncyber-netscan';

class UpdateService {
  // Queries the GitHub Releases API for the latest published release and compares
  // it against [kAppVersion]. Only runs when explicitly invoked by the user
  // (Check for Updates button) to preserve fully-offline/air-gapped operation by default.
  static Future<Map<String, dynamic>> checkForUpdates() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    client.userAgent = 'GNNcyber-NETscan-UpdateChecker';
    try {
      final uri = Uri.parse('https://api.github.com/repos/$_kRepoOwner/$_kRepoName/releases/latest');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'GNNcyber-NETscan-UpdateChecker');
      final response = await request.close().timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        await response.drain();
        return {
          'updateAvailable': false,
          'currentVersion': kAppVersion,
          'error': 'GitHub API returned status ${response.statusCode}.',
        };
      }

      final body = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(body);

      final String rawTag = (data['tag_name'] ?? '').toString();
      final String latestVersion = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;

      if (latestVersion.isEmpty) {
        return {
          'updateAvailable': false,
          'currentVersion': kAppVersion,
          'error': 'Could not parse the latest release version.',
        };
      }

      final String assetName = Platform.isWindows
          ? 'GNNcyber_NETscan_Setup.exe'
          : Platform.isMacOS
              ? 'GNNcyber_NETscan_macOS.zip'
              : '';

      String? downloadUrl;
      final assets = data['assets'];
      if (assetName.isNotEmpty && assets is List) {
        for (final asset in assets) {
          if (asset is Map && asset['name'] == assetName) {
            downloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      final bool isNewer = _isVersionNewer(latestVersion, kAppVersion);

      if (isNewer && downloadUrl == null) {
        return {
          'updateAvailable': false,
          'currentVersion': kAppVersion,
          'latestVersion': latestVersion,
          'error': 'Version $latestVersion is available but no installer asset was found for this platform.',
        };
      }

      return {
        'updateAvailable': isNewer,
        'currentVersion': kAppVersion,
        'latestVersion': latestVersion,
        'downloadUrl': downloadUrl,
      };
    } catch (_) {
      return {
        'updateAvailable': false,
        'currentVersion': kAppVersion,
        'error': 'Network error: could not reach GitHub.',
      };
    } finally {
      client.close();
    }
  }

  // Returns true if [latest] is a strictly greater dot-separated version than [current].
  static bool _isVersionNewer(String latest, String current) {
    List<int> parse(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final latestParts = parse(latest);
    final currentParts = parse(current);
    final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

    for (int i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l != c) return l > c;
    }
    return false;
  }

  // SECURITY: Whitelist URL validation to prevent Remote Code Execution (RCE) / Arbitrary File Download
  static bool isValidUpdateUrl(String downloadUrl) {
    try {
      final uri = Uri.parse(downloadUrl);
      if (uri.scheme != 'https' || uri.host.toLowerCase() != 'github.com') {
        return false;
      }
      final expectedPathPrefix = '/$_kRepoOwner/$_kRepoName/releases/download/';
      if (!uri.path.startsWith(expectedPathPrefix)) {
        return false;
      }
      final expectedExt = Platform.isWindows ? '.exe' : Platform.isMacOS ? '.zip' : '';
      if (expectedExt.isNotEmpty && !uri.path.toLowerCase().endsWith(expectedExt)) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Downloads the installer asset to a temp file, reporting progress via [onProgress] (0-100).
  // On Windows the installer is launched directly and this process then exits so the
  // installer can overwrite files currently held open by the running app.
  // On macOS the archive is extracted and revealed in Finder for manual drag-to-Applications.
  static Future<Map<String, dynamic>> downloadAndInstall(
    String downloadUrl, {
    required void Function(double) onProgress,
  }) async {
    if (!isValidUpdateUrl(downloadUrl)) {
      return {
        'success': false,
        'error': 'Security Exception: Invalid or untrusted update download URL.',
      };
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse(downloadUrl);
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        await response.drain();
        return {'success': false, 'error': 'Download failed with status ${response.statusCode}.'};
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'netscan_update';
      final filePath = '${tempDir.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      final sink = file.openWrite();

      final total = response.contentLength;
      int received = 0;

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress((received / total) * 100.0);
        }
      }
      await sink.flush();
      await sink.close();
      onProgress(100.0);

      if (Platform.isWindows) {
        await Process.start(filePath, [], mode: ProcessStartMode.detached);
        // Give the installer a moment to spawn before this instance exits,
        // since it needs to overwrite files currently held open by this process.
        Future.delayed(const Duration(milliseconds: 800), () => exit(0));
        return {'success': true};
      } else if (Platform.isMacOS) {
        final extractDir = '${tempDir.path}${Platform.pathSeparator}netscan_update_extracted';
        await Process.run('unzip', ['-o', filePath, '-d', extractDir]);
        await Process.run('open', [extractDir]);
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Automatic installation is not supported on this platform.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Update failed: $e'};
    } finally {
      client.close();
    }
  }
}
