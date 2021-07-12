import 'dart:convert';

import 'package:webim/src/message.dart';

/// [Message] response parser

class MessageResponse {
  Map<dynamic, dynamic> json;
  MessageResponse.fromJson(dynamic row) {
    json = (row is String) ? jsonDecode(row) : row;
  }
  Message transform() {
    return Message(
      canBeEdited: json['canBeEdited'],
      canBeReplied: json['canBeReplied'],
      clientSideId: json['clientSideId']['id'],
      isEdited: json['edited'],
      isReadByOperator: json['readByOperator'],
      isSavedInHistory: json['savedInHistory'],
      sendStatus: json['sendStatus'] == 'SENT' ? SendStatus.SENT : SendStatus.SENDING,
      senderName: json['senderName'],
      serverSideId: json['serverSideId'],
      text: json['text'],
      time: DateTime.fromMicrosecondsSinceEpoch(json['timeMicros']),
      type: _MessageTypeResponse.fromString(json['type']).transform,
    );
  }
}

/// List<[Message]> response parser

class ListMessageResponse {
  List<dynamic> json;
  ListMessageResponse.fromJson(dynamic row) {
    json = (row is String) ? jsonDecode(row) : row;
  }

  List<Message> transform() {
    return json.map((e) => MessageResponse.fromJson(e).transform()).toList();
  }
}

/// [MessageType] response parser
class _MessageTypeResponse {
  MessageType _type;
  _MessageTypeResponse.fromString(String row) {
    switch (row) {
      case 'ACTION_REQUEST':
        _type = MessageType.ACTION_REQUEST;
        break;
      case 'CONTACT_REQUEST':
        _type = MessageType.CONTACT_REQUEST;
        break;
      case 'FILE_FROM_OPERATOR':
        _type = MessageType.FILE_FROM_OPERATOR;
        break;
      case 'FILE_FROM_VISITOR':
        _type = MessageType.FILE_FROM_VISITOR;
        break;
      case 'INFO':
        _type = MessageType.INFO;
        break;
      case 'KEYBOARD':
        _type = MessageType.KEYBOARD;
        break;
      case 'KEYBOARD_RESPONSE':
        _type = MessageType.KEYBOARD_RESPONSE;
        break;
      case 'OPERATOR':
        _type = MessageType.ACTION_REQUEST;
        break;
      case 'OPERATOR_BUSY':
        _type = MessageType.OPERATOR_BUSY;
        break;
      case 'STICKER_VISITOR':
        _type = MessageType.STICKER_VISITOR;
        break;
      case 'VISITOR':
        _type = MessageType.VISITOR;
    }
  }
  MessageType get transform => _type;
}
