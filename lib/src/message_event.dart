
import 'package:flutter/foundation.dart';

import 'package:webim/webim.dart';

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