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

/// - Tag: ViewController
class ViewController: UIViewController, ARSessionDelegate {
        
    // MARK: - Properties
    @IBOutlet var arView: ARView!
    
    // declare scoket
    let manager  = SocketManager(socketURL: URL(string:"ws://192.168.0.22:5500")!,config: [.log(true), .compress])
    var socket:SocketIOClient!
    var socketStarted =  false
    
    
    // A weak reference to the root view controller of the overlay window.
    weak var overlayViewController: OverlayViewController?

    // Video compressor/decompressor.
    let videoProcessor = VideoProcessor()
    
    // A tracked ray cast for placing the marker.
    private var trackedRaycast: ARTrackedRaycast?

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()

            configuration.environmentTexturing = .automatic
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
               configuration.frameSemantics = .sceneDepth
            }

            return configuration
        }
        super.viewDidLoad()
        
        arView.session.delegate = self
        let configuration = buildConfigure()
        arView.session.run(configuration)
        
        
        UIApplication.shared.isIdleTimerDisabled = true
        connectSocket()
//        sendStart()
        
        
        
        

        // Configure the scene.
//        arView.scene.addAnchor(marker)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Make sure that the app delegate is of type AppDelegate")
        }
        overlayViewController = appDelegate.overlayWindow?.rootViewController as? OverlayViewController
        
        // Start ReplayKit capture and handle receiving video sample buffers.
    
        RPScreenRecorder.shared().startCapture {
            [self] (sampleBuffer, type, error) in
            if type == .video {
                guard let currentFrame = arView.session.currentFrame else { return }
                
                
                videoProcessor.compressAndSend(currentFrame.sceneDepth?.depthMap!, arFrame: currentFrame){
                    (data) in
                    self.socket.emit("data",data)
                }
                
                
                videoProcessor.compressAndSend(sampleBuffer, arFrame: currentFrame) {
                    (data) in
                        guard let depthData = currentFrame.sceneDepth  else {return}
                        guard let capturedImage = currentFrame.capturedImage else {return}
//                    let depthMap = DepthMapData(depthData: depthData)
//                    let jsonDepthMap =  JSONSerialization.jsonObject(with: depthData.depthMap)
                    print(depthData.depthMap)
//                        self.socket.emit("data", data)

//                    self.socket.emit("data",depthData)
                    

                    

                }
            }
        }
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        <#code#>
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that occurs.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { [self] _ in
                alertController.dismiss(animated: true, completion: nil)
                guard let configuration = arView.session.configuration else {
                    fatalError("ARSession does not have a configuration.")
                }
                print(configuration.frameSemantics)
                configuration.frameSemantics.insert(.sceneDepth)
                
                
                arView.session.run(configuration)
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func connectSocket(){
        socket = manager.defaultSocket
        socket.connect()
        if(socket.status == .connected){
            print("소켓 연결 성공")
        }
    }
    
    func disconnectSocket(){
        socket.disconnect()
        if(socket.status == .disconnected){
            print("소켓 종료 성공")
        }
        
    }
    
    
    func sendStart(){
        self.socketStarted = true
        
        arView.session.delegate = self
        print(self.socketStarted)
        RPScreenRecorder.shared().startCapture {
            [self] (sampleBuffer, type, error) in
            if type == .video {
                guard let currentFrame = arView.session.currentFrame else { return }
                videoProcessor.compressAndSend(sampleBuffer, arFrame: currentFrame) {
                    (data) in
                    
                    self.socket.emit("data", data)
                    
                    
//                    print(data)
                        
                }
            }
        }
    }
    
    func stopSend(){
        RPScreenRecorder.shared().stopCapture{error in
                print("녹화 종료")
            if error != nil{
                print("에러 발생 \(error?.localizedDescription ?? "Unknown Error")")
            }
        }
        self.socketStarted = false
        print(self.socketStarted)
    }
}
