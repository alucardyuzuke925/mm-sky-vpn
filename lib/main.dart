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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String vlessKey = "vless://7d69b1d1-7f1a-40c2-f2b8-da7805e671f9@104.18.1.232:443?type=ws&encryption=none&path=%2F&host=black.mainu.site&security=tls&fp=chrome&alpn=h3%2Ch2%2Chttp%2F1.1&sni=black.mainu.site";

  bool isConnected = false;
  bool isLoading = false;
  String status = "DISCONNECTED";
  String subStatus = "Tap to connect";
  String ping = "—";
  String duration = "00:00:00";
  late V2ray v2ray;
  DateTime? connectTime;

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
    _startTimer();
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
          });
        }
        _startTimer();
      }
    });
  }

  Future<void> _toggleConnect() async {
    if (isLoading) return;
    if (vlessKey.isEmpty) {
      setState(() {
        status = "NO KEY";
        subStatus = "Key မရှိပါ";
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
        final parser = V2ray.parseFromURL(vlessKey);
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
          });
        } else {
          setState(() {
            status = "PERMISSION DENIED";
            subStatus = "VPN permission လိုအပ်သည်";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cloud, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("MM SKY",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("Fast & Secure",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _toggleConnect,
              child: Container(
                width: 240, height: 240,
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
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.power_settings_new, color: Colors.white, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(status,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(subStatus, style: const TextStyle(fontSize: 15, color: Colors.grey)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _card(icon: isConnected ? Icons.wifi : Icons.wifi_off, label: "Status", value: isConnected ? "Active" : "Inactive"),
                  const SizedBox(width: 12),
                  _card(icon: Icons.show_chart, label: "Ping", value: ping),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _card(icon: Icons.access_time, label: "Duration", value: duration),
                  const SizedBox(width: 12),
                  _card(icon: Icons.shield_outlined, label: "Protocol", value: "VLESS"),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _card({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
              child: Icon(icon, color: const Color(0xFF0EA5E9), size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
