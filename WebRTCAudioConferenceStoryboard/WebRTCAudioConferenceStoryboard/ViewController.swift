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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var leaveBarButtonItem: UIBarButtonItem!
    
    let bandwidth = RTCBandwidth()

    var hasJoined = false
    
    var room: String?
    var name: String?
    
    var callers = [Caller]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bandwidth.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        updateInterface()
    }

    @IBAction func joinCall(_ sender: Any) {
        present { room, name in
            guard let room = room, let name = name else {
                return
            }
            
            self.join(room: room, name: name) { token in
                try? self.bandwidth.connect(using: token) {
                    self.bandwidth.publish(audio: true, video: false, alias: nil) {
                        DispatchQueue.main.async {
                            self.hasJoined = true
                            
                            self.room = room
                            self.name = name
                            
                            self.updateInterface()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func leaveCall(_ sender: Any) {
        bandwidth.disconnect()
        
        hasJoined = false
        
        room = nil
        name = nil
        
        callers.removeAll()
        
        updateInterface()
    }
    
    private func updateInterface() {
        joinButton.isHidden = hasJoined
        leaveBarButtonItem.isEnabled = hasJoined
        
        if let room = room, let name = name {
            title = "Conference \(room) as \(name)"
        } else {
            title = "Conference"
        }
        
        tableView.reloadData()
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
        print("streamAvailableAt", endpointId, participantId, alias ?? "---")
        
        let caller = Caller(endpointId: endpointId, participantId: participantId)
        callers.append(caller)
        
        DispatchQueue.main.async {
            self.updateInterface()
        }
    }

    func bandwidth(_ bandwidth: RTCBandwidth, streamUnavailableAt endpointId: String) {
        print("streamUnavailableAt", endpointId)
        
        guard let index = callers.firstIndex(where: { $0.endpointId == endpointId }) else {
            return
        }
        
        callers.remove(at: index)
        
        DispatchQueue.main.async {
            self.updateInterface()
        }
    }
}

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CallerCell", for: indexPath) as? CallerTableViewCell {
            let caller = callers[indexPath.row]
            cell.participantIdLabel.text = caller.participantId
            
            return cell
        }
        
        return UITableViewCell()
    }
}
