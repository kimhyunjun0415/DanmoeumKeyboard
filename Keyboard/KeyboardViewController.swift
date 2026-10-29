import UIKit
import SwiftUI
import AudioToolbox

final class KeyboardViewController: UIInputViewController {
    private var preferences = SettingsStore.load()
    private var repeatTimer: Timer?
    private var deletedDuringPress = false
    private var settingsHost: UIViewController?
    private var composer = HangulComposer()
    private var korean = true
    private var shift = false
    private var heightConstraint: NSLayoutConstraint?
    private let rowsKorean = [
        ["ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"],
        ["ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"],
        ["ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ"]
    ]
   private let rowsEnglish: [[String]] = [
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
        ["z", "x", "c", "v", "b", "n", "m"]
]
    private var rootStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        preferences = SettingsStore.load()
        heightConstraint?.constant = preferences.height
        rootStack.removeFromSuperview()
        setup()
        if heightConstraint == nil {
            let c = view.heightAnchor.constraint(equalToConstant: preferences.height)
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
        rootStack.spacing = preferences.rowGap
        overrideUserInterfaceStyle = preferences.dark ? .dark : .unspecified
        rootStack.distribution = .fillEqually
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: preferences.margin),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -preferences.margin),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        ])
        rebuild()
    }

    private func rebuild() {
        stopDeleting()
        rootStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var rows = korean ? rowsKorean : rowsEnglish
        if preferences.numberRow { rows.insert(Array("1234567890").map(String.init), at: 0) }
        for (index, keys) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = preferences.gap
            row.distribution = .fillEqually
            if index == rows.count - 1 { row.addArrangedSubview(button(korean ? "⇧" : "⇧", action: #selector(toggleShift), special: true)) }
            keys.forEach { row.addArrangedSubview(button((shift && !korean) ? $0.uppercased() : $0, action: #selector(typeKey))) }
            if index == rows.count - 1 { row.addArrangedSubview(button("⌫", action: #selector(deleteKey), special: true)) }
            rootStack.addArrangedSubview(row)
        }
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = preferences.gap
        bottom.distribution = .fill
        let style = preferences.languageKeyStyle ?? .short
        let languageTitle = style == .full ? (korean ? "영어" : "한글") : (korean ? "영" : "한")
        let language = button(languageTitle, action: #selector(toggleLanguage), special: true)
        if style == .icon {
            language.setTitle(nil, for: .normal)
            language.setImage(UIImage(systemName: "character.bubble"), for: .normal)
        }
        language.accessibilityLabel = korean ? "영어로 전환" : "한글로 전환"
        language.accessibilityHint = "길게 누르면 키보드 설정이 열립니다"
        language.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "키보드 설정 열기", target: self, selector: #selector(openSettingsAccessibly))
        ]
        let settingsPress = UILongPressGestureRecognizer(target: self, action: #selector(languageHeld(_:)))
        settingsPress.minimumPressDuration = 0.6
        settingsPress.cancelsTouchesInView = true
        language.addGestureRecognizer(settingsPress)
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
        b.titleLabel?.font = .systemFont(ofSize: title == "space" ? 15 : preferences.font, weight: preferences.bold ? .bold : .regular)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = UIColor { trait in
            if special { return trait.userInterfaceStyle == .dark ? UIColor(white: 0.34, alpha: 1) : UIColor(white: 0.68, alpha: 1) }
            return trait.userInterfaceStyle == .dark ? UIColor(white: 0.35, alpha: 1) : .white
        }
        b.layer.cornerRadius = preferences.radius
        b.addTarget(self, action: #selector(feedback), for: .touchDown)
        if title == "⌫" {
            b.accessibilityLabel = "삭제"
            b.addTarget(self, action: #selector(startDeleting), for: .touchDown)
            b.addTarget(self, action: #selector(finishDeleting), for: .touchUpInside)
            b.addTarget(self, action: #selector(stopDeleting), for: [.touchUpOutside, .touchCancel, .touchDragExit])
        } else {
            b.addTarget(self, action: action, for: .touchUpInside)
        }
        return b
    }

    @objc private func feedback() {
        if preferences.haptic && hasFullAccess { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        if preferences.sound { UIDevice.current.playInputClick() }
    }
    @objc private func startDeleting() {
        stopDeleting()
        deletedDuringPress = false
        if preferences.deleteOnTouchDown ?? true {
            deleteKey()
            deletedDuringPress = true
        }
        guard preferences.repeatDelete else { return }
        let timer = Timer(timeInterval: preferences.repeatInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.deletedDuringPress = true
            self.deleteKey()
        }
        timer.fireDate = Date(timeIntervalSinceNow: preferences.repeatDelay)
        repeatTimer = timer
        // Continue firing while UIKit is tracking a held finger.
        RunLoop.main.add(timer, forMode: .common)
    }
    @objc private func stopDeleting() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
    @objc private func finishDeleting() {
        if !deletedDuringPress { deleteKey() }
        stopDeleting()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDeleting()
    }
    @objc private func openSettings() {
        stopDeleting()
        commitComposition()
        guard settingsHost == nil else { return }
        let host = UIHostingController(rootView: KeyboardSettingsView(isKeyboard: true))
        addChild(host); host.view.frame = view.bounds; host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view); host.didMove(toParent: self); settingsHost = host
        let close = UIButton(type: .system)
        close.setTitle("완료", for: .normal); close.frame = CGRect(x: 0, y: 0, width: 60, height: 32)
        close.backgroundColor = .systemBackground
        close.addTarget(self, action: #selector(closeSettings), for: .touchUpInside); host.view.addSubview(close)
    }
    @objc private func languageHeld(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { openSettings() }
    }
    @objc private func openSettingsAccessibly() -> Bool {
        openSettings()
        return true
    }
    @objc private func closeSettings() {
        settingsHost?.willMove(toParent: nil); settingsHost?.view.removeFromSuperview(); settingsHost?.removeFromParent(); settingsHost = nil
        preferences = SettingsStore.load(); heightConstraint?.constant = preferences.height
        rootStack.removeFromSuperview(); setup()
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

    @objc private func spaceKey() { commitComposition()
        if preferences.doubleSpace && (textDocumentProxy.documentContextBeforeInput ?? "").hasSuffix(" ") {
            textDocumentProxy.deleteBackward(); textDocumentProxy.insertText(". ")
        } else { textDocumentProxy.insertText(" ") } }
    @objc private func returnKey() { commitComposition(); textDocumentProxy.insertText("\n") }
    @objc private func toggleLanguage() { commitComposition(); korean.toggle(); shift = false; rebuild() }
    @objc private func toggleShift() { shift.toggle(); rebuild() }
    @objc private func nextKeyboard() { commitComposition(); advanceToNextInputMode() }
}
