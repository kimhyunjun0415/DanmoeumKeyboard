import UIKit

final class KeyboardViewController: UIInputViewController {
    private var composer = HangulComposer()
    private var korean = true
    private var shift = false
    private var heightConstraint: NSLayoutConstraint?
    private let rowsKorean = [
        ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
        ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
        ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
    ]
    private let rowsEnglish = [
        Array("qwertyuiop").map(String.init),
        Array("asdfghjkl").map(String.init),
        Array("zxcvbnm").map(String.init)
    ]
    private var rootStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if heightConstraint == nil {
            let c = view.heightAnchor.constraint(equalToConstant: 260)
            c.priority = .defaultHigh
            c.isActive = true
            heightConstraint = c
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        // Changes made by other keyboards or the host app invalidate local composition.
        // Only reset if the expected composed suffix is no longer present.
        if !composer.composing.isEmpty,
           !(textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(composer.composing) {
            composer = HangulComposer()
        }
    }

    private func setup() {
        view.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1) }
        rootStack = UIStackView()
        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.distribution = .fillEqually
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        ])
        rebuild()
    }

    private func rebuild() {
        rootStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = korean ? rowsKorean : rowsEnglish
        for (index, keys) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 4
            row.distribution = .fillEqually
            if index == 2 { row.addArrangedSubview(button(korean ? "⇧" : "⇧", action: #selector(toggleShift), special: true)) }
            keys.forEach { row.addArrangedSubview(button((shift && !korean) ? $0.uppercased() : $0, action: #selector(typeKey))) }
            if index == 2 { row.addArrangedSubview(button("⌫", action: #selector(deleteKey), special: true)) }
            rootStack.addArrangedSubview(row)
        }
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = 4
        bottom.distribution = .fill
        let globe = button("🌐", action: #selector(nextKeyboard), special: true)
        globe.widthAnchor.constraint(equalToConstant: 45).isActive = true
        // Apple's keyboard-switching control supports long press for the full input-mode list.
        bottom.addArrangedSubview(globe)
        let language = button(korean ? "영어" : "한글", action: #selector(toggleLanguage), special: true)
        language.widthAnchor.constraint(equalToConstant: 49).isActive = true
        bottom.addArrangedSubview(language)
        let comma = button(",", action: #selector(typeKey))
        comma.widthAnchor.constraint(equalToConstant: 30).isActive = true
        bottom.addArrangedSubview(comma)
        bottom.addArrangedSubview(button("space", action: #selector(spaceKey)))
        let period = button(".", action: #selector(typeKey))
        period.widthAnchor.constraint(equalToConstant: 30).isActive = true
        bottom.addArrangedSubview(period)
        let enter = button("↵", action: #selector(returnKey), special: true)
        enter.widthAnchor.constraint(equalToConstant: 46).isActive = true
        bottom.addArrangedSubview(enter)
        rootStack.addArrangedSubview(bottom)
    }

    private func button(_ title: String, action: Selector, special: Bool = false) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: title == "space" ? 15 : 22, weight: .regular)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = UIColor { trait in
            if special { return trait.userInterfaceStyle == .dark ? UIColor(white: 0.34, alpha: 1) : UIColor(white: 0.68, alpha: 1) }
            return trait.userInterfaceStyle == .dark ? UIColor(white: 0.35, alpha: 1) : .white
        }
        b.layer.cornerRadius = 5
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func commitComposition() {
        // Composition already exists in the document proxy; only reset local state.
        composer = HangulComposer()
    }

    @objc private func typeKey(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let char = title.first else { return }
        if !korean {
            commitComposition()
            textDocumentProxy.insertText(title)
            if shift { shift = false; rebuild() }
            return
        }
        let edit = composer.takeInput(char)
        for _ in 0..<edit.0 { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(edit.1)
    }

    @objc private func deleteKey() {
        if let edit = composer.backspace() {
            for _ in 0..<edit.deleteCount { textDocumentProxy.deleteBackward() }
            if !edit.insert.isEmpty { textDocumentProxy.insertText(edit.insert) }
        } else { textDocumentProxy.deleteBackward() }
    }

    @objc private func spaceKey() { commitComposition(); textDocumentProxy.insertText(" ") }
    @objc private func returnKey() { commitComposition(); textDocumentProxy.insertText("\n") }
    @objc private func toggleLanguage() { commitComposition(); korean.toggle(); shift = false; rebuild() }
    @objc private func toggleShift() { shift.toggle(); rebuild() }
    @objc private func nextKeyboard() { commitComposition(); advanceToNextInputMode() }
}
