import 'dart:async';
import 'dart:io';

class ScanEngine {
  final String targetInput;
  final String module;
  final int maxThreads;
  final Duration timeout;
  final bool enableBannerGrabbing;

  // Callbacks to communicate status back to UI
  final Function(String timestamp, String type, String msg) onLog;
  final Function(String ip, String label, bool isUp) onHostDiscovered;
  final Function(String ip, int port, String protocol, String state, String service, String version, String vulnScore, String vulnLevel) onPortDiscovered;
  final Function(double progress) onProgress;
  final Function() onFinished;

  bool _isAborted = false;
  bool get isAborted => _isAborted;

  ScanEngine({
    required this.targetInput,
    required this.module,
    required this.maxThreads,
    required this.timeout,
    required this.enableBannerGrabbing,
    required this.onLog,
    required this.onHostDiscovered,
    required this.onPortDiscovered,
    required this.onProgress,
    required this.onFinished,
  });

  void abort() {
    _isAborted = true;
    _log('WARN', 'Scan abort requested by host controller.');
  }

  void _log(String type, String msg) {
    final timestamp = DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8);
    onLog(timestamp, type, msg);
  }

  // Starts the scanning process
  Future<void> run() async {
    try {
      _log('INFO', 'Resolving target scope...');
      List<String> ipList = await _resolveTargets(targetInput);
      if (ipList.isEmpty) {
        _log('WARN', 'No valid targets resolved. Scan terminated.');
        onFinished();
        return;
      }

      _log('INFO', 'Resolved ${ipList.length} IP target address(es).');

      // 1. Host Discovery (TCP Ping)
      _log('INFO', 'Starting host discovery sweep...');
      List<String> activeHosts = [];
      int completedHosts = 0;

      await _runInPool(
        tasks: ipList,
        worker: (ip) async {
          if (_isAborted) return;
          _log('INFO', 'Sweeping target: $ip');
          bool isUp = await _pingHost(ip);
          completedHosts++;
          onProgress((completedHosts / ipList.length) * 30.0); // Host discovery occupies first 30% of progress

          if (isUp) {
            _log('COMM', 'Host responds active: $ip');
            activeHosts.add(ip);
            onHostDiscovered(ip, 'ACTIVE_NODE', true);
          } else {
            // For single target, still show it as unreachable
            if (ipList.length == 1) {
              onHostDiscovered(ip, 'UNREACHABLE', false);
            }
          }
        },
      );

      if (_isAborted) {
        onFinished();
        return;
      }

      _log('INFO', 'Host discovery complete. Active hosts: ${activeHosts.length}');
      if (activeHosts.isEmpty) {
        _log('WARN', 'No active hosts discovered. Terminating.');
        onProgress(100.0);
        onFinished();
        return;
      }

      // 2. Port Scanning
      List<int> portsToScan = _getPortsForModule();
      _log('INFO', 'Starting TCP port scan on active hosts (${portsToScan.length} ports per host)...');

      int totalPortTasks = activeHosts.length * portsToScan.length;
      int completedPortTasks = 0;

      List<Map<String, dynamic>> scanTasks = [];
      for (var ip in activeHosts) {
        for (var port in portsToScan) {
          scanTasks.add({'ip': ip, 'port': port});
        }
      }

      await _runInPool(
        tasks: scanTasks,
        worker: (task) async {
          if (_isAborted) return;
          final String ip = task['ip'];
          final int port = task['port'];

          _log('INFO', 'Probing target: $ip:$port');
          await _scanPort(ip, port);

          completedPortTasks++;
          onProgress(30.0 + (completedPortTasks / totalPortTasks) * 70.0); // Port scan occupies 70% of progress
        },
      );

      onProgress(100.0);
      _log('INFO', 'Port scanning complete.');
      onFinished();
    } catch (e) {
      _log('WARN', 'Scan engine error: $e');
      onFinished();
    }
  }

  // Runs tasks concurrently in a thread pool using maxThreads limit
  Future<void> _runInPool<T>({
    required List<T> tasks,
    required Future<void> Function(T task) worker,
  }) async {
    final int poolSize = maxThreads > tasks.length ? tasks.length : maxThreads;
    if (poolSize == 0) return;

    int nextTaskIndex = 0;
    final completer = Completer<void>();

    Future<void> runWorker() async {
      while (true) {
        if (_isAborted) break;
        if (nextTaskIndex >= tasks.length) {
          break;
        }
        int currentTaskIndex = nextTaskIndex++;
        if (currentTaskIndex >= tasks.length) {
          break;
        }

        try {
          await worker(tasks[currentTaskIndex]);
        } catch (e) {
          // Ignore task execution errors to prevent pool crash
        }
      }
    }

    final workers = List.generate(poolSize, (_) => runWorker());
    await Future.wait(workers);
  }

  // Resolve target strings into IP address list
  Future<List<String>> _resolveTargets(String target) async {
    List<String> list = [];
    try {
      target = target.trim();
      if (target.contains('/')) {
        // Subnet CIDR (e.g. 192.168.1.0/24)
        final parts = target.split('/');
        final baseIp = parts[0];
        final prefix = int.tryParse(parts[1]) ?? 24;

        if (prefix >= 24 && prefix <= 32) {
          final ipParts = baseIp.split('.').map(int.parse).toList();
          final count = 1 << (32 - prefix);
          final baseValue = (ipParts[0] << 24) + (ipParts[1] << 16) + (ipParts[2] << 8) + ipParts[3];

          for (int i = 0; i < count; i++) {
            final val = baseValue + i;
            final ip = '${(val >> 24) & 255}.${(val >> 16) & 255}.${(val >> 8) & 255}.${val & 255}';
            list.add(ip);
          }
        }
      } else if (target.contains('-')) {
        // Range (e.g. 192.168.1.10-192.168.1.20)
        final parts = target.split('-');
        final startIp = parts[0].trim();
        final endIp = parts[1].trim();

        final startParts = startIp.split('.').map(int.parse).toList();
        final endParts = endIp.split('.').map(int.parse).toList();

        final startVal = (startParts[0] << 24) + (startParts[1] << 16) + (startParts[2] << 8) + startParts[3];
        final endVal = (endParts[0] << 24) + (endParts[1] << 16) + (endParts[2] << 8) + endParts[3];

        if (endVal >= startVal && (endVal - startVal) <= 256) {
          for (int val = startVal; val <= endVal; val++) {
            final ip = '${(val >> 24) & 255}.${(val >> 16) & 255}.${(val >> 8) & 255}.${val & 255}';
            list.add(ip);
          }
        }
      } else {
        // Single IP or Domain
        final address = Uri.parse('http://$target').host;
        final resolved = await InternetAddress.lookup(address.isNotEmpty ? address : target);
        for (var addr in resolved) {
          if (addr.type == InternetAddressType.IPv4) {
            list.add(addr.address);
          }
        }
      }
    } catch (_) {
      // Return empty if parsing failed
    }
    return list;
  }

  // Ping host using TCP Connect Ping to common ports
  Future<bool> _pingHost(String ip) async {
    final commonPorts = [80, 443, 22, 445, 139, 3389];
    for (final port in commonPorts) {
      if (_isAborted) return false;
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 300));
        socket.destroy();
        return true;
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 1225 || e.osError?.errorCode == 61 || e.message.contains('Connection refused')) {
          return true; // Connection refused means host is up
        }
      } catch (_) {}
    }
    return false;
  }

  // Scans a specific port, performs banner grabbing if open, and reports back
  Future<void> _scanPort(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      // Socket opened successfully!
      String service = _guessService(port);
      String version = 'UNKNOWN';
      String vulnScore = 'N/A';
      String vulnLevel = 'LOW';

      if (enableBannerGrabbing) {
        final grab = await _grabBanner(socket, port);
        if (grab.isNotEmpty) {
          version = grab;
          // Simple mock CVE mapping for aesthetics
          if (grab.toLowerCase().contains('openssh 8.') || grab.toLowerCase().contains('nginx/1.18')) {
            vulnScore = '7.5';
            vulnLevel = 'HIGH';
          } else if (grab.toLowerCase().contains('apache/2.4')) {
            vulnScore = '5.3';
            vulnLevel = 'MEDIUM';
          }
        }
      } else {
        socket.destroy();
      }

      _log('COMM', 'Open port detected: $ip:$port ($service)');
      onPortDiscovered(ip, port, 'TCP', 'open', service, version, vulnScore, vulnLevel);
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 1225 || e.osError?.errorCode == 61 || e.message.contains('Connection refused')) {
        // Port is closed, but host responded. We report it as closed (or we don't display closed ports, but we can pass it if we want to log it)
        // Usually we only display OPEN ports in the results table.
      }
    } catch (_) {
      // Timeout or error
    }
  }

  // Asynchronously grab banner
  Future<String> _grabBanner(Socket socket, int port) async {
    try {
      // Send standard probe if needed
      if (port == 80 || port == 8080 || port == 443) {
        socket.write('HEAD / HTTP/1.0\r\n\r\n');
      }

      final completer = Completer<String>();
      final timer = Timer(const Duration(milliseconds: 800), () {
        if (!completer.isCompleted) {
          socket.destroy();
          completer.complete('');
        }
      });

      socket.listen(
        (data) {
          if (completer.isCompleted) return;
          timer.cancel();
          final response = String.fromCharCodes(data).trim();
          socket.destroy();

          if (port == 80 || port == 8080 || port == 443) {
            // Extract Server header
            final lines = response.split('\n');
            for (var line in lines) {
              if (line.toLowerCase().startsWith('server:')) {
                completer.complete(line.substring(7).trim());
                return;
              }
            }
          }
          // Default: send first line of greeting
          final firstLine = response.split('\n')[0].trim();
          completer.complete(firstLine.length > 50 ? firstLine.substring(0, 50) : firstLine);
        },
        onError: (_) {
          timer.cancel();
          socket.destroy();
          if (!completer.isCompleted) completer.complete('');
        },
        onDone: () {
          timer.cancel();
          socket.destroy();
          if (!completer.isCompleted) completer.complete('');
        },
        cancelOnError: true,
      );

      return await completer.future;
    } catch (_) {
      socket.destroy();
      return '';
    }
  }

  // Get list of ports depending on selected module
  List<int> _getPortsForModule() {
    if (module == 'common') {
      // Top 20 common ports
      return [21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 8080, 8443];
    } else if (module == 'service') {
      // Ports that usually have banners
      return [21, 22, 23, 25, 80, 110, 143, 443, 445, 1433, 1521, 3306, 3389, 5432, 8080, 8081];
    } else {
      // Full Scan: Top 100 ports
      return [
        7, 9, 13, 21, 22, 23, 25, 37, 53, 79, 80, 88, 106, 110, 111, 113, 119, 135, 139, 143, 179, 199, 389, 443, 445,
        465, 513, 514, 515, 540, 548, 554, 587, 631, 636, 873, 902, 990, 993, 995, 1025, 1026, 1027, 1028, 1029, 1110,
        1433, 1521, 1720, 1723, 2000, 2049, 2121, 3000, 3128, 3306, 3389, 3986, 4899, 5000, 5051, 5060, 5101, 5432,
        5631, 5800, 5900, 6000, 6001, 6667, 7000, 7070, 8000, 8008, 8009, 8080, 8081, 8443, 8888, 9090, 9100, 9999,
        10000, 32768, 49152, 49153, 49154, 49155, 49156, 49157
      ];
    }
  }

  String _guessService(int port) {
    switch (port) {
      case 21: return 'ftp';
      case 22: return 'ssh';
      case 23: return 'telnet';
      case 25: return 'smtp';
      case 53: return 'dns';
      case 80: case 8080: case 8081: case 8008: return 'http';
      case 110: return 'pop3';
      case 135: return 'msrpc';
      case 139: return 'netbios-ssn';
      case 143: return 'imap';
      case 443: case 8443: return 'https';
      case 445: return 'microsoft-ds';
      case 993: return 'imaps';
      case 995: return 'pop3s';
      case 1433: return 'ms-sql-s';
      case 1521: return 'oracle';
      case 3306: return 'mysql';
      case 3389: return 'ms-wbt-server';
      case 5432: return 'postgresql';
      case 5900: return 'vnc';
      default: return 'unknown';
    }
  }
}
