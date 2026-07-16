import 'dart:async';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  FakeWebSocketChannel({Future<void>? ready, this.throwsOnAdd = false})
    : _ready = ready ?? Future.value(),
      _outgoing = StreamController<dynamic>.broadcast() {
    _sink = FakeWebSocketSink(_outgoing.sink, throwsOnAdd: throwsOnAdd);
  }

  final bool throwsOnAdd;
  final Future<void> _ready;
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final StreamController<dynamic> _outgoing;
  late final FakeWebSocketSink _sink;

  void add(dynamic value) => _incoming.add(value);

  void addError(Object error, [StackTrace? stackTrace]) =>
      _incoming.addError(error, stackTrace);

  Stream<dynamic> get outgoingStream => _outgoing.stream;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  FakeWebSocketSink get sink => _sink;

  @override
  Future<void> get ready => _ready;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class FakeWebSocketSink extends DelegatingStreamSink<dynamic>
    implements WebSocketSink {
  FakeWebSocketSink(super.sink, {this.throwsOnAdd = false});

  final bool throwsOnAdd;
  bool closed = false;

  @override
  Future close([int? closeCode, String? closeReason]) {
    closed = true;
    return super.close();
  }

  @override
  void add(dynamic value) {
    if (throwsOnAdd) throw StateError('sink is closed');
    super.add(value);
  }
}
