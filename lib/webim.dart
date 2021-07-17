import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:webim/src/message.dart';
import 'package:webim/src/message_event_response.dart';
import 'package:webim/src/message_response.dart';

export 'package:webim/src/message.dart';

const _methodChannelName = 'webim';
const _methodEventStreamName = 'webim.stream';

class Webim {
  static const MethodChannel _channel = const MethodChannel(_methodChannelName);
  // static EventChannel _messageStreamChannel;

  static final messageEventController = StreamController<MessageEvent>.broadcast();

  static final eventListenable = MessageEventListenableDelegate();

  static StreamSubscription messageStreamSubscription;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> buildSession({
    @required String accountName,
    @required String locationName,
    String visitorFields,
  }) async {
    _setMessageStreamListener();
    final session = await _channel.invokeMethod(
      'buildSession',
      {
        'ACCOUNT_NAME': accountName,
        'LOCATION_NAME': locationName,
        'VISITOR': visitorFields,
      },
    );
    return session.toString();
  }

  static FutureOr<void> resumeSession() async {
    return await _channel.invokeMethod('resumeSession');
  }

  static FutureOr<void> pauseSession() async {
    return await _channel.invokeMethod('pauseSession');
  }

  static FutureOr<void> disposeSession() async {
    return await _channel.invokeMethod('disposeSession');
  }

  static Future<String> sendMessage({
    @required String message,
  }) async {
    final response = await _channel.invokeMethod('sendMessage', {'MESSAGE': message});
    return response.toString();
  }

  static Future<List<Message>> getLastMessages({
    @required int limit,
  }) async {
    final response = await _channel.invokeMethod('getLastMessages', {'LIMIT': limit});
    return ListMessageResponse.fromJson(response).transform();
  }

  static void _setMessageStreamListener() {
    messageStreamSubscription =
        EventChannel(_methodEventStreamName).receiveBroadcastStream().listen(
      (row) {
        try {
          final event = MessageEventResponse(row).transform();
          if (event != null) {
            messageEventController.sink.add(event);
            eventListenable.value = event;
          }
        } catch (e) {
          messageEventController.addError(e);
        }
      },
      onError: (e) => messageEventController.addError(e),
    );
  }

  static void disposeMessageStreamSubscription() {
    messageStreamSubscription?.cancel();
  }
}

class MessageEventListenableDelegate implements ValueListenable {
  static final _eventListenerList = List<Function>();

  static MessageEvent _lastEvent;

  @override
  void addListener(void Function() listener) {
    _eventListenerList.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    if (!_eventListenerList.contains(listener)) return;
    _eventListenerList.remove(listener);
  }

  @override
  get value => _lastEvent;

  set value(MessageEvent event) {
    _lastEvent = event;
    _eventListenerList.forEach((listener) => listener());
  }

  void clearListenerList() {
    _eventListenerList.clear();
  }
}

abstract class MessageEvent {
  factory MessageEvent.removedAll() => MessageEventRemovedAll();
  factory MessageEvent.removed(Message message) => MessageEventRemoved(message);
  factory MessageEvent.added(Message message) => MessageEventAdded(message);
  factory MessageEvent.changed({
    @required Message from,
    @required Message to,
  }) =>
      MessageEventChanged(from, to);
}

@immutable
class MessageEventAdded implements MessageEvent {
  const MessageEventAdded(this.message);
  final Message message;
}

@immutable
class MessageEventChanged implements MessageEvent {
  const MessageEventChanged(this.from, this.to);
  final Message from;
  final Message to;
}

@immutable
class MessageEventRemoved implements MessageEvent {
  const MessageEventRemoved(this.message);
  final Message message;
}

@immutable
class MessageEventRemovedAll implements MessageEvent {}
