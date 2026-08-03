import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'history_db.dart';
import 'database_helper.dart';
import 'scan_engine.dart';
import 'update_service.dart';
import 'network_interface_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().init();
  runApp(const NetscanApp());
}

class NetscanApp extends StatelessWidget {
  const NetscanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GNNcyber - NETscan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  HttpServer? _server;
  int _port = 0;
  InAppWebViewController? _webViewController;
  ScanEngine? _activeScanEngine;
  DateTime? _scanStartTime;
  WebViewEnvironment? _webViewEnvironment;
  bool _envInitDone = false;
  bool _scanWasAborted = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _initWebViewEnvironment();
    await _startLocalServer();
  }

  Future<void> _initWebViewEnvironment() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final availableVersion = await WebViewEnvironment.getAvailableVersion();
        if (availableVersion != null) {
          final appSupportDir = await getApplicationSupportDirectory();
          final userDataPath = '${appSupportDir.path}${Platform.pathSeparator}WebView2Data';
          _webViewEnvironment = await WebViewEnvironment.create(
            settings: WebViewEnvironmentSettings(
              userDataFolder: userDataPath,
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to initialize WebViewEnvironment: $e');
      }
    }
    if (mounted) {
      setState(() {
        _envInitDone = true;
      });
    }
  }

  @override
  void dispose() {
    _activeScanEngine?.abort();
    _server?.close(force: true);
    super.dispose();
  }

  // Starts a local HTTP server on an available loopback port to serve index.html
  Future<void> _startLocalServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      setState(() {
        _port = _server!.port;
      });

      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        
        String assetPath = '';
        if (path == '/' || path == '/index.html') {
          assetPath = 'assets/web/index.html';
        } else {
          final cleanPath = path.startsWith('/') ? path.substring(1) : path;
          bool hasWebAsset = false;
          try {
            await rootBundle.load('assets/web/$cleanPath');
            hasWebAsset = true;
          } catch (_) {
            hasWebAsset = false;
          }
          assetPath = hasWebAsset ? 'assets/web/$cleanPath' : 'assets/$cleanPath';
        }

        try {
          final ByteData data = await rootBundle.load(assetPath);
          final buffer = data.buffer.asUint8List();
          
          if (assetPath.endsWith('.html')) {
            request.response.headers.contentType = ContentType.html;
          } else if (assetPath.endsWith('.png')) {
            request.response.headers.contentType = ContentType.parse('image/png');
          } else if (assetPath.endsWith('.jpg') || assetPath.endsWith('.jpeg')) {
            request.response.headers.contentType = ContentType.parse('image/jpeg');
          } else if (assetPath.endsWith('.ico')) {
            request.response.headers.contentType = ContentType.parse('image/x-icon');
          } else if (assetPath.endsWith('.css')) {
            request.response.headers.contentType = ContentType.parse('text/css');
          } else if (assetPath.endsWith('.js')) {
            request.response.headers.contentType = ContentType.parse('application/javascript');
          } else if (assetPath.endsWith('.ttf')) {
            request.response.headers.contentType = ContentType.parse('font/ttf');
          }

          request.response.add(buffer);
        } catch (e) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Asset not found: $e');
        }
        await request.response.close();
      });
    } catch (e) {
      debugPrint('Failed to start local server: $e');
    }
  }

  // Helper to run JS on the webview controller
  void _runJavaScript(String jsCode) {
    _webViewController?.evaluateJavascript(source: jsCode);
  }

  @override
  Widget build(BuildContext context) {
    if (_port == 0 || (!kIsWeb && Platform.isWindows && !_envInitDone)) {
      return const Scaffold(
        backgroundColor: Color(0xFF131314),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
          ),
        ),
      );
    }

    final initialUrl = WebUri("http://127.0.0.1:$_port/index.html");

    return Scaffold(
      backgroundColor: const Color(0xFF131314),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: initialUrl),
          webViewEnvironment: _webViewEnvironment,
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useOnLoadResource: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _setupJavaScriptHandlers(controller);
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("WEBVIEW CONSOLE: ${consoleMessage.message}");
          },
        ),
      ),
    );
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // 1. startScan
    controller.addJavaScriptHandler(
      handlerName: 'startScan',
      callback: (args) async {
        final data = args[0] as Map<String, dynamic>;
        final target = data['target'] as String;
        final module = data['module'] as String;
        final customPorts = data['customPorts'] as String?;
        final stealthLevel = data['stealthLevel'] as String? ?? 'T5';

        final settings = await HistoryDb.loadSettings();
        final maxThreads = settings['maxThreads'] as int? ?? 64;
        final timeoutMs = settings['timeoutMs'] as int? ?? 500;
        final enableBanner = settings['bannerGrabbing'] as bool? ?? true;
        final enableOnlineVendorLookup = settings['enableOnlineVendorLookup'] as bool? ?? false;

        _scanStartTime = DateTime.now();

        // Temporary data holders to construct final history record
        final Map<String, Map<String, dynamic>> discoveredHostsData = {};
        int findingsCount = 0;

        _activeScanEngine = ScanEngine(
          targetInput: target,
          module: module,
          customPorts: customPorts,
          maxThreads: maxThreads,
          timeout: Duration(milliseconds: timeoutMs),
          enableBannerGrabbing: enableBanner,
          enableOnlineVendorLookup: enableOnlineVendorLookup,
          stealthLevel: stealthLevel,
          onLog: (timestamp, type, msg) {
            _runJavaScript("window.netscan.onLogReceived(${jsonEncode(timestamp)}, ${jsonEncode(type)}, ${jsonEncode(msg)})");
          },
          onHostDiscovered: (ip, label, isUp, mac, vendor, os, hostname) {
            discoveredHostsData[ip] = {
              'ip': ip,
              'label': label,
              'isUp': isUp,
              'mac': mac,
              'vendor': vendor,
              'os': os,
              'hostname': hostname,
              'ports': []
            };
            _runJavaScript("window.netscan.onHostDiscovered(${jsonEncode(ip)}, ${jsonEncode(label)}, $isUp, ${jsonEncode(mac)}, ${jsonEncode(vendor)}, ${jsonEncode(os)}, ${jsonEncode(hostname)})");
          },
          onPortDiscovered: (ip, port, protocol, state, service, version, vulnScore, vulnLevel) {
            findingsCount++;
            if (discoveredHostsData[ip] != null) {
              final portsList = discoveredHostsData[ip]!['ports'] as List<dynamic>;
              portsList.add({
                'port': port,
                'protocol': protocol,
                'state': state,
                'service': service,
                'version': version,
                'vulnScore': vulnScore,
                'vulnLevel': vulnLevel
              });
            }
            _runJavaScript(
              "window.netscan.onPortDiscovered(${jsonEncode(ip)}, $port, ${jsonEncode(protocol)}, ${jsonEncode(state)}, ${jsonEncode(service)}, ${jsonEncode(version)}, ${jsonEncode(vulnScore)}, ${jsonEncode(vulnLevel)})"
            );
          },
          onProgress: (progress) {
            _runJavaScript("window.netscan.onProgressUpdate($progress)");
          },
          onFinished: () async {
            final durationMs = DateTime.now().difference(_scanStartTime!).inMilliseconds;
            
            // Build history item
            final historyItem = {
              'id': DateTime.now().microsecondsSinceEpoch.toString(),
              'target': target,
              'module': module,
              'timestamp': DateTime.now().toLocal().toString().substring(0, 19),
              'durationMs': durationMs,
              'findingsCount': findingsCount,
              'status': _scanWasAborted ? 'ABORTED' : 'COMPLETED',
              'resultData': discoveredHostsData,
              'scanHost': Platform.localHostname
            };

            await HistoryDb.saveHistoryItem(historyItem);

            _runJavaScript("window.netscan.onScanFinished()");
            _activeScanEngine = null;
            _scanWasAborted = false;
          },
        );

        // Run engine in background
        _activeScanEngine!.run();
        return true;
      },
    );

    // 2. stopScan
    controller.addJavaScriptHandler(
      handlerName: 'stopScan',
      callback: (args) {
        _scanWasAborted = true;
        _activeScanEngine?.abort();
        return true;
      },
    );

    // 3. loadSettings
    controller.addJavaScriptHandler(
      handlerName: 'loadSettings',
      callback: (args) async {
        final settings = await HistoryDb.loadSettings();
        settings['hostname'] = Platform.localHostname;
        settings['appVersion'] = kAppVersion;
        settings['systemBrightness'] =
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? 'dark' : 'light';
        try {
          final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
          if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
            settings['localIp'] = interfaces.first.addresses.first.address;
          }
        } catch (_) {}
        return settings;
      },
    );

    // 4. saveSettings
    controller.addJavaScriptHandler(
      handlerName: 'saveSettings',
      callback: (args) async {
        final settings = args[0] as Map<String, dynamic>;
        return await HistoryDb.saveSettings(settings);
      },
    );

    // 5. loadHistory
    controller.addJavaScriptHandler(
      handlerName: 'loadHistory',
      callback: (args) async {
        return await HistoryDb.loadHistory();
      },
    );

    // 6. clearHistory
    controller.addJavaScriptHandler(
      handlerName: 'clearHistory',
      callback: (args) async {
        await HistoryDb.clearHistory();
        return true;
      },
    );

    // 7. saveLogs (Saves terminal logs to text file)
    controller.addJavaScriptHandler(
      handlerName: 'saveLogs',
      callback: (args) async {
        try {
          final logsText = args[0] as String;
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/netscan_terminal_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
          await file.writeAsString(logsText);
          return file.path;
        } catch (e) {
          return null;
        }
      },
    );

    // 8. exportHistory (Exports history to CSV or JSON file)
    controller.addJavaScriptHandler(
      handlerName: 'exportHistory',
      callback: (args) async {
        try {
          final format = args[0] as String;
          final history = await HistoryDb.loadHistory();
          final directory = await getApplicationDocumentsDirectory();
          
          if (format == 'json') {
            final file = File('${directory.path}/netscan_export_${DateTime.now().millisecondsSinceEpoch}.json');
            await file.writeAsString(jsonEncode(history), flush: true);
            return file.path;
          } else if (format == 'pdf') {
            final pdfDoc = pw.Document();
            pdfDoc.addPage(
              pw.MultiPage(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                  return [
                    pw.Header(
                      level: 0,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('GNNcyber - NETscan', style: pw.TextStyle(color: PdfColors.blueGrey800, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Global History Report', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 14)),
                        ]
                      )
                    ),
                    pw.SizedBox(height: 20),
                    pw.TableHelper.fromTextArray(
                      context: context,
                      headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                      cellAlignment: pw.Alignment.centerLeft,
                      columnWidths: const {
                        0: pw.FlexColumnWidth(1.2),
                        1: pw.FlexColumnWidth(2.0),
                        2: pw.FlexColumnWidth(1.2),
                        3: pw.FlexColumnWidth(1.5),
                        4: pw.FlexColumnWidth(1.0),
                      },
                      headers: ['Date', 'Target', 'Module', 'Active Hosts / Ports', 'Status'],
                      data: history.map((item) {
                        return [
                          item['timestamp'] ?? '',
                          item['target'] ?? '',
                          item['module'] ?? '',
                          '${item['findingsCount'] ?? 0} found',
                          item['status'] ?? ''
                        ];
                      }).toList(),
                    ),
                  ];
                },
              ),
            );
            final file = File('${directory.path}/GNNcyber_History_${DateTime.now().millisecondsSinceEpoch}.pdf');
            await file.writeAsBytes(await pdfDoc.save(), flush: true);
            return file.path;
          } else {
            // CSV
            final file = File('${directory.path}/netscan_export_${DateTime.now().millisecondsSinceEpoch}.csv');
            final csvBuffer = StringBuffer();
            csvBuffer.writeln('Target,Module,Timestamp,DurationMs,FindingsCount,Status,OperatorHost');
            for (var item in history) {
              final scanHost = item['scanHost'] ?? 'UNKNOWN';
              csvBuffer.writeln('${item['target']},${item['module']},${item['timestamp']},${item['durationMs']},${item['findingsCount']},${item['status']},$scanHost');
            }
            await file.writeAsString(csvBuffer.toString(), flush: true);
            return file.path;
          }
        } catch (e) {
          return null;
        }
      },
    );

    // 9. openExternalUrl (Opens a URL in the system's default browser)
    controller.addJavaScriptHandler(
      handlerName: 'openExternalUrl',
      callback: (args) async {
        try {
          final urlString = args[0] as String;
          if (Platform.isWindows) {
            await Process.run('cmd', ['/c', 'start', '', urlString]);
          } else if (Platform.isMacOS) {
            await Process.run('open', [urlString]);
          } else if (Platform.isLinux) {
            await Process.run('xdg-open', [urlString]);
          }
          return true;
        } catch (_) {
          return false;
        }
      },
    );

    // 10. saveExportFile (Saves single scan details export files to Documents directory)
    controller.addJavaScriptHandler(
      handlerName: 'saveExportFile',
      callback: (args) async {
        try {
          final fileName = args[0] as String;
          final content = args[1] as String;
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(content, flush: true);
          return file.path;
        } catch (_) {
          return null;
        }
      },
    );

    // 11. exportSingleScanPdf (Generates professional PDF for a single scan)
    controller.addJavaScriptHandler(
      handlerName: 'exportSingleScanPdf',
      callback: (args) async {
        try {
          final scanData = jsonDecode(args[0] as String);
          final String target = scanData['target'] ?? 'Unknown';
          final String timestamp = scanData['timestamp'] ?? 'Unknown';
          final resultData = scanData['resultData'] ?? {};
          
          final pdfDoc = pw.Document();
          pdfDoc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4.landscape,
              build: (pw.Context context) {
                
                List<List<String>> tableData = [];
                for (var ip in resultData.keys) {
                  final host = resultData[ip];
                  final ports = host['ports'] as List? ?? [];
                  if (ports.isEmpty) {
                    tableData.add([
                      host['ip'], 
                      (host['hostname'] != null && host['hostname'] != 'UNKNOWN' && host['hostname'] != '') ? host['hostname'] : (host['label'] ?? ''), 
                      host['os'] ?? '', 
                      host['mac'] ?? '', 
                      'No Open Ports', '', '', ''
                    ]);
                  } else {
                    for (var p in ports) {
                      tableData.add([
                        host['ip'], 
                        (host['hostname'] != null && host['hostname'] != 'UNKNOWN' && host['hostname'] != '') ? host['hostname'] : (host['label'] ?? ''), 
                        host['os'] ?? '', 
                        host['mac'] ?? '', 
                        '${p['port']}/${p['protocol']}', 
                        p['service'] ?? '', 
                        p['version'] ?? '', 
                        p['vulnLevel'] ?? ''
                      ]);
                    }
                  }
                }

                return [
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('GNNcyber - NETscan', style: pw.TextStyle(color: PdfColors.blueGrey800, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Detailed Scan Report', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 14)),
                      ]
                    )
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Target: $target', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: $timestamp', style: pw.TextStyle(fontSize: 12)),
                    ]
                  ),
                  pw.SizedBox(height: 20),
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.2),
                      1: pw.FlexColumnWidth(1.2),
                      2: pw.FlexColumnWidth(1.0),
                      3: pw.FlexColumnWidth(1.3),
                      4: pw.FlexColumnWidth(0.8),
                      5: pw.FlexColumnWidth(1.0),
                      6: pw.FlexColumnWidth(2.5),
                      7: pw.FlexColumnWidth(0.8),
                    },
                    headers: ['IP Address', 'Hostname', 'OS', 'MAC', 'Port', 'Service', 'Version', 'Vuln Level'],
                    data: tableData,
                  ),
                ];
              },
            ),
          );
          
          final directory = await getApplicationDocumentsDirectory();
          final cleanTarget = target.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
          final cleanTime = timestamp.replaceAll(RegExp(r'[^0-9]'), '_');
          final file = File('${directory.path}/GNNcyber_NETscan_details_${cleanTarget}_$cleanTime.pdf');
          await file.writeAsBytes(await pdfDoc.save(), flush: true);
          return file.path;
        } catch (_) {
          return null;
        }
      },
    );

    // 12. checkForUpdates (Manually triggered — queries GitHub Releases API)
    controller.addJavaScriptHandler(
      handlerName: 'checkForUpdates',
      callback: (args) async {
        return await UpdateService.checkForUpdates();
      },
    );

    // 13. downloadAndInstallUpdate (Downloads the installer asset and launches it)
    controller.addJavaScriptHandler(
      handlerName: 'downloadAndInstallUpdate',
      callback: (args) async {
        final downloadUrl = args[0] as String;
        return await UpdateService.downloadAndInstall(
          downloadUrl,
          onProgress: (progress) {
            _runJavaScript("window.netscan.onUpdateDownloadProgress($progress)");
          },
        );
      },
    );

    // 14. getLocalInterfaces (Fetches local subnets via OS CLI/Dart and returns as safely encoded JSON array)
    controller.addJavaScriptHandler(
      handlerName: 'getLocalInterfaces',
      callback: (args) async {
        final interfaces = await NetworkInterfaceHelper.getLocalInterfaces();
        final List<Map<String, dynamic>> jsonList = interfaces.map((e) => e.toJson()).toList();
        // Return structured list to UI. The bridge handles JSON serialization securely.
        return jsonList;
      },
    );
  }
}
