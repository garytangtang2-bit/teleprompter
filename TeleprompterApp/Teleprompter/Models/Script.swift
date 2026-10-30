import Foundation

struct Script: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var body: String
    var updatedAt = Date()
}

extension String {
    /// Puts every sentence on its own line (splits after 。！？!?；).
    /// Existing line breaks are kept; closing quotes and brackets stay with their sentence.
    func splitIntoSentenceLines() -> String {
        let terminators: Set<Character> = ["。", "！", "？", "!", "?", "；"]
        let closers: Set<Character> = ["」", "』", "”", "’", "）", ")", "】", "》", "。", "！", "？", "!", "?"]
        let chars = Array(self)
        var result = ""
        var i = 0
        while i < chars.count {
            let c = chars[i]
            result.append(c)
            if terminators.contains(c) {
                var j = i + 1
                while j < chars.count, closers.contains(chars[j]) {
                    result.append(chars[j])
                    j += 1
                }
                while j < chars.count, chars[j] == " " || chars[j] == "\u{3000}" {
                    j += 1
                }
                if j < chars.count, chars[j] != "\n" {
                    result.append("\n")
                }
                i = j
                continue
            }
            i += 1
        }
        return result
    }
}
