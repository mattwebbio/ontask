import SwiftUI

/// Elapsed timer display with circular arc progress ring.
/// Used in Dynamic Island compact (trailing) and Lock Screen Live Activity.
/// Arc is purely visual — it does NOT use AnimationPhase or timerInterval.
/// The elapsed value comes from ContentState.elapsedSeconds (server-authoritative).
struct ElapsedTimerView: View {
    let elapsedSeconds: Int
    let maxSeconds: Int  // Used for arc fraction; default 3600 (1 hour cycle)

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(formattedElapsed)
                .font(.system(.caption2, design: .monospaced))
                .minimumScaleFactor(0.5)
        }
    }

    private var arcFraction: CGFloat {
        guard maxSeconds > 0 else { return 0 }
        return CGFloat(elapsedSeconds % maxSeconds) / CGFloat(maxSeconds)
    }

    private var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
