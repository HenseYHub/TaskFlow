import SwiftUI
import Foundation
import Combine

class TimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int
    @Published var totalSeconds: Int
    @Published var isRunning: Bool = false
    @Published var hasStarted = false

    private var timer: AnyCancellable?

    init(durationInMinutes: Int) {
        self.remainingSeconds = durationInMinutes * 60
        self.totalSeconds = durationInMinutes * 60
    }

    func start() {
        guard remainingSeconds > 0 else { return }

        isRunning = true
        hasStarted = true

        timer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stop()
                    // TODO: auto-complete task, if нужно
                }
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
    }

    func stop() {
        isRunning = false
        timer?.cancel()
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
