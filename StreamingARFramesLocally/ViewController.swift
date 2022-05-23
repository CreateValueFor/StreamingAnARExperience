/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main ViewController of the sample app.
*/

import RealityKit


import ARKit
import SocketIO


/// - Tag: ViewController
class ViewController: UIViewController, ARSessionDelegate {
        
    // MARK: - Properties
    @IBOutlet var arView: ARView!
    
    var socketManager : SocketIOManager!
//    var socketManager = SocketIOManager(socketURL: "172.20.10.3");
    
    weak var overlayViewController: OverlayViewController?


    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView.session.delegate = self
        let configuration = buildConfigure()
        
        arView.session.run(configuration)
        
        
        UIApplication.shared.isIdleTimerDisabled = true
//        socketManager.establishConnection()
        
    

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
            if(socketManager != nil){
                socketManager.checkStreaming(data: data)
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
    func getInternalIP(socketIP : String){
        socketManager = SocketIOManager.init(socketURL: socketIP)
        socketManager.establishConnection()
        sendStart()
        
        
    }
    
    func sendStart(){
        let bounds: CGRect = UIScreen.main.bounds
        
        arView = ARView.init(frame: bounds)
        arView.session.delegate = self
        let configuration = buildConfigure()
        
        arView.session.run(configuration)
        
        
        
        
    }
    func stopSend(){
        arView.session.pause()
    }
    
    
    
}
