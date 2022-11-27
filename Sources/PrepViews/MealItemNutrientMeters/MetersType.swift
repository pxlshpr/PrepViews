import Foundation

enum MetersType: Int, CaseIterable {
    case nutrients = 1
    case diet
    case meal
    
    var description: String {
        switch self {
        case .nutrients:
            return "Nutrients"
        case .diet:
            return "Diet"
        case .meal:
            return "Meal"
        }
    }
    
    var headerString: String {
        switch self {
        case .nutrients:
            return "All Listed Nutrients"
        case .diet:
            return "Goals for Today"
        case .meal:
            return "Goals for this Meal"
        }
    }
    
    var footerString: String {
        "Each bar shows the relative increase from what you've added so far."
    }
}
