import 'package:flutter/foundation.dart';
import '../models/tray.dart';

class TrayProvider with ChangeNotifier {
  final List<Tray> _trays = List.generate(
    4,
    (index) => Tray(id: index + 1),
  );

  List<Tray> get trays => _trays;

  bool get canStartDelivery => _trays.any((tray) => tray.status == TrayStatus.loaded);

  void updateTrayTable(int index, String table) {
    _trays[index].setDestination(table);
    notifyListeners();
  }

  void confirmLoad(int index) {
    if (_trays[index].destinationTable != null) {
      _trays[index].updateStatus(TrayStatus.loaded);
      notifyListeners();
    }
  }

  void startDelivery() {
    for (var tray in _trays) {
      if (tray.status == TrayStatus.loaded) {
        tray.updateStatus(TrayStatus.delivering);
      }
    }
    notifyListeners();
  }

  void clearTray(int index) {
    _trays[index].clear();
    notifyListeners();
  }
}
