import Foundation

func type(_ input: String, compact: Bool = true) -> String {
    var composer = HangulComposer()
    composer.danmoeum = compact
    var document = ""
    for key in input {
        let edit = composer.takeInput(key)
        for _ in 0..<edit.0 { document.removeLast() }
        document += edit.1
    }
    return document
}

let cases = [
    ("ㄱㄱㅏ", "까"), ("ㄷㄷㅏ", "따"), ("ㅂㅂㅏ", "빠"),
    ("ㅅㅅㅏ", "싸"), ("ㅈㅈㅏ", "짜"),
    ("ㅏㅏ", "ㅑ"), ("ㅓㅓ", "ㅕ"), ("ㅗㅗ", "ㅛ"), ("ㅜㅜ", "ㅠ"),
    ("ㅐㅐ", "ㅒ"), ("ㅔㅔ", "ㅖ"),
    ("ㄱㅗㅏ", "과"), ("ㅇㅗㅏㅣ", "왜"), ("ㅇㅜㅓㅣ", "웨"),
    ("ㅎㅏㄱㄱㅗㅗ", "학교"), ("ㄱㅏㅂㅅ", "값"),
    ("ㄱㅏㅂㅅㅣ", "갑시"), ("ㄷㅏㄹㄱㅏ", "달가"),
    ("ㄱㅏㄸㅏ", "가따"), ("ㄱㅏㅃㅏ", "가빠"), ("ㄱㅏㅉㅏ", "가짜"),
    ("ㅎㅏㄴㄱㅡㄹ", "한글"), ("ㅋㅎㅎ", "ㅋㅎㅎ"), ("ㅗㅐ", "ㅙ")
]
for (input, expected) in cases {
    let actual = type(input)
    precondition(actual == expected, "\(input): \(actual) != \(expected)")
}
precondition(type("ㄱㄱ", compact: false) == "ㄱㄱ")
var composer = HangulComposer()
for key in "ㄱㅏㅂㅅ" { _ = composer.takeInput(key) }
precondition(composer.backspace()?.insert == "갑")
precondition(composer.backspace()?.insert == "가")
var slow = HangulComposer()
_ = slow.takeInput("ㄱ")
slow.allowDoubleTap = false
let separated = slow.takeInput("ㄱ")
precondition(separated.1 == "ㄱㄱ")
print("Passed \(cases.count + 4) composition checks")
