import Foundation

/// Pure Hangul composing logic. The caller replaces the most recent composing character.
struct HangulComposer {
    private let initials: [Character] = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    private let medial: [Character] = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
    private let finals: [Character] = Array(" ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
    private let doubleInitial: [Character: Character] = ["ㄱ":"ㄲ","ㄷ":"ㄸ","ㅂ":"ㅃ","ㅅ":"ㅆ","ㅈ":"ㅉ"]
    private let combineMedial: [String: Character] = [
        "ㅏㅏ":"ㅑ", "ㅓㅓ":"ㅕ", "ㅗㅗ":"ㅛ", "ㅜㅜ":"ㅠ",
        "ㅏㅣ":"ㅐ", "ㅓㅣ":"ㅔ", "ㅑㅣ":"ㅒ", "ㅕㅣ":"ㅖ",
        "ㅗㅏ":"ㅘ", "ㅗㅐ":"ㅙ", "ㅗㅣ":"ㅚ", "ㅜㅓ":"ㅝ", "ㅜㅔ":"ㅞ", "ㅜㅣ":"ㅟ", "ㅡㅣ":"ㅢ"
    ]
    private let combineFinal: [String: Character] = ["ㄱㅅ":"ㄳ", "ㄴㅈ":"ㄵ", "ㄴㅎ":"ㄶ", "ㄹㄱ":"ㄺ", "ㄹㅁ":"ㄻ", "ㄹㅂ":"ㄼ", "ㄹㅅ":"ㄽ", "ㄹㅌ":"ㄾ", "ㄹㅍ":"ㄿ", "ㄹㅎ":"ㅀ", "ㅂㅅ":"ㅄ", "ㄱㄱ":"ㄲ", "ㅅㅅ":"ㅆ"]
    private let splitFinal: [Character: (Character, Character)] = ["ㄳ":("ㄱ","ㅅ"),"ㄵ":("ㄴ","ㅈ"),"ㄶ":("ㄴ","ㅎ"),"ㄺ":("ㄹ","ㄱ"),"ㄻ":("ㄹ","ㅁ"),"ㄼ":("ㄹ","ㅂ"),"ㄽ":("ㄹ","ㅅ"),"ㄾ":("ㄹ","ㅌ"),"ㄿ":("ㄹ","ㅍ"),"ㅀ":("ㄹ","ㅎ"),"ㅄ":("ㅂ","ㅅ")]
    private var pending: [Character] = []
    private(set) var composing = ""
    private(set) var committed = ""

    mutating func input(_ key: Character) -> (deleteCount: Int, insert: String) {
        let previous = composing
        if initials.contains(key) { inputConsonant(key) }
        else if medial.contains(key) { inputVowel(key) }
        else { flush(); committed += String(key) }
        return (previous.count, committed + composing)
    }

    mutating func finish() -> (deleteCount: Int, insert: String) {
        let prev = composing
        flush()
        let output = committed
        committed = ""
        return (prev.count, output)
    }

    mutating func backspace() -> (deleteCount: Int, insert: String)? {
        if !composing.isEmpty {
            let old = composing
            if !pending.isEmpty { pending.removeLast() }
            reconstruct()
            return (old.count, composing)
        }
        return nil
    }

    private mutating func flush() {
        committed += composing
        composing = ""
        pending = []
    }

    private mutating func inputConsonant(_ c: Character) {
        if pending.isEmpty { pending = [c] }
        else if pending.count == 1, let first = pending.first, initials.contains(first), let pair = doubleInitial[first], first == c {
            pending = [pair]
        } else if pending.count == 2, medial.contains(pending[1]) {
            pending.append(c)
        } else if pending.count == 3, let combined = combineFinal[String(pending[2]) + String(c)] {
            pending[2] = combined
        } else {
            flush(); pending = [c]
        }
        reconstruct()
    }

    private mutating func inputVowel(_ v: Character) {
        if pending.isEmpty { pending = [v] }
        else if pending.count == 1, initials.contains(pending[0]) { pending.append(v) }
        else if pending.count == 1, let combined = combineMedial[String(pending[0]) + String(v)] { pending[0] = combined }
        else if pending.count == 2, let combined = combineMedial[String(pending[1]) + String(v)] { pending[1] = combined }
        else if pending.count == 3 {
            let f = pending[2]
            if let (first, second) = splitFinal[f] {
                pending[2] = first
                reconstruct(); committed += composing
                pending = [second, v]
            } else {
                pending.removeLast()
                reconstruct(); committed += composing
                pending = [f, v]
            }
        } else { flush(); pending = [v] }
        reconstruct()
    }

    private mutating func reconstruct() {
        if pending.isEmpty { composing = ""; return }
        if pending.count >= 2, let l = initials.firstIndex(of: pending[0]), let v = medial.firstIndex(of: pending[1]) {
            let t = pending.count > 2 ? (finals.firstIndex(of: pending[2]) ?? 0) : 0
            composing = String(UnicodeScalar(0xAC00 + (l * 21 + v) * 28 + t)!)
        } else { composing = String(pending[0]) }
    }

    mutating func takeInput(_ key: Character) -> (Int, String) {
        committed = ""
        let result = input(key)
        committed = ""
        return (result.deleteCount, result.insert)
    }
}
