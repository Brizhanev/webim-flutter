import Flutter
import UIKit
import WebimClientLibrary

let methodChannelName = "webim"
let eventStreamChannelName = "webim.stream"

public class SwiftWebimPlugin: NSObject, FlutterPlugin, WebimLogger {
    
    static var  session: WebimSession?
    static let messageStreamHandler = WebimMessageListener()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        let instance = SwiftWebimPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let eventStreamChannel = FlutterEventChannel(name: eventStreamChannelName, binaryMessenger: registrar.messenger())
        eventStreamChannel.setStreamHandler(messageStreamHandler)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            getPlatformVersion (call, result: result)
        case "buildSession":
            buildSession (call, result: result)
        case "pauseSession":
            pauseSession (result: result)
        case "resumeSession":
            resumeSession (result: result)
        case "disposeSession":
            destroySession (result: result)
        case "sendMessage":
            sendMessage (call, result: result)
        case "getLastMessages":
            getLastMessages (call, result: result)
        default:
            print("not implemented")
        }
        
    }
    
    private func getPlatformVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        result("iOS! " + UIDevice.current.systemVersion)
    }
    
    private func resumeSession(result: @escaping FlutterResult){
        if(SwiftWebimPlugin.session == nil) {
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Session not exist",
                    details: nil))
        }
        do{
            try SwiftWebimPlugin.session?.resume()
            _ = try SwiftWebimPlugin.session?.getStream().newMessageTracker(messageListener: SwiftWebimPlugin.messageStreamHandler)
        }catch{
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Resume session failed",
                    details: nil))
            
        }
        result(nil)
    }
    
    private func pauseSession(result: @escaping FlutterResult){
        if(SwiftWebimPlugin.session == nil) {
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Session not exist",
                    details: nil))
        }
        do{
            try SwiftWebimPlugin.session?.pause()
        }catch{
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Pause session failed",
                    details: nil))
            
        }
        result(nil)
    }
    
    private func destroySession(result: @escaping FlutterResult){
        do{
            try SwiftWebimPlugin.session?.destroy()
            
        }catch{
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Pause session failed",
                    details: nil))
            
        }
        result(nil)
    }
    
    
    private func getLastMessages(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        let args = call.arguments as! [String: Any]
        let limit = args["LIMIT"] as! Int
        
        let tracker = try? SwiftWebimPlugin.session?.getStream().newMessageTracker(messageListener: WebimMessageListener())
        
        try? tracker?.getLastMessages(byLimit: limit, completion: {(messages: [Message]) -> Void in self.complete(messages, result)})
    }
    
    private func complete(_ messages: [Message],_  result: @escaping FlutterResult) -> Void {
        
        do{
            let json = try JSONSerialization.data(withJSONObject: messages.map{item in item.toJson()}, options: .prettyPrinted)
            
            result(String(data: json, encoding: .utf8))
        }catch {
            result(FlutterError(
                    code: FlutterPluginEnum.failure,
                    message: "Json serialization of messase failed",
                    details: nil))
        }
    }
    
    private func sendMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        let args = call.arguments as! [String: Any]
        let message = args["MESSAGE"] as! String
        
        let response = try? SwiftWebimPlugin.session?.getStream().send(message: message)
        
        result(response ?? "error")
    }
    
    private func buildSession(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        if(SwiftWebimPlugin.session != nil){
            try! SwiftWebimPlugin.session?.destroy()
        }
        let args = call.arguments as! [String: Any]
        let accountName = args["ACCOUNT_NAME"] as! String
        let locationName = args["LOCATION_NAME"] as! String
        let visitorFields = args["VISITOR"] as? String
        
        Webim.newSessionBuilder()
            .set(accountName: accountName)
            .set(location: locationName)
//            .set(visitorFieldsJSONString: visitorFields)
            .set(webimLogger: self, verbosityLevel: .verbose)
            .build(
                onSuccess: { webimSession in
                    SwiftWebimPlugin.session = webimSession
                    self.resumeSession(result: result)
                }, onError: {
                    error in
                    switch error{
                    case .nilAccountName:
                        result(FlutterError(code: FlutterPluginEnum.failure,
                                            message: "Webim session object creating failed because of passing nil account name.",
                                            details: nil))
                        
                        
                    case .nilLocation:
                        result(FlutterError(code: FlutterPluginEnum.failure,
                                            message: "Webim session object creating failed because of passing nil location name.",
                                            details: nil))
                        
                    case .invalidRemoteNotificationConfiguration:
                        result(FlutterError(code: FlutterPluginEnum.failure,
                                            message: "Webim session object creating failed because of invalid remote notifications configuration.",
                                            details: nil))
                        
                    case .invalidAuthentificatorParameters:
                        result(FlutterError(code: FlutterPluginEnum.failure,
                                            message: "Webim session object creating failed because of invalid visitor authentication system configuration.",
                                            details: nil))
                        
                    case .invalidHex:
                        result(FlutterError(code: FlutterPluginEnum.failure,
                                            message: "Webim can't parsed prechat fields",
                                            details: nil))
                        
                    case .unknown:
                        result(FlutterError(code: FlutterPluginEnum.failure,
                                            message: "Webim session object creating failed with unknown error",
                                            details: nil))
                    }
                }
            )
        
    }
    
    // MARK: - WebimLogger
    public func log(entry: String) {
        print(entry)
    }
}

class WebimMessageListener :NSObject, FlutterStreamHandler, MessageListener{
    
    private var _eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }
    
    public func added(message newMessage: Message, after previousMessage: Message?) {
        _eventSink?(["added": newMessage.toJson()])
    }
    
    public func removed(message: Message) {
        print(message)
    }
    
    public func removedAllMessages() {
        print("removedAllMessages")
    }
    
    public func changed(message oldVersion: Message, to newVersion: Message) {
        _eventSink?([
            "from": oldVersion.toJson(),
            "to": newVersion.toJson(),
        ]
        )
        print(oldVersion)
        print(newVersion)
    }
}

extension Message{
    
    func toJson() -> [String : Any]{
        
        let timeMicroseconds = (getTime().timeIntervalSince1970 * 1000000).rounded()
        
        let map =  [
            "clientSideId": ["id": getID()],
            "text": getText(),
            "currentChatId": getCurrentChatID() ?? "",
            "operatorId": getOperatorID() ?? "",
            "senderAvatarUrl":getSenderAvatarFullURL()?.absoluteString ?? "",
            "senderName":getSenderName(),
            "senderStatus":(getSendStatus() == MessageSendStatus.sent) ? "SENT" : "SENDING",
            "timeMicros": Int64(timeMicroseconds),
            "isReadOperator":isReadByOperator(),
            "canBeEdited": canBeEdited(),
            "canBeReplied": canBeReplied(),
            "edited": isEdited(),
            "readByOperator": isReadByOperator(),
            "serverSideId": getID(),
        ] as [String : Any]
        return map
    }
    
}
