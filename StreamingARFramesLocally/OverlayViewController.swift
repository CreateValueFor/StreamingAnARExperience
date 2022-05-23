/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The overlay view controller of the sample app.
*/

import UIKit
import MetalKit
import SocketIO

///- Tag: OverlayViewController
class OverlayViewController: UIViewController {
    
    var delegate: ViewController?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = ViewController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let alert = UIAlertController(title: "서버 주소를 입력해주세요", message: "", preferredStyle: .alert)
        alert.addTextField{(textField) in
            
            textField.placeholder = "ex) 172.20.10.3"
        }
        let ok = UIAlertAction(title: "OK", style: .default){ (ok) in
            guard let socketIP = alert.textFields?[0].text else {return}
            
            self.delegate?.getInternalIP(socketIP: socketIP)
        }
        
        let cancel = UIAlertAction(title: "cancel", style: .cancel){ (cancel) in
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(0)
            }
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func connectSocket(_ sender: UIButton) {
        // 소켓 연결 구현
        delegate?.socketManager.establishConnection()
    }
    
    @IBAction func disConnectSocket(_ sender: UIButton) {
        
        delegate?.socketManager.closeConnection()
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
