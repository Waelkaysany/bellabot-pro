import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class IotProvider extends ChangeNotifier {
  String _ipAddress = '192.168.158.102';
  bool _led1On = false;
  bool _led2On = false;
  bool _motorOn = false;
  bool _waiterActive = false;
  bool _isConnected = false;
  bool _isLoading = false;

  String get ipAddress => _ipAddress;
  bool get led1On => _led1On;
  bool get led2On => _led2On;
  bool get motorOn => _motorOn;
  bool get waiterActive => _waiterActive;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

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
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      _isConnected = response.statusCode == 200;
    } catch (e) {
      _isConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    // After the sequence finishes, mark as done
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
}
