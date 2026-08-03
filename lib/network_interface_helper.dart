import 'dart:io';

class NetworkAdapterInfo {
  final String name;
  final String ip;
  final String cidr;

  NetworkAdapterInfo({
    required this.name,
    required this.ip,
    required this.cidr,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'ip': ip,
        'cidr': cidr,
      };
}

class NetworkInterfaceHelper {
  static Future<List<NetworkAdapterInfo>> getLocalInterfaces() async {
    List<NetworkAdapterInfo> adapters = [];
    try {
      if (Platform.isWindows) {
        adapters = await _getWindowsInterfaces();
      } else if (Platform.isMacOS || Platform.isLinux) {
        adapters = await _getUnixInterfaces();
      }

      // Fallback if CLI fails
      if (adapters.isEmpty) {
        adapters = await _getDartInterfaces();
      }
    } catch (e) {
      print('[ERROR] Failed to list network interfaces: $e');
    }
    return adapters;
  }

  static Future<List<NetworkAdapterInfo>> _getWindowsInterfaces() async {
    List<NetworkAdapterInfo> result = [];
    try {
      final res = await Process.run('ipconfig', []);
      final output = res.stdout.toString();
      
      final adapterBlocks = output.split(RegExp(r'\n(?=\S)'));
      for (var block in adapterBlocks) {
        if (!block.contains('IPv4 Address') && !block.contains('IPv4 Adresi')) continue;

        String name = "Unknown";
        final nameMatch = RegExp(r'^(.+):').firstMatch(block);
        if (nameMatch != null) {
          name = nameMatch.group(1)?.trim() ?? "Unknown";
          name = name.replaceAll('adapter ', '').replaceAll('bağdaştırıcısı ', '');
        }

        String? ip;
        String? mask;

        final lines = block.split('\n');
        for (var line in lines) {
          if ((line.contains('IPv4 Address') || line.contains('IPv4 Adresi')) && line.contains(':')) {
            ip = line.split(':').last.trim();
          } else if ((line.contains('Subnet Mask') || line.contains('Alt Ağ Maskesi')) && line.contains(':')) {
            mask = line.split(':').last.trim();
          }
        }

        if (ip != null && mask != null && !ip.startsWith('169.254.') && !ip.startsWith('127.')) {
          int prefix = _netmaskToCidr(mask);
          String network = _calculateNetworkAddress(ip, mask);
          result.add(NetworkAdapterInfo(name: name, ip: ip, cidr: '$network/$prefix'));
        }
      }
    } catch (e) {
      print('[WARN] IPConfig parsing failed: $e');
    }
    return result;
  }

  static Future<List<NetworkAdapterInfo>> _getUnixInterfaces() async {
    List<NetworkAdapterInfo> result = [];
    try {
      final res = await Process.run('ifconfig', []);
      final output = res.stdout.toString();
      
      final adapterBlocks = output.split(RegExp(r'\n(?=^[a-zA-Z0-9]+:)'));
      for (var block in adapterBlocks) {
        if (!block.contains('inet ')) continue;

        String name = "Unknown";
        final nameMatch = RegExp(r'^([a-zA-Z0-9]+):').firstMatch(block);
        if (nameMatch != null) {
          name = nameMatch.group(1)?.trim() ?? "Unknown";
        }

        if (name == 'lo0' || name == 'lo') continue; // skip loopback

        final inetMatch = RegExp(r'inet\s+([0-9\.]+)\s+netmask\s+(0x[a-fA-F0-9]+|[0-9\.]+)').firstMatch(block);
        if (inetMatch != null) {
          String ip = inetMatch.group(1)!;
          String maskRaw = inetMatch.group(2)!;
          
          if (ip.startsWith('169.254.') || ip.startsWith('127.')) continue;

          String mask = maskRaw;
          if (maskRaw.startsWith('0x')) {
             mask = _hexToIp(maskRaw);
          }

          int prefix = _netmaskToCidr(mask);
          String network = _calculateNetworkAddress(ip, mask);
          result.add(NetworkAdapterInfo(name: name, ip: ip, cidr: '$network/$prefix'));
        }
      }
    } catch (e) {
      print('[WARN] ifconfig parsing failed: $e');
    }
    return result;
  }

  static Future<List<NetworkAdapterInfo>> _getDartInterfaces() async {
    List<NetworkAdapterInfo> result = [];
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    for (var interface in interfaces) {
      for (var address in interface.addresses) {
        final ip = address.address;
        if (ip.startsWith('127.') || ip.startsWith('169.254.')) continue;

        // Fallback default /24
        final parts = ip.split('.');
        if (parts.length == 4) {
          result.add(NetworkAdapterInfo(
            name: interface.name,
            ip: ip,
            cidr: '${parts[0]}.${parts[1]}.${parts[2]}.0/24',
          ));
        }
      }
    }
    return result;
  }

  static int _netmaskToCidr(String netmask) {
    int cidr = 0;
    for (var octet in netmask.split('.')) {
      int val = int.tryParse(octet) ?? 0;
      while (val > 0) {
        cidr += val & 1;
        val >>= 1;
      }
    }
    return cidr;
  }

  static String _calculateNetworkAddress(String ip, String netmask) {
    List<int> ipOctets = ip.split('.').map((e) => int.parse(e)).toList();
    List<int> maskOctets = netmask.split('.').map((e) => int.parse(e)).toList();
    
    if (ipOctets.length != 4 || maskOctets.length != 4) return ip;

    List<int> networkOctets = [];
    for (int i = 0; i < 4; i++) {
      networkOctets.add(ipOctets[i] & maskOctets[i]);
    }
    return networkOctets.join('.');
  }

  static String _hexToIp(String hexStr) {
    hexStr = hexStr.replaceFirst('0x', '');
    if (hexStr.length != 8) return '255.255.255.0';
    List<String> octets = [];
    for (int i = 0; i < 8; i += 2) {
      octets.add(int.parse(hexStr.substring(i, i + 2), radix: 16).toString());
    }
    return octets.join('.');
  }
}
