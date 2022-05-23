/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main ViewController of the sample app.
*/

import RealityKit
import MultipeerConnectivity
import MetalKit
import ReplayKit
import ARKit
import SocketIO
import CoreVideo

/// - Tag: ViewController
class ViewController: UIViewController, ARSessionDelegate {
        
    // MARK: - Properties
    @IBOutlet var arView: ARView!
    
    
    // declare scoket
    var manager: SocketManager!
//    let manager  = SocketManager(socketURL: URL(string:"ws://172.20.10.3:5500")!,config: [.log(true), .compress])
    var socket:SocketIOClient!
    
    
    
    weak var overlayViewController: OverlayViewController?


    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.session.delegate = self
        let configuration = buildConfigure()
        
        arView.session.run(configuration)
        
        
        UIApplication.shared.isIdleTimerDisabled = true
//        connectSocket()

        // Configure the scene.

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Make sure that the app delegate is of type AppDelegate")
        }
        overlayViewController = appDelegate.overlayWindow?.rootViewController as? OverlayViewController
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        guard let depthMap = frame.sceneDepth?.depthMap else {return}
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0));
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        if let srcBuffer = CVPixelBufferGetBaseAddress(depthMap) {
            let data = Data(bytes: srcBuffer, count: bytesPerRow * height)
            if(socket != nil){
                socket.emit("data",data)
            }
            
        }
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    func buildConfigure() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()

        configuration.environmentTexturing = .automatic
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
           configuration.frameSemantics = .sceneDepth
        }

        return configuration
    }
    
    
    // 소켓
    
    func connectSocket(){
        print("소켓연결시작")
        socket = manager.defaultSocket
        socket.connect()
        
    }
    
    func emitSave(){
        socket = manager.defaultSocket

        socket.disconnect()
        if(socket.status == .disconnected){
            print("소켓 종료 성공")
        }
        
    }
    
    
    func sendStart(){
        arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        self.arView.session.delegate = self
        let configuration = buildConfigure()
        self.arView.session.run(configuration)
    }
    
    func stopSend(){
        self.arView.session.pause()
        
        socket.emit("save")
        socket.disconnect()
    }
    
    func getInternalIP(socketIP : String){
        manager = SocketManager(socketURL: URL(string:"ws://\(socketIP):5500")!,config: [.log(true), .compress])
        connectSocket()
        
    }
    
    
}
