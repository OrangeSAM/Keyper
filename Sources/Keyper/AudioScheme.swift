import Foundation

/// Audio scheme data model - matches the schemes.json format from original Tickeys
struct AudioScheme: Codable {
    let name: String
    let displayName: String
    let files: [String]
    let nonUniqueCount: Int
    let keyAudioMap: [String: Int]

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case files
        case nonUniqueCount = "non_unique_count"
        case keyAudioMap = "key_audio_map"
    }

    /// Get the audio file index for a given keyCode
    /// - Special keys (Enter, Space, etc.) use key_audio_map
    /// - Other keys map deterministically using keyCode % non_unique_count (1:1 with original Tickeys)
    func audioIndex(forKeyCode keyCode: Int) -> Int {
        let keyStr = String(keyCode)
        if let mappedIndex = keyAudioMap[keyStr] {
            return mappedIndex
        }
        guard nonUniqueCount > 0 else { return 0 }
        return abs(keyCode) % nonUniqueCount
    }
}
