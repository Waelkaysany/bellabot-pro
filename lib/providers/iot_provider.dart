import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

// ─── Transaction model ────────────────────────────────────────────────────────
class RfidTransaction {
  final String status; // 'SUCCESS' | 'FAILED'
  final String name;
  final String uid;
  final DateTime time;

  RfidTransaction({
    required this.status,
    required this.name,
    required this.uid,
    required this.time,
  });

  bool get isSuccess => status == 'SUCCESS';
}

// ══════════════════════════════════════════════════════════════════════════════
class IotProvider extends ChangeNotifier {
  String _ipAddress = '192.168.158.102';
  bool _led1On = false;
  bool _led2On = false;
  bool _motorOn = false;
  bool _waiterActive = false;
  bool _isConnected = false;
  bool _isLoading = false;

  // ─── RFID Payment State ────────────────────────────────────────────────────
  String _rfidStatus = 'IDLE'; // 'IDLE' | 'SUCCESS' | 'FAILED'
  String _rfidUid    = '';
  String _rfidName   = '';
  bool _rfidPollingActive = false;
  Timer? _rfidPollTimer;
  final List<RfidTransaction> _transactionHistory = [];

  // ─── Getters ───────────────────────────────────────────────────────────────
  String get ipAddress       => _ipAddress;
  bool   get led1On          => _led1On;
  bool   get led2On          => _led2On;
  bool   get motorOn         => _motorOn;
  bool   get waiterActive    => _waiterActive;
  bool   get isConnected     => _isConnected;
  bool   get isLoading       => _isLoading;

  String get rfidStatus      => _rfidStatus;
  String get rfidUid         => _rfidUid;
  String get rfidName        => _rfidName;
  bool   get rfidPolling     => _rfidPollingActive;
  List<RfidTransaction> get transactionHistory =>
      List.unmodifiable(_transactionHistory);

  // ══════════════════════════════════════════════════════════════════════════
  //  CONNECTION
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> checkConnection() async {
    await _sendCommand('');
  }

  void setIpAddress(String ip) {
    _ipAddress = ip;
    notifyListeners();
    checkConnection();
  }

  Future<void> _sendCommand(String endpoint) async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse('http://$_ipAddress/$endpoint');
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));
      _isConnected = response.statusCode == 200;
    } catch (e) {
      _isConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BASIC CONTROLS
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> toggleLed1() async {
    _led1On = !_led1On;
    notifyListeners();
    await _sendCommand('led1/${_led1On ? "on" : "off"}');
  }

  Future<void> toggleLed2() async {
    _led2On = !_led2On;
    notifyListeners();
    await _sendCommand('led2/${_led2On ? "on" : "off"}');
  }

  Future<void> toggleMotor() async {
    _motorOn = !_motorOn;
    notifyListeners();
    await _sendCommand('motor/${_motorOn ? "on" : "off"}');
  }

  Future<void> activateWaiter() async {
    _waiterActive = true;
    _led1On = true;
    _led2On = true;
    _motorOn = false;
    notifyListeners();
    await _sendCommand('waiter');
    await Future.delayed(const Duration(seconds: 4));
    _waiterActive = false;
    notifyListeners();
  }

  Future<void> resetRobot() async {
    _led1On = false;
    _led2On = false;
    _motorOn = false;
    _waiterActive = false;
    notifyListeners();
    await _sendCommand('reset');
  }

  Future<void> triggerBirthday(String name) async {
    final encodedName = Uri.encodeComponent(name);
    await _sendCommand('birthday?name=$encodedName');
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RFID POLLING (called by Payment Page)
  // ══════════════════════════════════════════════════════════════════════════

  /// Start polling /rfid/status every 800 ms.
  void startRfidPolling() {
    if (_rfidPollingActive) return;
    _rfidPollingActive = true;
    notifyListeners();
    _rfidPollTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _pollRfidStatus(),
    );
  }

  /// Stop polling (called when Payment Page is disposed).
  void stopRfidPolling() {
    _rfidPollTimer?.cancel();
    _rfidPollTimer = null;
    _rfidPollingActive = false;
    notifyListeners();
  }

  Future<void> _pollRfidStatus() async {
    try {
      final url = Uri.parse('http://$_ipAddress/rfid/status');
      final response =
          await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newStatus = data['status'] as String? ?? 'IDLE';
        final newUid    = data['uid']    as String? ?? '';
        final newName   = data['name']   as String? ?? '';

        if (newStatus != 'IDLE' && newStatus != _rfidStatus) {
          _rfidStatus = newStatus;
          _rfidUid    = newUid;
          _rfidName   = newName;

          // Log into transaction history
          _transactionHistory.insert(
            0,
            RfidTransaction(
              status: newStatus,
              name:   newName,
              uid:    newUid,
              time:   DateTime.now(),
            ),
          );
          // Cap history at 50 entries
          if (_transactionHistory.length > 50) {
            _transactionHistory.removeRange(50, _transactionHistory.length);
          }

          notifyListeners();

          // Auto-clear after showing overlay (3.5 s)
          Future.delayed(const Duration(milliseconds: 3500), clearRfidStatus);
        }
      }
    } catch (_) {
      // Network error — silently ignore, keep polling
    }
  }

  /// Hit /rfid/clear and reset local state back to IDLE.
  Future<void> clearRfidStatus() async {
    _rfidStatus = 'IDLE';
    _rfidUid    = '';
    _rfidName   = '';
    notifyListeners();
    try {
      final url = Uri.parse('http://$_ipAddress/rfid/clear');
      await http.get(url).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  @override
  void dispose() {
    stopRfidPolling();
    super.dispose();
  }
}
