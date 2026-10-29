import UIKit
import SwiftUI
import AudioToolbox

final class KeyboardViewController: UIInputViewController {
    private var preferences = SettingsStore.load()
    private var repeatTimer: Timer?
    private var deletedDuringPress = false
    private var settingsHost: UIViewController?
    private var composer = HangulComposer()
    private var lastInputTime = Date.distantPast
    private var korean = true
    private var shift = false
    private var symbols = false
    private var extraSymbols = false
    private let shiftedKorean = ["ㅂ": "ㅃ", "ㅈ": "ㅉ", "ㄷ": "ㄸ", "ㄱ": "ㄲ", "ㅅ": "ㅆ", "ㅐ": "ㅒ", "ㅔ": "ㅖ", "ㅗ": "ㅛ", "ㅓ": "ㅕ", "ㅏ": "ㅑ", "ㅜ": "ㅠ"]
    private let compactRows = [
        ["ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ", "ㅗ", "ㅐ", "ㅔ"],
        ["ㅁ", "ㄴ", "ㅇ", "ㄹ", "ㅎ", "ㅓ", "ㅏ", "ㅣ"],
        ["ㅋ", "ㅌ", "ㅊ", "ㅍ", "ㅜ", "ㅡ"]
    ]
    private let symbolRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["-", "/", ":", ";", "(", ")", "₩", "&", "@", "\""],
        [".", ",", "?", "!", "'", "~", "_"]
    ]
    private let extraSymbolRows = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
        ["\\", "|", "<", ">", "$", "€", "£", "¥", "•", "`"],
        ["…", "♥", "★", "☆", "○", "●", "※"]
    ]
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
    private var backgroundMaterial: UIVisualEffectView?

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
        backgroundMaterial?.removeFromSuperview()
        backgroundMaterial = nil
        view.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1) : UIColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1) }
        if preferences.modernAppearance ?? true {
            view.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(red: 0.886, green: 0.89, blue: 0.906, alpha: 1) }
        }
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
        var rows = korean ? ((preferences.compactLayout ?? true) ? compactRows : rowsKorean) : rowsEnglish
        if symbols { rows = extraSymbols ? extraSymbolRows : symbolRows }
        if preferences.numberRow && !symbols { rows.insert(Array("1234567890").map(String.init), at: 0) }
        for (index, keys) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = preferences.gap
            row.distribution = .fillEqually
            if preferences.modernAppearance ?? true, index == rows.count - 2 {
                row.isLayoutMarginsRelativeArrangement = true
                row.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            }
            if index == rows.count - 1 {
                row.addArrangedSubview(button(symbols ? (extraSymbols ? "123" : "#+=") : "⇧", action: #selector(toggleShift), special: true))
            }
            keys.forEach { key in
                let title = shift && !symbols ? (korean ? (shiftedKorean[key] ?? key) : key.uppercased()) : key
                row.addArrangedSubview(button(title, action: #selector(typeKey)))
            }
            if index == rows.count - 1 { row.addArrangedSubview(button("⌫", action: #selector(deleteKey), special: true)) }
            rootStack.addArrangedSubview(row)
        }
        let bottom = UIStackView()
        bottom.axis = .horizontal
        bottom.spacing = preferences.gap
        bottom.distribution = .fill
        let symbolKey = button(symbols ? (korean ? "한" : "ABC") : "123", action: #selector(toggleSymbols), special: true)
        bottom.addArrangedSubview(symbolKey)
        symbolKey.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: 0.145).isActive = true
        symbolKey.accessibilityLabel = symbols ? "문자 키보드로 돌아가기" : "숫자 및 특수문자"
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
        bottom.addArrangedSubview(language)
        language.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: style == .full ? 0.14 : 0.10).isActive = true
        if !(preferences.modernAppearance ?? true) {
            let comma = button(",", action: #selector(typeKey))
            comma.widthAnchor.constraint(equalToConstant: 30).isActive = true
            bottom.addArrangedSubview(comma)
        }
        bottom.addArrangedSubview(button("space", action: #selector(spaceKey)))
        if !(preferences.modernAppearance ?? true) {
            let period = button(".", action: #selector(typeKey))
            period.widthAnchor.constraint(equalToConstant: 30).isActive = true
            bottom.addArrangedSubview(period)
        }
        let enter = button("↵", action: #selector(returnKey), special: true)
        bottom.addArrangedSubview(enter)
        enter.widthAnchor.constraint(equalTo: bottom.widthAnchor, multiplier: 0.19).isActive = true
        rootStack.addArrangedSubview(bottom)
    }

    private func button(_ title: String, action: Selector, special: Bool = false) -> UIButton {
        let b = KeyboardKey(frame: .zero)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: title == "space" ? 15 : preferences.font, weight: preferences.bold ? .bold : .regular)
        b.setTitleColor(.label, for: .normal)
        b.backgroundColor = UIColor { trait in
            if special { return trait.userInterfaceStyle == .dark ? UIColor(white: 0.34, alpha: 1) : UIColor(white: 0.68, alpha: 1) }
            return trait.userInterfaceStyle == .dark ? UIColor(white: 0.35, alpha: 1) : .white
        }
        b.layer.cornerRadius = preferences.radius
        b.layer.cornerCurve = .continuous
        if preferences.modernAppearance ?? true {
            b.layer.cornerRadius = preferences.radius
            b.restingColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark ? UIColor(white: 0.28, alpha: 1) : .white
            }
            b.pressedColor = .systemGray3
            b.layer.borderWidth = 0
            b.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).resolvedColor(with: traitCollection).cgColor
            b.layer.shadowColor = UIColor.black.cgColor
            b.layer.shadowOffset = CGSize(width: 0, height: 1)
            b.layer.shadowRadius = 0.5
            b.layer.shadowOpacity = 0
            b.tintColor = .label
            if let icon = KeyboardIcons.image(for: title) {
                b.setTitle(nil, for: .normal)
                b.setImage(icon, for: .normal)
                b.accessibilityLabel = title == "⌫" ? "삭제" : (title == "⇧" ? "Shift" : "줄바꿈")
            }
            if title == "space" { b.setTitle(nil, for: .normal); b.accessibilityLabel = "스페이스" }
            if title == "⇧" && shift { b.restingColor = .systemGray3 }
        } else {
            b.restingColor = b.backgroundColor ?? .secondarySystemBackground
        }
        b.backgroundColor = b.restingColor
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
        // Settings need room independent of the user's compact typing height.
        // Stay within the current window in landscape and on smaller phones.
        let availableHeight = view.window?.bounds.height ?? UIScreen.main.bounds.height
        let editorHeight = min(440, max(260, availableHeight * 0.65))
        heightConstraint?.constant = editorHeight
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let host = UIHostingController(rootView: KeyboardSettingsView(isKeyboard: true))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self); settingsHost = host
        let close = UIButton(type: .system)
        close.setTitle("완료", for: .normal); close.frame = CGRect(x: 0, y: 0, width: 60, height: 32)
        close.backgroundColor = .systemBackground
        close.addTarget(self, action: #selector(closeSettings), for: .touchUpInside)
        view.addSubview(close)
        close.tag = 9041
    }
    @objc private func languageHeld(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { openSettings() }
    }
    @objc private func openSettingsAccessibly() -> Bool {
        openSettings()
        return true
    }
    @objc private func closeSettings() {
        view.viewWithTag(9041)?.removeFromSuperview()
        settingsHost?.willMove(toParent: nil); settingsHost?.view.removeFromSuperview(); settingsHost?.removeFromParent(); settingsHost = nil
        preferences = SettingsStore.load(); heightConstraint?.constant = preferences.height
        rootStack.removeFromSuperview(); setup()
    }
    private func commitComposition() {
        // Composition already exists in the document proxy; only reset local state.
        composer = HangulComposer()
        lastInputTime = .distantPast
    }

    @objc private func typeKey(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let char = title.first else { return }
        if symbols {
            commitComposition()
            textDocumentProxy.insertText(title)
            return
        }
        if !korean {
            commitComposition()
            textDocumentProxy.insertText(title)
            if shift { shift = false; rebuild() }
            return
        }
        let now = Date()
        composer.danmoeum = preferences.compactLayout ?? true
        composer.allowDoubleTap = now.timeIntervalSince(lastInputTime) <= (preferences.doubleTapWindow ?? 0.35)
        lastInputTime = now
        let edit = composer.takeInput(char)
        for _ in 0..<edit.0 { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(edit.1)
        if shift { shift = false; rebuild() }
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
    @objc private func toggleLanguage() { commitComposition(); korean.toggle(); symbols = false; shift = false; rebuild() }
    @objc private func toggleSymbols() {
        commitComposition()
        symbols.toggle()
        extraSymbols = false
        shift = false
        rebuild()
    }
    @objc private func toggleShift() {
        if symbols { extraSymbols.toggle() } else { shift.toggle() }
        rebuild()
    }
    @objc private func nextKeyboard() { commitComposition(); advanceToNextInputMode() }
}
