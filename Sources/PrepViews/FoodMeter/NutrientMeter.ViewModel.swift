import SwiftUI

public extension NutrientMeter {
    class ViewModel: ObservableObject {
        
        @Published public var component: NutrientMeterComponent
        @Published public var goal: Double?
        
        /// Having this as a non-zero value implies that it's being included with the goal
        ///
        @Published public var burned: Double
        @Published public var planned: Double
        
        @Published public var eaten: Double?
        @Published public var increment: Double?
        
        public init(component: NutrientMeterComponent, goal: Double? = nil, burned: Double = 0, food: Double, increment: Double) {
            self.component = component
            self.goal = goal
            self.burned = burned
            self.planned = food
            self.eaten = nil
            self.increment = increment
        }
        
        public init(component: NutrientMeterComponent, goal: Double? = nil, burned: Double = 0, food: Double, eaten: Double) {
            self.component = component
            self.goal = goal
            self.burned = burned
            self.planned = food
            self.eaten = eaten
            self.increment = nil
        }
    }
}

public extension NutrientMeter.ViewModel {
    var remainingString: String {
        guard let goal else { return "" }
        return "\(Int(goal + burned - planned - (increment ?? 0)))"
    }
    
    var goalString: String {
        guard let goal else { return "" }
        return "\(Int(goal))"
    }
    
    var burnedString: String {
        "\(Int(burned))"
    }
    
    var foodString: String {
        "\(Int(planned + (increment ?? 0)))"
    }
    
//    var incrementString: String {
//        "\(Int(increment ?? 0))"
//    }
}

extension NutrientMeter.ViewModel: Hashable {
    public func hash(into hasher: inout Hasher) {
    hasher.combine(component)
        hasher.combine(goal)
        hasher.combine(burned)
        hasher.combine(planned)
        hasher.combine(eaten)
        hasher.combine(increment)
    }
}

extension NutrientMeter.ViewModel: Equatable {
    public static func ==(lhs: NutrientMeter.ViewModel, rhs: NutrientMeter.ViewModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public extension NutrientMeter.ViewModel {
    var haveGoal: Bool {
        goal != nil
    }
    
    var totalGoal: Double {
        /// Returned `planned` when we have no goal so that the entire meter becomes the planned amount
        guard let goal else {
            return planned
        }
        return goal + burned
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
        return (increment + planned) / totalGoal
    }
    
    var incrementPercentageForMeter: Double {
        guard let increment = increment, totalGoal != 0 else { return 0 }
        //        guard let increment = increment?.wrappedValue, totalGoal != 0 else { return 0 }
        
        /// Choose greater of goal or "prepped + increment"
        let total: Double
        if planned + increment > totalGoal {
            total = planned + increment
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
            guard planned != 0 else { return 0 }
            return eaten / planned
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
           planned / (totalGoal + increment) > preppedPercentage
        {
            return planned / (planned + increment)
        } else {
            return preppedPercentage
        }
    }
    
    var preppedPercentage: Double {
        guard totalGoal != 0 else { return 0 }
        
        let total: Double
        if let increment = increment,
           planned + increment > totalGoal
        {
            //        if let increment = increment?.wrappedValue,
            //           food + increment > totalGoal
            //        {
            total = planned + increment
        } else {
            total = totalGoal
        }
        
        return planned / total
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
}

//MARK: Colors

public extension NutrientMeter.ViewModel {
    
    var preppedColor: Color {
        switch percentageType {
        case .empty:
            return Color("StatsEmptyFill", bundle: .module)
        case .regular:
            return component.preppedColor
        case .complete:
            return haveGoal ? Colors.Complete.placeholder : component.preppedColor
        case .excess:
            return haveGoal ? Colors.Excess.placeholder : component.preppedColor
        }
    }
    
    var incrementColor: Color {
        switch incrementPercentageType {
        case .empty:
            return Color("StatsEmptyFill", bundle: .module)
        case .regular:
            return component.eatenColor
        case .complete:
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        case .excess:
            return haveGoal ? Colors.Excess.fill : component.eatenColor
        }
    }
    
    var eatenColor: Color {
        guard preppedPercentageType != .complete else {
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        }
        
        switch eatenPercentageType {
        case .empty:
            return Color("StatsEmptyFill", bundle: .module)
        case .regular:
            return component.eatenColor
        case .complete:
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        case .excess:
            return haveGoal ? Colors.Excess.fill : component.eatenColor
        }
    }
}

//MARK: - Color Constants

public extension NutrientMeter.ViewModel {
    struct Colors {
        public struct Complete {
            public static let placeholder = Color("StatsCompleteFillExtraNew", bundle: .module)
            public static let fill = Color("StatsCompleteFill", bundle: .module)
            public static let text = Color("StatsCompleteText", bundle: .module)
            public static let textDarker = Color("StatsCompleteTextExtra", bundle: .module)
        }
        
        public struct Excess {
            public static let placeholder = Color("StatsExcessFillExtra", bundle: .module)
            public static let fill = Color("StatsExcessFill", bundle: .module)
            public static let text = Color("StatsExcessText", bundle: .module)
            public static let textDarker = Color("StatsExcessTextExtra", bundle: .module)
        }
        
        public struct Empty {
            public static let fill = Color("StatsEmptyFill", bundle: .module)
            public static let text = Color("StatsEmptyText", bundle: .module)
            public static let textLighter = Color("StatsEmptyTextSecondary", bundle: .module)
        }
    }
}
