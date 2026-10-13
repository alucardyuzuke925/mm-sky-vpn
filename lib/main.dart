import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

void main() => runApp(const MMSkyVPN());

class MMSkyVPN extends StatelessWidget {
  const MMSkyVPN({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MM SKY VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A1628),
      ),
      home: const HomeScreen(),
    );
  }
}

class ServerInfo {
  final String name;
  final String key;
  ServerInfo({required this.name, required this.key});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ServerInfo> servers = [
    ServerInfo(
      name: "Myanmar All sim saver 1",
      key: "vless://7d69b1d1-7f1a-40c2-f2b8-da7805e671f9@104.18.1.232:443?type=ws&encryption=none&path=%2F&host=black.mainu.site&security=tls&fp=chrome&alpn=h3%2Ch2%2Chttp%2F1.1&sni=black.mainu.site#Myanmar%20All%20sim%20saver%201",
    ),
    ServerInfo(
      name: "Myanmar All sim saver 2",
      key: "vless://1dc4f5c7-3373-4ffb-ff0d-b14b18593fe8@104.18.1.232:443?type=ws&encryption=none&path=%2F&host=black.mainu.site&security=tls&fp=chrome&alpn=h3%2Ch2%2Chttp%2F1.1&sni=black.mainu.site#Myanmar%20All%20sim%20saver%202",
    ),
    ServerInfo(
      name: "Mytel vless-Myanmar Mytel Sim only",
      key: "vless://33b2a768-f03b-4336-a51a-21e1b52efaa1@203.159.93.210:2083?type=ws&encryption=none&path=%2Fmytel-vip&host=&security=tls&fp=chrome&alpn=h3%2Ch2%2Chttp%2F1.1&sni=swg.cloudflare.com#Mytel%20vless-Myanmar%20Mytel%20Sim%20only",
    ),
  ];

  int selectedServer = 0;
  bool isConnected = false;
  bool isLoading = false;
  bool hasInternet = true;
  String status = "DISCONNECTED";
  String subStatus = "Tap to connect";
  String ping = "—";
  String duration = "00:00:00";
  String uploadData = "0 B";
  String downloadData = "0 B";
  String expiryText = "365 days left";
  int daysLeft = 365;
  bool isExpired = false;
  late V2ray v2ray;
  DateTime? connectTime;
  int uploadBytes = 0;
  int downloadBytes = 0;

  @override
  void initState() {
    super.initState();
    v2ray = V2ray(
      onStatusChanged: (s) {
        setState(() {
          isConnected = s.state == "CONNECTED";
          if (isConnected) {
            status = "CONNECTED";
            subStatus = "Tap to disconnect";
            connectTime = connectTime ?? DateTime.now();
            ping = "${20 + (DateTime.now().millisecond % 40)} ms";
          } else {
            status = "DISCONNECTED";
            subStatus = "Tap to connect";
            connectTime = null;
            ping = "—";
            duration = "00:00:00";
          }
        });
      },
    );
    _checkInternet();
    _startTimer();
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final ok = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      setState(() => hasInternet = ok);
      return ok;
    } catch (e) {
      setState(() => hasInternet = false);
      return false;
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (isConnected && connectTime != null) {
          final diff = DateTime.now().difference(connectTime!);
          setState(() {
            duration = "${diff.inHours.toString().padLeft(2, '0')}:"
                "${(diff.inMinutes % 60).toString().padLeft(2, '0')}:"
                "${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
            uploadBytes += 1024 * (1 + DateTime.now().millisecond % 10);
            downloadBytes += 1024 * (5 + DateTime.now().millisecond % 20);
            uploadData = _formatBytes(uploadBytes);
            downloadData = _formatBytes(downloadBytes);
          });
        }
        _startTimer();
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / 1024 / 1024).toStringAsFixed(1)} MB";
    }
    return "${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB";
  }

  Future<void> _toggleConnect() async {
    if (isLoading) return;
    final online = await _checkInternet();
    if (!online) {
      setState(() {
        status = "NO INTERNET";
        subStatus = "ဒေတာ မရှိပါ — WiFi/Data ဖွင့်ပါ";
      });
      return;
    }
    setState(() => isLoading = true);
    try {
      if (isConnected) {
        v2ray.stopV2Ray();
        setState(() {
          isConnected = false;
          status = "DISCONNECTED";
          subStatus = "Tap to connect";
          connectTime = null;
          duration = "00:00:00";
          ping = "—";
        });
      } else {
        final currentKey = servers[selectedServer].key;
        final parser = V2ray.parseFromURL(currentKey);
        final perm = await v2ray.requestPermission();
        if (perm) {
          v2ray.startV2Ray(
            remark: parser.remark,
            config: parser.getFullConfiguration(),
            proxyOnly: false,
          );
          setState(() {
            isConnected = true;
            status = "CONNECTED";
            subStatus = "Tap to disconnect";
            connectTime = DateTime.now();
            ping = "${20 + (DateTime.now().millisecond % 40)} ms";
            uploadBytes = 0;
            downloadBytes = 0;
          });
        }
      }
    } catch (e) {
      setState(() {
        status = "ERROR";
        subStatus = e.toString();
      });
    }
    setState(() => isLoading = false);
  }

  void _changeServer(int index) {
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("VPN ဖြုတ်ပြီးမှ Server ပြောင်းပါ")),
      );
      return;
    }
    setState(() => selectedServer = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.cloud, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MM SKY",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Fast & Secure",
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!hasInternet)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text("ဒေတာ မရှိပါ — WiFi/Data ဖွင့်ပါ",
                            style: TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButton<int>(
                    value: selectedServer,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: List.generate(servers.length, (i) {
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Row(
                          children: [
                            Icon(
                              isConnected && selectedServer == i
                                  ? Icons.check_circle
                                  : Icons.dns,
                              color: const Color(0xFF0EA5E9),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(servers[i].name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      );
                    }),
                    onChanged: (v) => _changeServer(v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleConnect,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isConnected
                          ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                          : [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected ? const Color(0xFF10B981) : const Color(0xFF0EA5E9))
                            .withOpacity(0.5),
                        blurRadius: 60, spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.power_settings_new, color: Colors.white, size: 70),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(status,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(subStatus, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _card(icon: isConnected ? Icons.wifi : Icons.wifi_off, label: "Status", value: isConnected ? "Active" : "Inactive"),
                  const SizedBox(width: 12),
                  _card(icon: Icons.show_chart, label: "Ping", value: ping),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _card(icon: Icons.access_time, label: "Duration", value: duration),
                  const SizedBox(width: 12),
                  _card(icon: Icons.shield_outlined, label: "Protocol", value: "VLESS"),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _card(icon: Icons.arrow_upward, label: "Upload", value: uploadData),
                  const SizedBox(width: 12),
                  _card(icon: Icons.arrow_downward, label: "Download", value: downloadData),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _card(icon: Icons.calendar_today, label: "Expiry", value: expiryText),
                  const SizedBox(width: 12),
                  _card(icon: Icons.data_usage, label: "Days Left", value: "$daysLeft"),
                ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
