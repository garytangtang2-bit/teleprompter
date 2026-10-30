import SwiftUI

struct CameraTeleprompterView: View {
    let script: Script

    @EnvironmentObject private var settingsStore: SettingsStorage
    @Environment(\.dismiss) private var dismiss

    @StateObject private var camera = CameraManager()
    @StateObject private var scroller = TeleprompterScrollManager()

    @State private var showSettings = false
    @State private var dragOrigin: CGPoint?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            if camera.permission == .denied {
                deniedView
            } else {
                GeometryReader { geo in
                    panel(in: geo.size)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if camera.permission != .denied {
                controls
            }
        }
        .statusBarHidden(true)
        .task {
            await camera.prepare()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            scroller.pause()
            camera.shutdown()
        }
        .sheet(isPresented: $showSettings) {
            TeleprompterSettingsView()
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $camera.completedRecording) { recording in
            RecordingCompleteView(
                recording: recording,
                onRetake: {
                    camera.discardCompleted()
                },
                onFinish: {
                    camera.discardCompleted()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        dismiss()
                    }
                }
            )
        }
        .alert("提示", isPresented: Binding(
            get: { camera.errorMessage != nil },
            set: { if !$0 { camera.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(camera.errorMessage ?? "")
        }
    }

    // MARK: - Teleprompter panel

    private func panel(in size: CGSize) -> some View {
        let s = settingsStore.settings
        let width = size.width * s.panelWidth
        let height = size.height * s.panelHeight
        let freeX = max(size.width - width, 0)
        let freeY = max(size.height - height, 0)

        let drag = DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let origin = dragOrigin ?? CGPoint(x: s.panelX, y: s.panelY)
                dragOrigin = origin
                var updated = settingsStore.settings
                if freeX > 1 {
                    updated.panelX = clamp01(origin.x + Double(value.translation.width / freeX))
                }
                if freeY > 1 {
                    updated.panelY = clamp01(origin.y + Double(value.translation.height / freeY))
                }
                settingsStore.settings = updated
            }
            .onEnded { _ in
                dragOrigin = nil
            }

        return VStack(spacing: 0) {
            ZStack {
                Color.clear
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 48, height: 5)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
            .frame(height: 30)
            .contentShape(Rectangle())
            .gesture(drag)

            TeleprompterTextView(text: script.body, settings: s, manager: scroller)
        }
        .frame(width: width, height: height)
        .background(Color.black.opacity(s.backgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .offset(x: freeX * s.panelX, y: freeY * s.panelY)
    }

    private func clamp01(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                roundButton(systemName: "arrow.counterclockwise", label: "重新開始") {
                    scroller.restart()
                }
                roundButton(systemName: scroller.isPlaying ? "pause.fill" : "play.fill",
                            label: scroller.isPlaying ? "暫停" : "播放") {
                    scroller.toggle()
                }
                Image(systemName: "tortoise.fill")
                    .foregroundStyle(.white.opacity(0.8))
                Slider(value: settingsStore.binding(\.speed), in: TeleprompterSettings.speedRange, step: 1)
                Image(systemName: "hare.fill")
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(Int(settingsStore.settings.speed.rounded()))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 32)
            }

            if camera.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("錄影中 \(timeString(camera.elapsed))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white)
                }
            }

            HStack {
                if camera.isRecording {
                    Color.clear.frame(width: 52, height: 52)
                } else {
                    roundButton(systemName: "xmark", label: "返回稿件") {
                        dismiss()
                    }
                }
                Spacer()
                recordButton
                Spacer()
                roundButton(systemName: "slider.horizontal.3", label: "提詞設定") {
                    showSettings = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            Color.black.opacity(0.45)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var recordButton: some View {
        Button {
            if camera.isRecording {
                camera.stopRecording()
            } else {
                Task { await camera.beginRecording() }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 76, height: 76)
                if camera.isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red)
                        .frame(width: 30, height: 30)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 62, height: 62)
                }
            }
        }
        .accessibilityLabel(camera.isRecording ? "停止錄影" : "開始錄影")
    }

    private func roundButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white.opacity(0.22)))
        }
        .accessibilityLabel(label)
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - Permission denied

    private var deniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.8))
            Text(camera.deniedMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
            Button("開啟 iPhone 設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Button("返回稿件") {
                dismiss()
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
