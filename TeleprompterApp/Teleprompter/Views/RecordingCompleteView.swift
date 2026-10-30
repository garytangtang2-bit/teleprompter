import SwiftUI
import AVKit

struct RecordingCompleteView: View {
    let recording: CompletedRecording
    let onRetake: () -> Void
    let onFinish: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Label("影片已儲存到「相片」", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                if let note = recording.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 16)

            VideoPlayer(player: player)
                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button {
                    onRetake()
                } label: {
                    Text("再拍一次")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)

                Button {
                    onFinish()
                } label: {
                    Text("完成")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .onAppear {
            player = AVPlayer(url: recording.url)
        }
        .onDisappear {
            player?.pause()
        }
    }
}
