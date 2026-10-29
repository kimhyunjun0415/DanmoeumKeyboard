import SwiftUI
import UIKit

enum LanguageKeyStyle: String, Codable, CaseIterable {
    case short, full, icon
    var label: String {
        switch self {
        case .short: return "영 / 한"
        case .full: return "영어 / 한글"
        case .icon: return "시스템 아이콘"
        }
    }
}

struct KeyboardSettings: Codable {
    var height = 260.0, gap = 4.0, rowGap = 7.0, font = 22.0, margin = 4.0, radius = 5.0
    var bold = false, dark = false, haptic = false, sound = false, numberRow = false
    var repeatDelete = true, repeatDelay = 0.45, repeatInterval = 0.09
    var doubleSpace = false
    // Optional fields keep settings saved by earlier versions readable.
    var languageKeyStyle: LanguageKeyStyle? = .short
    var deleteOnTouchDown: Bool? = true
}

enum SettingsStore {
    // Set this Info.plist key in BOTH targets only when both signed entitlements permit it.
    static var shared: UserDefaults? {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "KeyboardAppGroup") as? String,
              FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil else { return nil }
        return UserDefaults(suiteName: id)
    }
    static var defaults: UserDefaults { shared ?? .standard }
    static func load() -> KeyboardSettings {
        guard let data = defaults.data(forKey: "keyboard.settings.v1"),
              let value = try? JSONDecoder().decode(KeyboardSettings.self, from: data) else { return KeyboardSettings() }
        return value
    }
    static func save(_ value: KeyboardSettings) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: "keyboard.settings.v1") }
    }
    static func code(_ value: KeyboardSettings) -> String {
        (try? JSONEncoder().encode(value).base64EncodedString()) ?? ""
    }
    static func importCode(_ text: String) -> KeyboardSettings? {
        guard text.utf8.count < 8192, let data = Data(base64Encoded: text),
              let s = try? JSONDecoder().decode(KeyboardSettings.self, from: data),
              (180...400).contains(s.height), (0...12).contains(s.gap),
              (0...16).contains(s.rowGap), (12...32).contains(s.font),
              (0...24).contains(s.margin), (0...20).contains(s.radius),
              (0.2...1).contains(s.repeatDelay), (0.04...0.3).contains(s.repeatInterval) else { return nil }
        return s
    }
}

struct KeyboardSettingsView: View {
    @State private var settings = SettingsStore.load()
    @State private var transfer = ""
    @State private var message = ""
    var changed: (() -> Void)?
    var body: some View {
        Form {
            Section("크기와 간격") {
                slider("키보드 높이", $settings.height, 180...400)
                slider("키 가로 간격", $settings.gap, 0...12)
                slider("행 간격", $settings.rowGap, 0...16)
                slider("좌우 여백", $settings.margin, 0...24)
                slider("글자 크기", $settings.font, 12...32)
                slider("모서리", $settings.radius, 0...20)
                Toggle("숫자 행", isOn: $settings.numberRow)
            }
            Section("디자인과 피드백") {
                Toggle("굵은 글씨", isOn: $settings.bold)
                Toggle("다크 테마 (끄면 시스템 테마)", isOn: $settings.dark)
                Toggle("진동 (기기 및 권한에 따라 제한)", isOn: $settings.haptic)
                Toggle("입력 소리 (시스템 설정에 따름)", isOn: $settings.sound)
            }
            Section("입력") {
                Picker("언어 전환 키 표시", selection: Binding(
                    get: { settings.languageKeyStyle ?? .short },
                    set: { settings.languageKeyStyle = $0 }
                )) {
                    ForEach(LanguageKeyStyle.allCases, id: \.self) { style in
                        Text(style.label).tag(style)
                    }
                }
                Toggle("스페이스 두 번으로 마침표", isOn: $settings.doubleSpace)
            }
            Section("삭제키") {
                Toggle("누르는 즉시 삭제", isOn: Binding(
                    get: { settings.deleteOnTouchDown ?? true },
                    set: { settings.deleteOnTouchDown = $0 }
                ))
                Text("끄면 짧게 누른 뒤 손을 뗄 때 삭제합니다. 길게 누르면 아래 설정대로 반복합니다.")
                Toggle("길게 눌러 삭제 반복", isOn: $settings.repeatDelete)
                slider("반복 시작 대기 (초)", $settings.repeatDelay, 0.2...1)
                    .disabled(!settings.repeatDelete)
                slider("반복 간격 (초)", $settings.repeatInterval, 0.04...0.3)
                    .disabled(!settings.repeatDelete)
                Text("반복 간격이 작을수록 빠르게 지워집니다. 손을 떼거나 키 밖으로 이동하면 멈춥니다.")
            }
            Section("설정 관리") {
                Text(SettingsStore.shared == nil ? "현재 앱과 키보드는 각각 저장합니다. 아래 코드를 복사해 키보드 ⚙ 화면에 붙여넣고 가져오세요." : "App Group 공유 저장소 사용 중")
                TextField("설정 코드", text: $transfer).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("현재 설정 코드 복사") { transfer = SettingsStore.code(settings); UIPasteboard.general.string = transfer }
                Button("코드 가져오기") {
                    if let value = SettingsStore.importCode(transfer) { settings = value; save(); message = "가져왔습니다" }
                    else { message = "올바른 설정 코드가 아닙니다" }
                }
                Text(message)
                Button("기본값 복원", role: .destructive) { settings = KeyboardSettings(); save() }
            }
        }.onChange(of: settingsCode) { _ in save() }
    }
    private var settingsCode: String { SettingsStore.code(settings) }
    private func save() { SettingsStore.save(settings); changed?() }
    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading) { Text("\(title): \(value.wrappedValue, specifier: "%.2f")"); Slider(value: value, in: range) }
    }
}
