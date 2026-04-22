//
//  ParentalGateView.swift
//  DetiZhivotnieApp
//
//  Figma: `1:7137` (Parent Control positive), `1:7119` (Alert),
//         `1:7128` (Repeat Parent Control).
//
//  A modal math-gate popup overlaid on the host screen. Tapping outside the
//  card dismisses (onCancel). Correct answer → onSuccess. Incorrect → shrinks
//  to an alert card with a pink warning for 3 seconds, then a new question.
//

import SwiftUI

struct ParentalGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var question = MathQuestion.generate()
    @State private var attemptState: AttemptState = .asking

    private enum AttemptState: Equatable {
        case asking
        case wrong       // showing the "Oops!" alert
    }

    var body: some View {
        ZStack {
            // Darkened backdrop that dismisses on tap.
            DS.Color.Overlay.disabled
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            // Card
            Group {
                switch attemptState {
                case .asking:
                    questionCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                case .wrong:
                    wrongCard
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }
            .padding(.horizontal, DS.Gap.gap500)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: attemptState)
    }

    // MARK: - Question card (positive flow)

    private var questionCard: some View {
        VStack(spacing: DS.Gap.gap500) {
            VStack(spacing: DS.Gap.gap100) {
                Text("Parent control")
                    .dsStyle(.title2Bold)
                    .foregroundColor(DS.Color.Label.primary)
                Text("Solve a mathematical example")
                    .dsStyle(.subheadline)
                    .foregroundColor(DS.Color.Label.secondary)
            }

            Text(question.prompt)
                .dsStyle(.title1Bold)
                .foregroundColor(DS.Color.Label.accent)

            VStack(spacing: DS.Gap.gap300) {
                ForEach(question.choices, id: \.self) { choice in
                    Button {
                        submit(choice)
                    } label: {
                        Text("\(choice)")
                            .dsStyle(.bodySemi)
                            .foregroundColor(DS.Color.Label.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                Capsule()
                                    .fill(DS.Color.Fill.quaternary)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DS.Gap.gap500)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxl)
                .fill(DS.Color.Background.primaryElevated)
        )
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
    }

    // MARK: - Wrong answer card (negative flow)

    private var wrongCard: some View {
        VStack(spacing: DS.Gap.gap400) {
            WarningTriangleBadge()
                .frame(width: 80, height: 74)

            VStack(spacing: DS.Gap.gap100) {
                Text("Parent control")
                    .dsStyle(.title2Bold)
                    .foregroundColor(DS.Color.Label.primary)
                Text("Solve a mathematical example")
                    .dsStyle(.subheadline)
                    .foregroundColor(DS.Color.Label.secondary)
            }

            Text("Oops! Try again!")
                .dsStyle(.title1Bold)
                .foregroundColor(DS.Color.Label.error)
                .padding(.top, DS.Gap.gap100)
        }
        .padding(DS.Gap.gap500)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xxl)
                .fill(DS.Color.Background.primaryElevated)
        )
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
    }

    // MARK: - Logic

    private func submit(_ choice: Int) {
        if choice == question.answer {
            onSuccess()
        } else {
            attemptState = .wrong
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)   // 3s
                await MainActor.run {
                    question = MathQuestion.generate()
                    attemptState = .asking
                }
            }
        }
    }
}

// MARK: - Math question

struct MathQuestion: Equatable {
    let a: Int
    let b: Int
    let answer: Int
    let choices: [Int]

    var prompt: String { "\(a) + \(b) = __" }

    static func generate() -> MathQuestion {
        let a = Int.random(in: 2...9)
        let b = Int.random(in: 2...9)
        let answer = a + b
        var pool: Set<Int> = [answer]
        while pool.count < 4 {
            let candidate = Int.random(in: 2...18)
            if candidate != answer { pool.insert(candidate) }
        }
        return MathQuestion(a: a, b: b, answer: answer, choices: pool.shuffled())
    }
}

// MARK: - Warning triangle badge

private struct WarningTriangleBadge: View {
    var body: some View {
        ZStack {
            // Pink triangle with soft rounded corners (matches Figma illustration)
            RoundedTriangle(cornerRadius: 10)
                .fill(DS.Palette.Pink.c500)
                .shadow(color: DS.Palette.Pink.c600.opacity(0.4), radius: 6, y: 4)

            Text("!")
                .dsStyle(.largeTitleBold)
                .foregroundColor(DS.Palette.Neutral.n900)
                .offset(y: 6)
        }
    }
}

private struct RoundedTriangle: Shape {
    var cornerRadius: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bl  = CGPoint(x: rect.minX, y: rect.maxY)
        let br  = CGPoint(x: rect.maxX, y: rect.maxY)

        var path = Path()
        path.move(to: CGPoint(x: top.x, y: top.y + cornerRadius))
        path.addArc(tangent1End: top, tangent2End: br, radius: cornerRadius)
        path.addArc(tangent1End: br, tangent2End: bl, radius: cornerRadius)
        path.addArc(tangent1End: bl, tangent2End: top, radius: cornerRadius)
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [DS.Palette.LightBlue.c500, DS.Palette.LightBlue.c400], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        ParentalGateView(onSuccess: {}, onCancel: {})
    }
}
