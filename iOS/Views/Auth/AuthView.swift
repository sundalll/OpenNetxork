import SwiftUI

public class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User? = nil
    @Published public var errorMessage: String? = nil
    @Published public var isLoading: Bool = false

    public init() {}

    public func login(emailOrUsername: String, password: String) async -> Bool {
        guard !emailOrUsername.isEmpty, !password.isEmpty else {
            await MainActor.run { self.errorMessage = "Заполните все поля" }
            return false
        }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        let body: [String: Any] = [
            "action": "login",
            "email": emailOrUsername,
            "password": password
        ]

        do {
            let response: APIResponse<User> = try await NetworkManager.shared.request(endpoint: "auth.php", method: "POST", body: body)
            if response.success, let user = response.data {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                return true
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? " Ошибка авторизации"
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Неверный логин или пароль"
                self.isLoading = false
            }
            return false
        }
    }

    public func register(username: String, email: String, password: String, firstName: String, lastName: String) async -> Bool {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty, !firstName.isEmpty else {
            await MainActor.run { self.errorMessage = "Заполните все обязательные поля" }
            return false
        }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        let body: [String: Any] = [
            "action": "register",
            "username": username,
            "email": email,
            "password": password,
            "first_name": firstName,
            "last_name": lastName
        ]

        do {
            let response: APIResponse<User> = try await NetworkManager.shared.request(endpoint: "auth.php", method: "POST", body: body)
            if response.success, let user = response.data {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                return true
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "Ошибка регистрации"
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка при регистрации"
                self.isLoading = false
            }
            return false
        }
    }
}

public struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isRegisterMode: Bool = false

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("OpenNetwork")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.blue)

                Text(isRegisterMode ? "Регистрация нового аккаунта" : "Войдите в свой профиль")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 14) {
                if isRegisterMode {
                    TextField("Имя (например: Иван)", text: $firstName)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                    TextField("Фамилия", text: $lastName)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                    TextField("Логин (username)", text: $username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }

                TextField("Email или логин", text: $email)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                SecureField("Пароль", text: $password)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)

            Button(action: {
                Task {
                    if isRegisterMode {
                        _ = await viewModel.register(username: username, email: email, password: password, firstName: firstName, lastName: lastName)
                    } else {
                        _ = await viewModel.login(emailOrUsername: email, password: password)
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isRegisterMode ? "Зарегистрироваться" : "Войти")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .disabled(viewModel.isLoading)

            Button(action: {
                withAnimation {
                    isRegisterMode.toggle()
                    viewModel.errorMessage = nil
                }
            }) {
                Text(isRegisterMode ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding(.vertical, 20)
    }
}
