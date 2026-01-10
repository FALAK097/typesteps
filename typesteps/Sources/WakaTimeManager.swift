import Foundation
import Combine

class WakaTimeManager: ObservableObject {
    static let shared = WakaTimeManager()
    
    @Published var totalMinutesToday: Double = 0
    @Published var isFetching: Bool = false
    @Published var lastError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchTodayStats(apiKey: String) {
        guard !apiKey.isEmpty else { return }
        
        // WakaTime API expects the API key to be Base64 encoded in the Authorization header
        let credentialData = apiKey.data(using: .utf8)!
        let base64Credentials = credentialData.base64EncodedString()
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: today)
        
        let url = URL(string: "https://wakatime.com/api/v1/users/current/summaries?start=\(dateString)&end=\(dateString)")!
        
        var request = URLRequest(url: url)
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        isFetching = true
        lastError = nil
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: WakaTimeSummaryResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isFetching = false
                if case .failure(let error) = completion {
                    self.lastError = error.localizedDescription
                    print("WakaTime Fetch Error: \(error)")
                }
            } receiveValue: { response in
                if let totalSeconds = response.cumulative_total?.seconds {
                    self.totalMinutesToday = totalSeconds / 60.0
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Decodable Models

struct WakaTimeSummaryResponse: Decodable {
    let cumulative_total: CumulativeTotal?
    
    struct CumulativeTotal: Decodable {
        let seconds: Double?
        let text: String?
    }
}
