import SwiftUI
import PrepDataTypes

extension FoodMeterComponent: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .energy:
            hasher.combine(0)
        case .carb:
            hasher.combine(1)
        case .fat:
            hasher.combine(2)
        case .protein:
            hasher.combine(3)
        case .micro(let name, let unit):
            hasher.combine(4)
            hasher.combine(name)
            hasher.combine(unit)
        }
    }
}

public enum FoodMeterComponent {
    case energy
    case carb
    case fat
    case protein
    case micro(name: String, unit: String = "g")
    
    var iconImageName: String? {
        switch self {
        case .energy:
            return "flame.fill"
        default:
            return nil
        }
    }
    
    var name: String {
        switch self {
        case .energy:
            return "Energy"
        case .carb:
            return "Carb"
        case .fat:
            return "Fat"
        case .protein:
            return "Protein"
        case .micro(let name, _):
            return name
        }
    }
    
    var initial: String {
        guard let firstCharacter = name.first else { return "" }
        return String(firstCharacter)
    }
    
    var textColor: Color {
        switch self {
        case .energy:
            return energyTextColor
        case .carb:
            return Color("StatsCarbText")
        case .fat:
            return Color("StatsFatText")
        case .protein:
            return Color("StatsProteinText")
        case .micro:
            return Color.black
        }
    }
    
    var unit: String {
        switch self {
        //TODO: Handle kJ preference
        case .energy:
            return "kcal"
        case .micro(_, let unit):
            return unit
        default:
            /// Implies it's a macro
            return "g"
        }
    }
    
    var energyTextColor: Color {
        Color("StatsEnergyText", bundle: .module)
//        let type = PercentageType(progress)
//        switch type {
//        case .empty:
//            return Color("StatsEmptyTextSecondary")
//        case .regular:
//            return Color("StatsEnergyText")
//        case .complete:
//            return progress > 1.0 ? Color("StatsCompleteTextExtra") : Color("StatsCompleteText")
//        case .excess:
//            return Color("StatsExcessTextExtra")
//        }
    }
    
    var textTotalColor: Color {
        switch self {
        case .energy:
            return energyTextTotalColor
        default:
            let color = textColor
            return color.brighter(by: -10)
        }
    }

    var energyTextTotalColor: Color {
        Color("StatsEnergyText", bundle: .module)
//        let type = PercentageType(progress)
//        switch type {
//        case .empty:
//            return Color("StatsEmptyTextSecondary")
//        case .regular:
////            return Color("StatsEnergyPlaceholderText")
//            return energyPlaceholderColor
//        case .complete:
//            return progress >= 1.0 ? Color("StatsCompleteText") : Color("StatsCompleteTextExtra")
//        case .excess:
//            return Color("StatsExcessText")
//        }
    }
    
    var energyPlaceholderColor: Color {
//        return Color("StatsEnergyPlaceholderText")
        return Color("StatsEnergyText", bundle: .module)
    }

    var eatenColor: Color {
        switch self {
        case .energy:
            return Color("StatsEnergyFill")
        case .carb:
            return Color("StatsCarbFill")
        case .fat:
            return Color("StatsFatFill")
        case .protein:
            return Color("StatsProteinFill")
        case .micro:
            return Color("StatsEnergyFill")
        }
    }
    
    var preppedColor: Color {
        switch self {
        case .energy:
            return Color("StatsEnergyPlaceholder")
        case .carb:
            return Color("StatsCarbPlaceholder")
        case .fat:
            return Color("StatsFatPlaceholder")
        case .protein:
            return Color("StatsProteinPlaceholder")
        case .micro:
            return Color("StatsEnergyPlaceholder")
        }
    }
    
    init(macro: Macro?) {
        guard let macro = macro else {
            self = .energy
            return
        }
        switch macro {
        case .carb:
            self = .carb
        case .fat:
            self = .fat
        case .protein:
            self = .protein
        }
    }
}

extension FoodMeterComponent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .energy:
            return "Energy"
        case .carb:
            return "Carb"
        case .fat:
            return "Fat"
        case .protein:
            return "Protein"
        case .micro:
            return "Micronutrient"
        }
    }
}
