/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The overlay view controller of the sample app.
*/

import UIKit
import MetalKit

///- Tag: OverlayViewController
class OverlayViewController: UIViewController {
    
    var delegate: ViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = ViewController()
    }
    
    @IBAction func connectSocket(_ sender: UIButton) {
        // 소켓 연결 구현
        delegate?.connectSocket()
    }
    
    @IBAction func disConnectSocket(_ sender: UIButton) {
        delegate?.disconnectSocket()
    }
    @IBAction func sendStart(_ sender: UIButton) {
        // 소켓 송신 구현
        delegate?.sendStart()
    }
    
    @IBAction func sendStop(_ sender: UIButton) {
        // 소켓 송신 종료 구현
        delegate?.stopSend()
    }
    
    
    
}
