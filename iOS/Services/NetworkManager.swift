import Foundation
import Combine

public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case serverError(String)
    case decodingError(String)
    case unauthorized
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Некорректный адрес сервера"
        case .serverError(let msg): return msg
        case .decodingError(let msg): return "Ошибка чтения данных: \(msg)"
        case .unauthorized: return "Требуется авторизация"
        }
    }
}

public class NetworkManager: ObservableObject {
    public static let shared = NetworkManager()
    
    @Published public var baseURL: String = "http://46.53.128.120/api"
    @Published public var authToken: String? = nil
    
    private init() {}
    
    public func request<T: Codable>(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            
            let decoder = JSONDecoder()
            
            do {
                let decodedResponse = try decoder.decode(APIResponse<T>.self, from: data)
                if decodedResponse.success, let result = decodedResponse.data {
                    return result
                } else if decodedResponse.success && T.self == [String: String].self {
                    return [:] as! T
                } else {
                    throw NetworkError.serverError(decodedResponse.message ?? "Ошибка сервера")
                }
            } catch let decodeErr {
                // Пытаемся распарсить ответ напрямую если не обернут в APIResponse
                if let directResult = try? decoder.decode(T.self, from: data) {
                    return directResult
                }
                
                let rawString = String(data: data, encoding: .utf8) ?? ""
                print("Decoding error details: \(decodeErr). Raw data: \(rawString)")
                throw NetworkError.decodingError(decodeErr.localizedDescription)
            }
        } catch {
            throw error
        }
    }

    public func request<T: Codable>(endpoint: String, method: String = "GET", jsonBody: [String: Any]) async throws -> T {
        let data = try JSONSerialization.data(withJSONObject: jsonBody)
        return try await request(endpoint: endpoint, method: method, body: data)
    }
}
