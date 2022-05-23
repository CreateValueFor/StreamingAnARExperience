//
//  Socket.swift
//  AR-Stream
//
//  Created by 이민기 on 2022/05/23.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit
import SocketIO

class SocketIOManager: NSObject {

//    static var sharedInstance = SocketIOManager(socketURL: "172.20.10.3:5500")
    
    //서버에서 메시지를 주고받을 수 있게 해주는 Socket.IO의 기본 클래스
//    var manager = SocketManager(socketURL: URL(string: "localhost...:3000")!, config: [.log(true) , .compress])
//
    var manager : SocketManager!
    var socket:SocketIOClient!
    
    //클라이언트 소캣 초기화
    init(socketURL : String) {
        manager = SocketManager(socketURL: URL(string:"ws://\(socketURL):5500")!,config: [.log(true), .compress])
        
        socket = self.manager.defaultSocket
//        SocketIOManager.sharedInstance = SocketIOManager(socketURL: socketURL)
        
        print("소켓 초기화 완료")
        
    }
    
    //MARK: 소켓 연결 시도
    func establishConnection() {
        
        socket.connect()
        socket.on("server_msg") { (dataArray, ack) in
            print(dataArray)
        }
        print("소켓 연결 시도")
        addController()
    }

    //MARK: 소켓 연결 종료
    func closeConnection() {
        
        socket.disconnect()

        print("소켓 연결 종료")
    }
    
    
    //MARK: 메세지 ㅗ보내기
    func sendMessage(msg: String){
        socket.emit("client_msg", msg)
        
    }
    
    func checkStreaming(data : Data){
        socket.emit("check")
        socket.on("check"){
            bool , _ in
            
            if(bool[0] as! Int == 1){
                self.socket.emit("data",data)
            }else{
                print("소켓 종료됨")
            }
            
            
        }
    }

    //MARK : 데이터 보내기
    func sendData(data: Data){
        socket.emit("data",data)
    }
    
    func addController(){
        socket.on("connect"){ _, _ in
            print("socket connected")
            self.socket.emit("client_msg","소켓 연결됨")
            
        }
        print("controller 생성")
        socket.on("start"){
            (data, ack) in
            print("소켓 시작됨");
        }
        
    }
    
    
    //MARK: 유저 채팅방에 연결
    func connectToServerWithNickname(nickname:String ,
                         completeHandler:(
                            @escaping ([[String:AnyObject]]) -> Void
                            )
                        )
    {
 
        //서버에 유저 아이디 전송
        socket.emit("connectUser", nickname)
 
        //서버에서 송신한 데이터 받기
        socket.on("userList") { (dataArray, ack) in
            completeHandler(dataArray[0] as! [[String:AnyObject]])
        }
        
        //유저들 입장, 퇴장 듣기
        listenForOtherMessage()
    }
        
    //MARK: 유저 채팅방에서 삭제
    func exitChatWithNickname(nickname:String, completeHandler: ()-> Void) {
        socket.emit("exitUser", nickname)
        completeHandler()
    }
    
    //MARK: 메시지 발송
    func sendMessage(message:String , withNickname nickname: String) {
        socket.emit("chatMessage" , nickname, message)
    }
    
    func getChatMessage(completHandler : ( @escaping
                                    ([String: AnyObject]) -> Void
                                  )
                
                )
    {
        
        socket.on("newChatMessage") { (dataArray, ack) in
            var msgDictionary = [String:AnyObject]()
            msgDictionary["nickname"] = dataArray[0] as! String as AnyObject
            msgDictionary["message"] = dataArray[1] as! String as AnyObject
            msgDictionary["date"] = dataArray[2] as! String as AnyObject
            
            completHandler(msgDictionary)
        }
        
    }

    /*
     두 개의 새로운 메시지(“ userConnectUpdate ”, “ userExitUpdate ”)를 듣기 위한 새로운 메소드를 구현할 것이다.
     전자는 새로운 유저의 닉네임이 서버에 전달되고 나서 연결될 때 서버에 의해 보내지는 것이다.
     반면 두 번째는 유저가 앱을 종료할 때나 유저가 Exit 버튼을 눌러서 유저리스트에서 완전히 삭제될 때 보내진다.
     */
    //MARK: 유저 입장, 퇴장, 타이핑유무 등록
    private func listenForOtherMessage(){
        //입장 - 유저 전체 리턴받음
        socket.on("userConnectUpdate") { (dataArray, ack) in
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: dataArray[0] as! [String:AnyObject])
        }
        
        //퇴장 - 퇴장한 유저명 리턴받음
        socket.on("userExitUpdate") { (dataArray, ack) in
           
            NotificationCenter.default.post(name: NSNotification.Name("userWasDisconnectedNotification"), object: dataArray[0] as! String)
        }
        
        //타이핑 유무
        socket.on("userTypingUpdate") { (dataArray, ack) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userTypingNotification"), object: dataArray[0] as? [String:AnyObject])
        }
        
        //ChatViewController.swift - viewDidLoad(_:)  -위 세 알림 관찰 메소드 작성 필요
    }
    
    //MARK:- 유저 타이핑 유무..
/*
     현재 메시지를 치고 있는 유저의 닉네임을 라벨에 보여주는 것이고 아무도 아무것도 치고 있지 않으면 이를 숨기는 기능이다.
     이를 가능하게 하기 위해서 우리는 한 유저가 타이핑을 시작하거나 멈출때 서버에 알릴 것이다.
     그리고 그 결과로 우리는 타이핑하고 있는 모든 유저의 딕셔너리를 받게 된다.
*/
    func sendStartTypingMessage(nickName: String){
        socket.emit("startType", nickName)
    }
    
    func sendStopTypingMessage(nickName:String){
        socket.emit("stopType", nickName)
    }
}
