import SwiftUI

public class AuthViewModel: ObservableObject {
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User? = nil
    @Published public var errorMessage: String? = nil
    @Published public var isLoading: Bool = false

    public init() {
        if let data = UserDefaults.standard.data(forKey: "saved_murlika_user"),
           let savedUser = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = savedUser
            self.isAuthenticated = true
        }
    }

    private func saveSession(user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "saved_murlika_user")
        }
    }

    public func logout() {
        UserDefaults.standard.removeObject(forKey: "saved_murlika_user")
        self.currentUser = nil
        self.isAuthenticated = false
    }

    public func login(emailOrUsername: String, password: String) async -> Bool {
        let trimmedEmail = emailOrUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            await MainActor.run { self.errorMessage = "Заполните логин и пароль" }
            return false
        }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        let body: [String: Any] = [
            "action": "login",
            "email": trimmedEmail,
            "username": trimmedEmail,
            "password": trimmedPassword
        ]

        do {
            let response: APIResponse<User> = try await NetworkManager.shared.request(endpoint: "auth.php", method: "POST", jsonBody: body)
            if response.success, let user = response.data {
                await MainActor.run {
                    self.saveSession(user: user)
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isLoading = false
                }
                return true
            } else {
                await MainActor.run {
                    self.errorMessage = response.message ?? "Ошибка авторизации"
                    self.isLoading = false
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    public func register(username: String, email: String, password: String, firstName: String, lastName: String) async -> Bool {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !trimmedPassword.isEmpty else {
            await MainActor.run { self.errorMessage = "Введите логин и пароль" }
            return false
        }

        await MainActor.run { self.isLoading = true; self.errorMessage = nil }

        let body: [String: Any] = [
            "action": "register",
            "username": trimmedUsername,
            "email": trimmedEmail.isEmpty ? "\(trimmedUsername)@opennetwork.app" : trimmedEmail,
            "password": trimmedPassword,
            "first_name": trimmedFirstName.isEmpty ? trimmedUsername : trimmedFirstName,
            "last_name": trimmedLastName
        ]

        do {
            let response: APIResponse<User> = try await NetworkManager.shared.request(endpoint: "auth.php", method: "POST", jsonBody: body)
            if response.success, let user = response.data {
                await MainActor.run {
                    self.saveSession(user: user)
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
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}

public struct AuthView: View {
    @ObservedObject private var viewModel: AuthViewModel
    @State private var isRegisterMode: Bool = false

    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""

    public init(authViewModel: AuthViewModel? = nil) {
        self.viewModel = authViewModel ?? AuthViewModel()
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                if let logoUrl = URL(string: "https://myrlika.bond/Logo/murlika.png") {
                    if #available(iOS 15.0, *) {
                        AsyncImage(url: logoUrl) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Color.clear
                        }
                        .frame(maxHeight: 90)
                    }
                }

                Text(isRegisterMode ? "Регистрация нового аккаунта" : "Войдите в свой профиль")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 24)
            }

            VStack(spacing: 14) {
                if isRegisterMode {
                    TextField("Имя (например: Алексей)", text: $firstName)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                    TextField("Логин (например: alex2026)", text: $username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)

                    TextField("Email (необязательно)", text: $email)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                } else {
                    TextField("Логин или Email", text: $email)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }

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
