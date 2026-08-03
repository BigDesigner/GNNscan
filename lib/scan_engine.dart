import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'database_helper.dart';

class ScanEngine {
  final String targetInput;
  final String module;
  final String? customPorts;
  final int maxThreads;
  final Duration timeout;
  final bool enableBannerGrabbing;
  final String stealthLevel;
  final bool enableOnlineVendorLookup;

  // Callbacks to communicate status back to UI
  final Function(String timestamp, String type, String msg) onLog;
  final Function(String ip, String label, bool isUp, String mac, String vendor, String os, String hostname) onHostDiscovered;
  final Function(String ip, int port, String protocol, String state, String service, String version, String vulnScore, String vulnLevel) onPortDiscovered;
  final Function(double progress) onProgress;
  final Function() onFinished;

  bool _isAborted = false;
  bool get isAborted => _isAborted;

  ScanEngine({
    required this.targetInput,
    required this.module,
    this.customPorts,
    required this.maxThreads,
    required this.timeout,
    required this.stealthLevel,
    required this.enableBannerGrabbing,
    required this.enableOnlineVendorLookup,
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
      _log('INFO', 'Initiating scan engine on host: ${Platform.localHostname}');
      _log('INFO', 'Resolving target scope...');
      List<String> ipList = await _resolveTargets(targetInput);
      if (ipList.isEmpty) {
        _log('WARN', 'No valid targets resolved. Scan terminated.');
        onFinished();
        return;
      }

      _log('INFO', 'Resolved ${ipList.length} IP target address(es).');

      // Fetch initial ARP table
      _log('INFO', 'Querying local network ARP mappings...');
      Map<String, String> arpTable = await _getArpTable();

      // 1. Host Discovery (TCP Ping & ARP Sweep)
      _log('INFO', 'Starting host discovery sweep...');
      List<String> activeHosts = [];
      int completedHosts = 0;

      await _runInPool(
        tasks: ipList,
        worker: (ip) async {
          if (_isAborted) return;
          _log('INFO', 'Sweeping target: $ip');
          
          bool isUp = false;
          // If already dynamic in ARP cache, it is up
          if (arpTable.containsKey(ip)) {
            isUp = true;
          } else if (ipList.length == 1) {
            // For single targets (especially external WAN IPs), we force 'up' state to ensure port scan runs regardless of ping block.
            _log('INFO', 'Single target detected. Forcing active state (Skipping Ping Drop).');
            isUp = true;
          } else {
            isUp = await _pingHost(ip);
          }
          
          completedHosts++;
          onProgress((completedHosts / ipList.length) * 30.0); // Host discovery occupies first 30% of progress

          if (isUp) {
            _log('COMM', 'Host responds active: $ip');
            activeHosts.add(ip);
            
            String mac = arpTable[ip] ?? 'N/A';
            // If this is the local machine, ARP won't have its own entry.
            // Detect local machine by checking all local network interfaces.
            if (mac == 'N/A') {
              mac = await _getLocalMacAddress(ip);
            }
            final vendor = mac != 'N/A' ? await _getMacVendor(mac) : 'UNKNOWN';
            final os = await _getOsFingerprint(ip);
            final hostname = await _resolveHostname(ip);
            
            onHostDiscovered(ip, 'ACTIVE_NODE', true, mac, vendor, os, hostname);
          } else {
            // For single target, still show it as unreachable
            if (ipList.length == 1) {
              onHostDiscovered(ip, 'UNREACHABLE', false, 'N/A', 'UNKNOWN', 'UNKNOWN', 'UNKNOWN');
            }
          }
        },
      );

      if (_isAborted) {
        onFinished();
        return;
      }

      // Update ARP table after sweep to capture stimulated ARP responses
      _log('INFO', 'Updating host resolution mappings via ARP cache...');
      arpTable = await _getArpTable();
      
      // Add any hosts that responded to ARP but were missed by TCP ping
      for (var ip in ipList) {
        if (!activeHosts.contains(ip) && arpTable.containsKey(ip)) {
          activeHosts.add(ip);
          _log('COMM', 'Host resolved from ARP cache: $ip');
          
          final mac = arpTable[ip]!;
          final vendor = await _getMacVendor(mac);
          final os = await _getOsFingerprint(ip);
          final hostname = await _resolveHostname(ip);
          onHostDiscovered(ip, 'ACTIVE_NODE', true, mac, vendor, os, hostname);
        }
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
      
      if (portsToScan.isEmpty) {
        _log('INFO', 'Host discovery only. Skipping port scan phase.');
        onProgress(100.0);
        onFinished();
        return;
      }

      _log('INFO', 'Starting TCP port scan on active hosts (${portsToScan.length} ports per host)...');

      int totalPortTasks = activeHosts.length * portsToScan.length;
      int completedPortTasks = 0;

      List<Map<String, dynamic>> scanTasks = [];
      for (var ip in activeHosts) {
        for (var port in portsToScan) {
          scanTasks.add({'ip': ip, 'port': port});
        }
      }
      scanTasks.shuffle();

      await _runInPool(
        tasks: scanTasks,
        worker: (task) async {
          if (_isAborted) return;
          final String ip = task['ip'];
          final int port = task['port'];

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
          
          int delayMs = 0;
          if (stealthLevel == 'T1') {
            delayMs = 500;
          } else if (stealthLevel == 'T2') {
            delayMs = 100;
          } else if (stealthLevel == 'T3') {
            delayMs = 10;
          }
          
          if (delayMs > 0) {
            await Future.delayed(Duration(milliseconds: delayMs));
          }
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
        } else {
          _log('ERROR', 'CIDR prefix /$prefix is out of supported range. Please use /24 to /32 (max 256 hosts).');
        }
      } else if (target.contains('-')) {
        // Range (e.g. 192.168.1.10-192.168.1.20 or 192.168.1.10-20)
        final parts = target.split('-');
        final startIp = parts[0].trim();
        var endIp = parts[1].trim();

        if (!endIp.contains('.')) {
          final lastDot = startIp.lastIndexOf('.');
          if (lastDot != -1) {
            endIp = startIp.substring(0, lastDot + 1) + endIp;
          }
        }

        final startParts = startIp.split('.').map(int.parse).toList();
        final endParts = endIp.split('.').map(int.parse).toList();

        final startVal = (startParts[0] << 24) + (startParts[1] << 16) + (startParts[2] << 8) + startParts[3];
        final endVal = (endParts[0] << 24) + (endParts[1] << 16) + (endParts[2] << 8) + endParts[3];

        if (endVal >= startVal && (endVal - startVal) <= 256) {
          for (int val = startVal; val <= endVal; val++) {
            final ip = '${(val >> 24) & 255}.${(val >> 16) & 255}.${(val >> 8) & 255}.${val & 255}';
            list.add(ip);
          }
        } else if (endVal < startVal) {
          _log('ERROR', 'Invalid IP range: end IP is smaller than start IP.');
        } else {
          _log('WARN', 'IP range exceeds 256 hosts limit. Please narrow the range.');
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

  // Ping host using Hybrid Engine (ICMP Echo fallback to TCP Connect)
  Future<bool> _pingHost(String ip) async {
    if (_isAborted) return false;

    // SECURITY: Strict IP validation to prevent OS command injection
    final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$|^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
    if (!ipRegex.hasMatch(ip)) {
      _log('WARN', 'Invalid IP format detected: $ip. Skipping ping.');
      return false;
    }

    // Stage 2: OS ICMP Ping
    try {
      final args = Platform.isWindows ? ['-n', '1', '-w', '400', ip] : ['-c', '1', '-W', '1', ip];
      final result = await Process.run('ping', args);
      if (result.exitCode == 0) {
        _log('COMM', '[INFO] ICMP Echo Ping active for $ip');
        return true;
      }
    } catch (e) {
      // Ignored
    }

    if (_isAborted) return false;
    _log('COMM', '[INFO] Fallback to TCP Connect Ping for $ip');

    // Stage 3: TCP Connect Fallback
    final commonPorts = [80, 443, 22, 445, 139, 3389];
    for (final port in commonPorts) {
      if (_isAborted) return false;
      try {
        final socket = await Socket.connect(ip, port, timeout: timeout);
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
          
          // Parse service and version from banner for CVE check
          final words = grab.split(' ');
          String parsedService = service;
          String parsedVersion = '';
          
          if (words.length > 1 && RegExp(r'\d+\.\d+').hasMatch(words[1])) {
            parsedService = words[0].toLowerCase();
            parsedVersion = RegExp(r'\d+\.\d+(\.\d+[a-z]?)?').stringMatch(words[1]) ?? '';
          } else if (words.length == 1 && grab.contains('/')) {
            final parts = grab.split('/');
            parsedService = parts[0].toLowerCase();
            parsedVersion = RegExp(r'\d+\.\d+(\.\d+[a-z]?)?').stringMatch(parts[1]) ?? '';
          }
          
          if (parsedService == 'apache' && version.toLowerCase().contains('httpd')) parsedService = 'apache httpd';
          if (parsedService == 'ssh' || parsedService.toLowerCase() == 'openssh') parsedService = 'OpenSSH';
          
          if (parsedVersion.isNotEmpty) {
             final cveData = await DatabaseHelper().findCveForService(parsedService, parsedVersion);
             if (cveData != null) {
               vulnScore = cveData['cvss_score'].toString();
               vulnLevel = cveData['severity'].toString();
             }
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
      final timer = Timer(Duration(milliseconds: (timeout.inMilliseconds * 1.5).round()), () {
        if (!completer.isCompleted) {
          socket.destroy();
          completer.complete('');
        }
      });

      socket.listen(
        (data) {
          if (completer.isCompleted) return;
          timer.cancel();
          
          // Strip Telnet/binary negotiation options (bytes starting with 255 / 0xFF)
          List<int> cleanBytes = [];
          for (int i = 0; i < data.length; i++) {
            if (data[i] == 255) {
              if (i + 2 < data.length) {
                i += 2; // Skip standard 3-byte IAC command sequences
              } else {
                i = data.length; // Skip to end
              }
            } else {
              cleanBytes.add(data[i]);
            }
          }

          final String response;
          if (cleanBytes.isEmpty && port == 23) {
            response = 'Telnet Service (Active Negotiation)';
          } else {
            response = String.fromCharCodes(cleanBytes).trim();
          }
          
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
    if (module == 'quick') {
      // Quick Scan: Top 20 most critical ports
      return [21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080];
    } else if (module == 'custom') {
      if (customPorts == null || customPorts!.trim().isEmpty) {
        return [];
      }
      List<int> ports = [];
      List<String> parts = customPorts!.split(',');
      for (String p in parts) {
        int? port = int.tryParse(p.trim());
        if (port != null && port > 0 && port <= 65535) {
          ports.add(port);
        }
      }
      return ports;
    } else if (module == 'common') {
      // Standard Sweep: 1 to 1024 + popular high ports
      List<int> ports = List.generate(1024, (i) => i + 1);
      final Set<int> portsSet = ports.toSet();
      List<int> highPorts = [1433, 1521, 1720, 1723, 2000, 2049, 2121, 3000, 3128, 3306, 3389, 3986, 4899, 5000, 5051, 5060, 5101, 5432, 5631, 5800, 5900, 6000, 6001, 6667, 7000, 7070, 8000, 8008, 8009, 8080, 8081, 8443, 8888, 9090, 9100, 9999, 10000, 32768, 49152, 49153, 49154, 49155, 49156, 49157];
      for(var p in highPorts) { if (!portsSet.contains(p)) ports.add(p); }
      return ports;
    } else if (module == 'service') {
      // Ports that usually have banners
      return [21, 22, 23, 25, 80, 110, 143, 443, 445, 1433, 1521, 3306, 3389, 5432, 8080, 8081];
    } else {
      // Full Scan: All 65535 TCP ports
      return List.generate(65535, (i) => i + 1);
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

  // Get local ARP table mappings
  Future<Map<String, String>> _getArpTable() async {
    final Map<String, String> table = {};
    try {
      final args = Platform.isMacOS ? ['-an'] : ['-a'];
      final result = await Process.run('arp', args);
      if (result.exitCode == 0) {
        final ipRegex = RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b');
        final macRegex = RegExp(r'\b([0-9a-fA-F]{2}[-:]){5}[0-9a-fA-F]{2}\b');
        
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          final ipMatch = ipRegex.firstMatch(line);
          final macMatch = macRegex.firstMatch(line);
          if (ipMatch != null && macMatch != null) {
            final ip = ipMatch.group(0)!;
            final mac = macMatch.group(0)!.toUpperCase().replaceAll('-', ':');
            
            // Filter out broadcast and multicast MACs
            if (mac != 'FF:FF:FF:FF:FF:FF' && !mac.startsWith('01:00:5E')) {
              table[ip] = mac;
            }
          }
        }
      }
    } catch (_) {}
    return table;
  }

  // Query MAC vendor asynchronously
  Future<String> _getOsFingerprint(String ip) async {
    try {
      final args = Platform.isWindows ? ['-n', '1', '-w', '1000', ip] : ['-c', '1', '-W', '1', ip];
      final result = await Process.run('ping', args);
      final output = result.stdout.toString().toLowerCase();
      
      int ttl = -1;
      final RegExp ttlRegex = RegExp(r'ttl=(\d+)');
      final match = ttlRegex.firstMatch(output);
      if (match != null) {
        ttl = int.parse(match.group(1)!);
      }

      if (ttl > 0) {
        if (ttl <= 64) return 'Linux/macOS';
        if (ttl <= 128) return 'Windows';
        if (ttl <= 255) return 'Network/Cisco';
      }
    } catch (_) {}
    return 'UNKNOWN';
  }

  /// Scans the local system's network interfaces to find the MAC address
  /// associated with the given [localIp]. Works on Windows (ipconfig /all)
  /// and macOS/Linux (ifconfig).
  Future<String> _getLocalMacAddress(String localIp) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('ipconfig', ['/all']);
        if (result.exitCode != 0) return 'N/A';
        final output = result.stdout as String;
        // Split by blank lines to get per-adapter blocks
        final blocks = output.split('\r\n\r\n');
        for (final block in blocks) {
          if (block.contains(localIp)) {
            for (final line in block.split('\r\n')) {
              // Supports both English ("Physical Address") and Turkish ("Fiziksel Adres") locales
              if (line.toLowerCase().contains('physical address') ||
                  line.toLowerCase().contains('fiziksel adres')) {
                final colonIdx = line.indexOf(':');
                if (colonIdx != -1) {
                  return line.substring(colonIdx + 1).trim().replaceAll('-', ':');
                }
              }
            }
          }
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('ifconfig', []);
        if (result.exitCode != 0) return 'N/A';
        final output = result.stdout as String;
        // Split by adapter blocks (lines that start without whitespace)
        final blocks = output.split(RegExp(r'\n(?=[a-z])'));
        for (final block in blocks) {
          if (block.contains(localIp)) {
            for (final line in block.split('\n')) {
              final trimmed = line.trim();
              if (trimmed.startsWith('ether ')) {
                return trimmed.split(' ')[1].trim().toUpperCase().replaceAll('-', ':');
              }
            }
          }
        }
      }
    } catch (_) {}
    return 'N/A';
  }

  /// Performs a reverse DNS lookup for [ip].
  /// Returns the resolved hostname or 'UNKNOWN' on failure/timeout.
  Future<String> _resolveHostname(String ip) async {
    try {
      final addr = InternetAddress(ip);
      final reversed = await addr.reverse().timeout(const Duration(seconds: 2));
      final host = reversed.host;
      // Skip bare IP addresses returned as host (some systems do this)
      if (host.isNotEmpty && host != ip) return host;
    } catch (_) {}
    return 'UNKNOWN';
  }

  Future<String> _getMacVendor(String mac) async {
    final cleanMac = mac.replaceAll(':', '').replaceAll('-', '').toLowerCase();
    if (cleanMac.length >= 6) {
      final prefix = cleanMac.substring(0, 6);
      
      // Practical recognition labels for common virtualization NICs. Their official IEEE
      // registrant (e.g. "PCS Systemtechnik GmbH") is technically accurate but useless for
      // triage, so these two are intentionally overridden with the vendor pentesters expect.
      // All other vendor names come straight from the offline IEEE OUI database below.
      const localOuis = {
        '080027': 'Oracle VirtualBox',
        '00155d': 'Microsoft Hyper-V',
      };

      if (localOuis.containsKey(prefix)) {
        return localOuis[prefix]!;
      }

      // Bundled offline OUI database (~39.7k prefixes, direct from the IEEE public registry). Fully local, no network call.
      final offlineVendor = DatabaseHelper().lookupOuiVendor(prefix);
      if (offlineVendor != null) {
        return offlineVendor;
      }

      // Online fallback is opt-in only: sends the MAC prefix of scanned devices to
      // macvendors.com over the internet. Disabled by default to preserve fully-offline operation.
      if (!enableOnlineVendorLookup) {
        return 'UNKNOWN';
      }

      _log('WARN', 'Vendor prefix $prefix not in offline DB. Querying external macvendors.com (online vendor lookup is enabled)...');

      final client = HttpClient();
      try {
        client.connectionTimeout = const Duration(seconds: 2);

        final uri = Uri.parse('https://macvendors.com/query/$prefix');
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          return body.trim();
        }
      } catch (_) {}
      finally {
        client.close();
      }
    }
    return 'UNKNOWN';
  }
}
