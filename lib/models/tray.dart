enum TrayStatus { empty, loaded, delivering }

class Tray {
  final int id;
  TrayStatus status;
  String? destinationTable;

  Tray({
    required this.id,
    this.status = TrayStatus.empty,
    this.destinationTable,
  });

  void updateStatus(TrayStatus newStatus) {
    status = newStatus;
  }

  void setDestination(String table) {
    destinationTable = table;
    status = TrayStatus.loaded;
  }

  void clear() {
    status = TrayStatus.empty;
    destinationTable = null;
  }
}
