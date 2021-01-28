//
//  ViewController.swift
//  WebRTCAudioConferenceStoryboard
//
//  Created by Michael Hamer on 1/25/21.
//

import UIKit
import WebRTC
import BandwidthWebRTC

class ViewController: UIViewController {
    let bandwidth = RTCBandwidth()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bandwidth.delegate = self
    }

    @IBAction func joinCall(_ sender: Any) {
        present { room, name in
            guard let room = room, let name = name else {
                return
            }
            
            self.join(room: room, name: name) { token in
                
                try? self.bandwidth.connect(using: token) {
                    
                    self.bandwidth.publish(audio: true, video: false, alias: name) {
                        
                    }
                }
                
                print(token)
            }
        }
    }
    
    private func present(completion: @escaping (String?, String?) -> ()) {
        let alert = UIAlertController(title: "Join Call", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textfield in
            textfield.placeholder = "Room"
        }
        
        alert.addTextField { textfield in
            textfield.placeholder = "Name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
            let room = alert.textFields?.first?.text
            let name = alert.textFields?.last?.text
            
            completion(room, name)
        })
        
        present(alert, animated: true)
    }
    
    private func join(room: String, name: String, completion: @escaping (String) -> ()) {
        guard let url = URL(string: "\(Configuration.default.address)/joinCall") else {
            fatalError("Could not resolve application server endpoint.")
        }
        
        let joinCallRequest = JoinCallRequest(room: room, audio: true, video: false, caller: JoinCallRequestCaller(name: name))
        
        guard let data = try? JSONEncoder().encode(joinCallRequest) else {
            fatalError("Failed to encode the join call request.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let joinCallResponse = try? JSONDecoder().decode(JoinCallResponse.self, from: data) else {
                fatalError("Failed to decode the join call response.")
            }
            
            completion(joinCallResponse.token)
        }.resume()
    }
}

extension ViewController: RTCBandwidthDelegate {
    func bandwidth(_ bandwidth: RTCBandwidth, streamAvailableAt endpointId: String, participantId: String, alias: String?, mediaTypes: [MediaType], mediaStream: RTCMediaStream?) {
        print(endpointId, participantId, alias)
    }

    func bandwidth(_ bandwidth: RTCBandwidth, streamUnavailableAt endpointId: String) {
        
    }
}
