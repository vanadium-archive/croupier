class LogWriter {
  final Function updateCallback; // Takes in Map<String, String> data
  LogWriter(this.updateCallback);

  Map<String, String> _data;
  void write(Map<String, String> data) {
    _data = data;
    updateCallback(_data);
  }
}
