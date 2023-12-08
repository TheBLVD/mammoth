//
//  Sound.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 01/02/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import AVKit

class Sound {
    func playSound(named: String, withVolume: Float) {
        if GlobalStruct.soundsEnabled && !Mute.shared.isMute {
            if let path = Bundle.main.path(forResource: "\(named)", ofType: "wav") {
                let sound = URL(fileURLWithPath: path)
                do {
                    GlobalStruct.audioPlayer = try AVAudioPlayer(contentsOf: sound)
                    GlobalStruct.audioPlayer.setVolume(withVolume, fadeDuration: TimeInterval(1))
                    GlobalStruct.audioPlayer.play()
                } catch {
                    log.error("couldn't load sound file or failed to set audio session category: \(error)")
                }
            }
        }
    }
}
