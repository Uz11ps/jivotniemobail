import SwiftUI

struct ParentalGateView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @State private var firstNumber: Int = 0
    @State private var secondNumber: Int = 0
    @State private var correctAnswer: Int = 0
    @State private var selectedAnswer: Int?
    @State private var showError = false
    
    private let answers: [Int] = Array(1...10)
    
    init(onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Родительский контроль")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Решите пример, чтобы продолжить")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Text("\(firstNumber)")
                    .font(.system(size: 48, weight: .bold))
                
                Text("+")
                    .font(.system(size: 36))
                
                Text("\(secondNumber)")
                    .font(.system(size: 48, weight: .bold))
                
                Text("=")
                    .font(.system(size: 36))
                
                Text("?")
                    .font(.system(size: 48, weight: .bold))
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(answers, id: \.self) { answer in
                    Button(action: {
                        checkAnswer(answer)
                    }) {
                        Text("\(answer)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(selectedAnswer == answer ? (showError ? Color.red : Color.blue) : Color.gray)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            
            if showError {
                Text("Неверный ответ. Попробуйте снова.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: onCancel) {
                Text("Отмена")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear {
            generateQuestion()
        }
    }
    
    private func generateQuestion() {
        firstNumber = Int.random(in: 1...5)
        secondNumber = Int.random(in: 1...5)
        correctAnswer = firstNumber + secondNumber
        selectedAnswer = nil
        showError = false
    }
    
    private func checkAnswer(_ answer: Int) {
        selectedAnswer = answer
        
        if answer == correctAnswer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSuccess()
            }
        } else {
            showError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                generateQuestion()
            }
        }
    }
}
