import SwiftUI

@main
struct DanmoeumApp: App {
    @State private var sampleText = ""
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 20) {
                Text("단모음 키보드").font(.largeTitle.bold())
                Text("설정 → 일반 → 키보드 → 키보드 → 새로운 키보드 추가 → 단모음")
                Text("키보드를 추가한 뒤 글로브(🌐) 버튼으로 전환하세요. 전체 접근 권한은 필요하지 않습니다.")
                TextField("여기서 키보드를 시험해 보세요", text: $sampleText)
                    .textFieldStyle(.roundedBorder)
                Spacer()
            }
            .padding(24)
        }
    }
}
