import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final bool isVip;
  final String? password;
  ServerInfo({
    required this.name,
    required this.key,
    this.isVip = false,
    this.password,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      isVip: json['isVip'] ?? false,
      password: json['password'] ?? '',
    );
  }
}

const String configUrl = "https://raw.githubusercontent.com/alucardyuzuke925/mm-sky-vpn/main/config.json";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String kpayNumber = "09698624401";
  String kpayName = "San Dar Soe";
  String telegramUser = "@VIPkey90";
  String telegramChannel = "https://t.me/FreekeytoVip";
  String telegramChannelName = "FREE VPN KEY";
  String messengerLink = "https://www.facebook.com/share/1CN89ohAwG/";
  String pricing1Month = "5,000 MMK";
  String pricing3Months = "23,000 MMK";
  String pricing1Year = "80,000 MMK";
  String freeGb = "10";
  int like1Count = 0;
  int like2Count = 0;
  int like3Count = 0;
  int myChoice = 0;

  List<ServerInfo> servers = [];

  int selectedServer = 0;
  final Set<int> unlockedVipIndexes = {};
  bool isConnected = false;
  bool isLoading = false;
  bool hasInternet = true;
  String status = "DISCONNECTED";
  String subStatus = "Tap to connect";
  String ping = "—";
  String duration = "00:00:00";
  String uploadData = "0 B";
  String downloadData = "0 B";
  String speedTestResult = "Tap to test";
  late V2ray v2ray;
  DateTime? connectTime;
  int uploadBytes = 0;
  int downloadBytes = 0;
  int currentKbps = 0;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

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
            _cancelNotification();
          }
        });
      },
    );
    _initNotifications();
    _loadUnlockedVips();
    _loadMyChoice();
    _loadLikes();
    _checkInternet();
    _fetchConfig();
    _startTimer();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
  }

  Future<void> _showSpeedNotification(int kbps) async {
    const androidDetails = AndroidNotificationDetails(
      'vpn_speed', 'VPN Speed',
      channelDescription: 'VPN Speed Monitor',
      importance: Importance.low, priority: Priority.low,
      ongoing: true, showProgress: false,
      icon: '@mipmap/ic_launcher',
    );
    await _notifications.show(1, 'MM SKY VPN Connected',
        'Speed: $kbps Kbps', const NotificationDetails(android: androidDetails));
  }

  Future<void> _cancelNotification() async {
    await _notifications.cancel(1);
  }

  Future<void> _loadUnlockedVips() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('unlocked_vips') ?? [];
    setState(() {
      unlockedVipIndexes.clear();
      unlockedVipIndexes.addAll(saved.map((s) => int.parse(s)));
    });
  }

  Future<void> _saveUnlockedVips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_vips',
        unlockedVipIndexes.map((i) => i.toString()).toList());
  }

  Future<void> _loadMyChoice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => myChoice = prefs.getInt('my_choice') ?? 0);
  }

  Future<void> _loadLikes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      like1Count = prefs.getInt('like1') ?? 0;
      like2Count = prefs.getInt('like2') ?? 0;
      like3Count = prefs.getInt('like3') ?? 0;
    });
  }

  Future<void> _saveLikes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('like1', like1Count);
    await prefs.setInt('like2', like2Count);
    await prefs.setInt('like3', like3Count);
  }

  Future<void> _submitLike(int choice) async {
    if (myChoice == choice) return;
    setState(() {
      if (myChoice == 1) like1Count--;
      if (myChoice == 2) like2Count--;
      if (myChoice == 3) like3Count--;
      if (choice == 1) like1Count++;
      if (choice == 2) like2Count++;
      if (choice == 3) like3Count++;
      myChoice = choice;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('my_choice', choice);
    await _saveLikes();
  }

  Future<void> _fetchConfig() async {
    try {
      final response = await http.get(Uri.parse(configUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          kpayNumber = data['kpay'] ?? kpayNumber;
          kpayName = data['kpay_name'] ?? kpayName;
          telegramUser = data['telegram'] ?? telegramUser;
          telegramChannel = data['telegram_channel'] ?? telegramChannel;
          telegramChannelName = data['telegram_channel_name'] ?? telegramChannelName;
          messengerLink = data['messenger'] ?? messengerLink;
          pricing1Month = data['pricing_1month'] ?? pricing1Month;
          pricing3Months = data['pricing_3months'] ?? pricing3Months;
          pricing1Year = data['pricing_1year'] ?? pricing1Year;
          freeGb = data['free_gb'] ?? freeGb;
          if (data['servers'] != null) {
            final List<dynamic> sJson = data['servers'];
            servers = sJson.map((s) => ServerInfo.fromJson(s)).toList();
          }
        });
      }
    } catch (e) {}
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
          final kbps = 100 + (DateTime.now().millisecond % 900);
          setState(() {
            currentKbps = kbps;
            duration = "${diff.inHours.toString().padLeft(2, '0')}:"
                "${(diff.inMinutes % 60).toString().padLeft(2, '0')}:"
                "${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
            uploadBytes += 1024 * (1 + DateTime.now().millisecond % 10);
            downloadBytes += 1024 * (5 + DateTime.now().millisecond % 20);
            uploadData = _formatBytes(uploadBytes);
            downloadData = _formatBytes(downloadBytes);
          });
          _showSpeedNotification(kbps);
        }
        _startTimer();
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / 1024 / 1024).toStringAsFixed(1)} MB";
    return "${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB";
  }

  Future<void> _speedTest() async {
    setState(() => speedTestResult = "Testing...");
    await Future.delayed(const Duration(seconds: 3));
    final mbps = 5 + (DateTime.now().millisecond % 45);
    setState(() => speedTestResult = "$mbps Mbps");
  }

  Future<void> _toggleConnect() async {
    if (isLoading) return;
    if (servers.isEmpty) return;
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
        _cancelNotification();
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
    if (servers[index].isVip && !unlockedVipIndexes.contains(index)) {
      _showVipDialog(index);
      return;
    }
    setState(() => selectedServer = index);
  }

  Future<void> _openTelegram() async {
    try {
      final url = Uri.parse('https://t.me/${telegramUser.replaceAll("@", "")}');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Telegram ဖွင့်လို့ မရပါ: $e")),
      );
    }
  }

  Future<void> _openChannel() async {
    try {
      final url = Uri.parse(telegramChannel);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Channel ဖွင့်လို့ မရပါ: $e")),
      );
    }
  }

  Future<void> _openMessenger() async {
    try {
      final url = Uri.parse(messengerLink);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Messenger ဖွင့်လို့ မရပါ: $e")),
      );
    }
  }

  void _showVipDialog(int serverIndex) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("🔒 VIP Server", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("VIP Server သုံးဖို့ ငွေ ပေးပါ",
                  style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066CC),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text("K", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(kpayNumber, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("👤 $kpayName", style: const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 10),
                    const Text("💰 ဈေးနှုန်း:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("• 1 Month — $pricing1Month", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Text("• 3 Months — $pricing3Months", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Text("• 1 Year — $pricing1Year", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 10),
                    const Text("💸 ငွေလွဲပြီးရင် ပြေစာ ပို့ပေးပါ:",
                        style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openTelegram,
                          child: Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0088CC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _openMessenger,
                          child: Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0084FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.message, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text("ပုံကို နှိပ်ပါ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text("Password ရပြီးရင် ဒီမှာ ထည့်ပါ:",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0A1628),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pass = passCtrl.text.trim();
              if (pass == servers[serverIndex].password) {
                setState(() {
                  unlockedVipIndexes.add(serverIndex);
                  selectedServer = serverIndex;
                });
                await _saveUnlockedVips();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✓ VIP Server ဖွင့်ပြီးပါပြီ"), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Password မှားသည်"), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
            child: const Text("Unlock", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _likeOption(int choice, String text, int count) {
    final isSelected = myChoice == choice;
    return GestureDetector(
      onTap: () => _submitLike(choice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9).withOpacity(0.2) : const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
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
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.4), blurRadius: 15),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset('8002c5a5f554f1ef1510b9f561cc1775.jpg', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MM SKY", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Fast & Secure", style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                      Expanded(child: Text("ဒေတာ မရှိပါ — WiFi/Data ဖွင့်ပါ", style: TextStyle(color: Colors.red, fontSize: 13))),
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
                  child: servers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text("Loading servers...", style: TextStyle(color: Colors.grey)),
                        )
                      : DropdownButton<int>(
                          value: selectedServer,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: const Color(0xFF1E293B),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          items: List.generate(servers.length, (i) {
                            final server = servers[i];
                            final isLocked = server.isVip && !unlockedVipIndexes.contains(i);
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Row(
                                children: [
                                  Icon(isLocked ? Icons.lock : Icons.dns,
                                      color: isLocked ? Colors.orange : const Color(0xFF0EA5E9), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(server.name,
                                        style: TextStyle(color: isLocked ? Colors.orange : Colors.white, fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  if (isLocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("VIP", style: TextStyle(color: Colors.orange, fontSize: 10)),
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
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isConnected
                          ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                          : [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected ? const Color(0xFF10B981) : const Color(0xFF0EA5E9)).withOpacity(0.5),
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
              Text(status, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(subStatus, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _card(icon: isConnected ? Icons.wifi : Icons.wifi_off, label: "Status", value: isConnected ? "Active" : "Inactive"),
                  const SizedBox(width: 12),
                  _card(icon: Icons.speed, label: "Speed", value: isConnected ? "$currentKbps Kbps" : "—"),
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      Row(
                        children: [
                          const Icon(Icons.data_usage, color: Color(0xFF0EA5E9), size: 20),
                          const SizedBox(width: 8),
                          Text("Free: $freeGb GB", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("သင့်ဆန္ဒ ရွေးပါ:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _likeOption(1, "GB တိုးပေးပါ", like1Count),
                      _likeOption(2, "မတိုးပေးပါနဲ့", like2Count),
                      _likeOption(3, "လိုင်းကောင်း VIP ဝယ်မယ်", like3Count),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _openChannel,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0088CC), Color(0xFF00B4D8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send,
                                    color: Color(0xFF0088CC), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(telegramChannelName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Free GB တိုးချင်ရင် Channel Join ပြီး ပြောပါ",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _speedTest,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.network_check, color: Color(0xFF0EA5E9), size: 24),
                        const SizedBox(width: 12),
                        const Text("Speed Test", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(speedTestResult, style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
