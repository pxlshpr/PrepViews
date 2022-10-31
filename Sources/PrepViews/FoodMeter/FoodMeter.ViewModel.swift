import SwiftUI

public extension FoodMeter {
    class ViewModel: ObservableObject {
        
        @Published var component: FoodMeterComponent
        @Published var goal: Double
        
        /// Having this as a non-zero value implies that it's being included with the goal
        ///
        @Published var burned: Double
        @Published var food: Double
        
        @Published var eaten: Double?
        @Published var increment: Double?
        
        public init(component: FoodMeterComponent, goal: Double, burned: Double, food: Double, eaten: Double? = nil, increment: Double? = nil) {
            self.component = component
            self.goal = goal
            self.burned = burned
            self.food = food
            self.eaten = eaten
            self.increment = increment
        }
    }
}

public extension FoodMeter.ViewModel {
    var remainingString: String {
        "\(Int(goal + burned - food - (increment ?? 0)))"
    }
    
    var goalString: String {
        "\(Int(goal))"
    }
    
    var burnedString: String {
        "\(Int(burned))"
    }
    
    var foodString: String {
        "\(Int(food + (increment ?? 0)))"
    }
    
//    var incrementString: String {
//        "\(Int(increment ?? 0))"
//    }
}

extension FoodMeter.ViewModel: Hashable {
    public func hash(into hasher: inout Hasher) {
    hasher.combine(component)
        hasher.combine(goal)
        hasher.combine(burned)
        hasher.combine(food)
        hasher.combine(eaten)
        hasher.combine(increment)
    }
}

extension FoodMeter.ViewModel: Equatable {
    public static func ==(lhs: FoodMeter.ViewModel, rhs: FoodMeter.ViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public extension FoodMeter.ViewModel {
    var totalGoal: Double {
        goal + burned
//        if let burned = burned?.wrappedValue,
//            let includeBurned = includeBurned?.wrappedValue,
//            includeBurned
//        {
//            return goal + burned
//        } else {
//            return goal
//        }
    }
    
    var preppedPercentageType: PercentageType {
        PercentageType(preppedPercentage)
    }
    
    var incrementPercentageType: PercentageType {
        PercentageType(incrementPercentage)
    }
    
    var incrementPercentage: Double {
        guard let increment = increment, totalGoal != 0 else { return 0 }
//        guard let increment = increment?.wrappedValue, totalGoal != 0 else { return 0 }
        return (increment + food) / totalGoal
    }
    
    var incrementPercentageForMeter: Double {
        guard let increment = increment, totalGoal != 0 else { return 0 }
//        guard let increment = increment?.wrappedValue, totalGoal != 0 else { return 0 }

        /// Choose greater of goal or "prepped + increment"
        let total: Double
        if food + increment > totalGoal {
            total = food + increment
        } else {
            total = totalGoal
        }
        
        return ((increment / total) + preppedPercentage)
    }
    
    var eatenPercentageType: PercentageType {
        guard preppedPercentageType != .excess else {
            return .excess
        }
        return PercentageType(eatenPercentage)
    }

    var eatenPercentage: Double {
        guard let eaten = eaten, totalGoal != 0 else { return 0 }
//        guard let eaten = eaten?.wrappedValue, totalGoal != 0 else { return 0 }
        if preppedPercentage < 1 {
            return eaten / totalGoal
        } else {
            guard food != 0 else { return 0 }
            return eaten / food
        }
    }

    var normalizdEatenPercentage: Double {
        if eatenPercentage < 0 {
            return 0
        } else if eatenPercentage > 1 {
            return 1.0/eatenPercentage
        } else {
            return eatenPercentage
        }
    }
    
    var preppedPercentageForMeter: Double {
        /// Choose greater of preppedPercentage or prepped/(prepped + increment)
        if let increment = increment,
           totalGoal + increment > 0,
           food / (totalGoal + increment) > preppedPercentage
        {
            return food / (food + increment)
        } else {
            return preppedPercentage
        }
    }

    var preppedPercentage: Double {
        guard totalGoal != 0 else { return 0 }
        
        let total: Double
        if let increment = increment,
           food + increment > totalGoal
        {
//        if let increment = increment?.wrappedValue,
//           food + increment > totalGoal
//        {
            total = food + increment
        } else {
            total = totalGoal
        }
        
        return food / total
    }
    
    var normalizedPreppedPercentage: Double {
        if preppedPercentage < 0 {
            return 0
        } else if preppedPercentage > 1 {
            return 1.0
//            return 1.0/preppedPercentage
        } else {
            return preppedPercentage
        }
    }
    
    var percentageType: PercentageType {
        if let _ = increment {
            return incrementPercentageType
        } else {
            return preppedPercentageType
        }
    }
    
    var preppedColor: Color {
        switch percentageType {
        case .empty:
            return Color("StatsEmptyFill")
        case .regular:
            return component.preppedColor
        case .complete:
            return Colors.Complete.placeholder
        case .excess:
            return Colors.Excess.placeholder
        }
    }

    var incrementColor: Color {
//        return type.eatenColor
        switch incrementPercentageType {
        case .empty:
            return Color("StatsEmptyFill")
        case .regular:
            return component.eatenColor
        case .complete:
            return Colors.Complete.fill
        case .excess:
            return Colors.Excess.fill
//            return Color("StatsExcessFill")
        }
    }

    var eatenColor: Color {
        guard preppedPercentageType != .complete else {
            return Colors.Complete.fill
        }
        
        switch eatenPercentageType {
        case .empty:
            return Color("StatsEmptyFill")
        case .regular:
            return component.eatenColor
        case .complete:
            return Colors.Complete.fill
        case .excess:
            return Colors.Excess.fill
        }
    }
    
    struct Colors {
        struct Complete {
            static let placeholder = Color("StatsCompleteFillExtraNew")
            static let fill = Color("StatsCompleteFill")
            static let text = Color("StatsCompleteText")
            static let textDarker = Color("StatsCompleteTextExtra")
        }
        
        struct Excess {
            static let placeholder = Color("StatsExcessFillExtra")
            static let fill = Color("StatsExcessFill")
            static let text = Color("StatsExcessText")
            static let textDarker = Color("StatsExcessTextExtra")
        }
        
        struct Empty {
            static let fill = Color("StatsEmptyFill")
            static let text = Color("StatsEmptyText")
            static let textLighter = Color("StatsEmptyTextSecondary")
        }
    }
}
