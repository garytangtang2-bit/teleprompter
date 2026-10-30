import AVFoundation
import Photos
import UIKit

struct CompletedRecording: Identifiable {
    let id = UUID()
    let url: URL
    let note: String?
}

/// Owns the capture session (front camera + microphone) and records plain video.
/// The teleprompter is a SwiftUI overlay only, so it is never part of the recorded video.
final class CameraManager: NSObject, ObservableObject {
    enum Permission {
        case unknown
        case authorized
        case denied
    }

    @Published var permission: Permission = .unknown
    @Published var deniedMessage = ""
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var completedRecording: CompletedRecording?

    let session = AVCaptureSession()

    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "teleprompter.camera.session")
    private var isConfigured = false
    private var timer: Timer?
    private var interruptedWhileRecording = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionWasInterrupted),
            name: AVCaptureSession.wasInterruptedNotification, object: session)
        NotificationCenter.default.addObserver(
            self, selector: #selector(sessionRuntimeError),
            name: AVCaptureSession.runtimeErrorNotification, object: session)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    func prepare() async {
        let videoOK = await AVCaptureDevice.requestAccess(for: .video)
        let audioOK = await AVCaptureDevice.requestAccess(for: .audio)

        if !videoOK || !audioOK {
            let name: String
            if !videoOK && !audioOK {
                name = "相機和麥克風"
            } else if !videoOK {
                name = "相機"
            } else {
                name = "麥克風"
            }
            await MainActor.run {
                self.deniedMessage = "「提詞機」需要使用\(name)才能拍攝。\n請前往 iPhone「設定」→「提詞機」，開啟\(name)權限，然後回到本 App。"
                self.permission = .denied
            }
            return
        }

        await MainActor.run { self.permission = .authorized }
        sessionQueue.async { [weak self] in
            self?.configureAndStart()
        }
    }

    private func configureAndStart() {
        if !isConfigured {
            guard configure() else { return }
            isConfigured = true
        }
        if !session.isRunning {
            session.startRunning()
        }
    }

    private func configure() -> Bool {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(videoInput) else {
            postError("找不到前置鏡頭，或無法使用鏡頭。")
            return false
        }
        session.addInput(videoInput)

        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        guard session.canAddOutput(movieOutput) else {
            postError("無法設定影片錄製。")
            return false
        }
        session.addOutput(movieOutput)

        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            // Save the front-camera video un-mirrored (same as the iPhone Camera app default).
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }
        return true
    }

    private func postError(_ message: String) {
        DispatchQueue.main.async { self.errorMessage = message }
    }

    // MARK: - Recording

    func beginRecording() async {
        guard permission == .authorized, !isRecording else { return }

        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        guard status == .authorized || status == .limited else {
            await MainActor.run {
                self.errorMessage = "沒有儲存影片到「相片」的權限，所以無法開始拍攝。\n請前往 iPhone「設定」→「提詞機」→「相片」，允許新增影片到相片圖庫。"
            }
            return
        }

        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning, !self.movieOutput.isRecording else { return }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("recording-\(UUID().uuidString).mov")
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
        }
    }

    func shutdown() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func discardCompleted() {
        if let url = completedRecording?.url {
            try? FileManager.default.removeItem(at: url)
        }
        completedRecording = nil
    }

    // MARK: - Interruptions and errors

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        DispatchQueue.main.async {
            if self.isRecording {
                self.interruptedWhileRecording = true
            }
        }
        stopRecording()
    }

    @objc private func sessionRuntimeError(_ notification: Notification) {
        stopRecording()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
        postError("鏡頭發生錯誤，已嘗試重新啟動。如果畫面沒有恢復，請返回再重新進入。")
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let seconds = self.movieOutput.recordedDuration.seconds
            if seconds.isFinite {
                self.elapsed = seconds
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Saving

    private func saveToPhotos(_ url: URL) {
        let note: String? = interruptedWhileRecording ? "錄影途中曾被中斷，已儲存中斷前的片段。" : nil
        interruptedWhileRecording = false

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = false
            request.addResource(with: .video, fileURL: url, options: options)
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.completedRecording = CompletedRecording(url: url, note: note)
                } else {
                    let detail = error?.localizedDescription ?? "未知原因"
                    self.errorMessage = "影片儲存到「相片」失敗：\(detail)"
                }
            }
        })
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo fileURL: URL,
                    from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.elapsed = 0
            self.isRecording = true
            self.startTimer()
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        DispatchQueue.main.async {
            self.stopTimer()
            self.isRecording = false

            if let error = error {
                let finishedOK = ((error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
                if !finishedOK {
                    self.errorMessage = "拍攝失敗：\(error.localizedDescription)"
                    try? FileManager.default.removeItem(at: outputFileURL)
                    return
                }
                self.interruptedWhileRecording = true
            }
            self.saveToPhotos(outputFileURL)
        }
    }
}
