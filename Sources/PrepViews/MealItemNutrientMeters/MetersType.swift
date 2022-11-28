import Foundation

enum MetersType: Int, CaseIterable {
    case nutrients = 1
    case diet
    case meal
    
    var description: String {
        switch self {
        case .nutrients:
            return "Nutrition Facts"
        case .diet:
            return "Daily Goals"
        case .meal:
            return "Meal Goals"
        }
    }
    
    var headerString: String {
        switch self {
        case .nutrients:
            return "Nutrition Facts"
        case .diet:
            return "Goals for Today"
        case .meal:
            return "Goals for this Meal"
        }
    }
    
    var footerString: String {
        switch self {
        case .nutrients:
            return "Each bar shows the portion of the recommended daily allowance that this food will add. You can customise these in settings."
        default:
            return "Each bar shows the relative increase from what you've added so far."
        }
    }
}
