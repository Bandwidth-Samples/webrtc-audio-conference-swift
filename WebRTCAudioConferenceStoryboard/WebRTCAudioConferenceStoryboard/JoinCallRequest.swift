//
//  JoinCallRequest.swift
//  WebRTCAudioConferenceStoryboard
//
//  Created by Michael Hamer on 1/27/21.
//

import Foundation

struct JoinCallRequest: Encodable {
    let room: String
    let audio: Bool
    let video: Bool
    let caller: JoinCallRequestCaller
}
