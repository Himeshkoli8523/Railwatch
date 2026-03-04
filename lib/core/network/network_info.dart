abstract class NetworkInfo {
  bool get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl({bool initialConnected = true})
    : _isConnected = initialConnected;

  bool _isConnected;

  @override
  bool get isConnected => _isConnected;

  void setConnected(bool value) {
    _isConnected = value;
  }
}
