import Foundation

struct ActivityPoint: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let count: Int
}

enum AppCategory: String, CaseIterable {
    case code = "Code"
    case communicate = "Communicate"
    case create = "Create"
    case browsing = "Browsing"
    case utility = "Utility"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .communicate: return "bubble.left.and.bubble.right.fill"
        case .create: return "paintbrush.fill"
        case .browsing: return "safari.fill"
        case .utility: return "gearshape.fill"
        case .other: return "app.dashed"
        }
    }
}
