import SwiftUI

/// Deadline countdown display with shrinking arc.
/// Arc shows fraction of time remaining: 1.0 (full) → 0.0 (expired).
/// Text uses neutral, non-urgent tone per UX copy rules:
/// "X remaining" — NOT "Act now" or "Time running out".
struct CountdownArcView: View {
    let deadlineTimestamp: Date
    let stakeAmount: Decimal?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(remainingText)
                    .font(.system(.caption2, design: .monospaced))
                    .minimumScaleFactor(0.5)
                if let amount = stakeAmount {
                    Text("$\(amount)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var remainingSeconds: TimeInterval {
        max(0, deadlineTimestamp.timeIntervalSinceNow)
    }

    /// Arc fraction: full 2-hour window = 7200s baseline.
    private var arcFraction: CGFloat {
        let baseline: TimeInterval = 7200
        return CGFloat(min(remainingSeconds / baseline, 1.0))
    }

    private var remainingText: String {
        let total = Int(remainingSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d", h, m)
        }
        return String(format: "%d:%02d", m, s)
    }
}
