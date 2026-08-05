import SwiftUI

public struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isRegisterMode: Bool = false

    public init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Logo Header
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("VK Swift Social Network")
                    .font(.system(size: 26, weight: .bold))
                
                Text("Общайтесь, слушайте музыку и смотрите видео")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Input Form
            VStack(spacing: 16) {
                if isRegisterMode {
                    TextField("Имя", text: $authViewModel.firstNameInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Фамилия", text: $authViewModel.lastNameInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Username", text: $authViewModel.usernameInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                TextField("Email или телефон", text: $authViewModel.emailInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Пароль", text: $authViewModel.passwordInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 32)

            // Submit Button
            Button(action: {
                Task {
                    await authViewModel.login()
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isRegisterMode ? "Зарегистрироваться" : "Войти")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            // Toggle Register/Login Mode
            Button(action: {
                withAnimation {
                    isRegisterMode.toggle()
                }
            }) {
                Text(isRegisterMode ? "Уже есть аккаунт? Войти" : "Ещё нет аккаунта? Зарегистрироваться")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}
