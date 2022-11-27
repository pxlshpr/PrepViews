import SwiftUI

public extension NutrientMeter2 {
    struct ViewModel {
        
        public var component: NutrientMeterComponent

        /// Used to convey that this is for a component that has been generated (either an implicit daily goal or a meal subgoal),
        /// as we may want to style it differently
        public var isGenerated: Bool
        
        public var goalLower: Double?
        public var goalUpper: Double?

        public var planned: Double
        public var eaten: Double?
        public var increment: Double?

        //TODO: Remove this
        public var burned: Double
        
        public init(
            component: NutrientMeterComponent,
            isGenerated: Bool = false,
            goalLower: Double? = nil,
            goalUpper: Double? = nil,
            burned: Double = 0,
            planned: Double,
            increment: Double
        ) {
            self.component = component
            self.isGenerated = isGenerated
            self.goalLower = goalLower
            self.goalUpper = goalUpper
            self.burned = burned
            self.planned = planned
            self.eaten = nil
            self.increment = increment
        }
        
        public init(
            component: NutrientMeterComponent,
            isGenerated: Bool = false,
            goalLower: Double? = nil,
            goalUpper: Double? = nil,
            burned: Double = 0,
            planned: Double,
            eaten: Double
        ) {
            self.component = component
            self.isGenerated = isGenerated
            self.goalLower = goalLower
            self.goalUpper = goalUpper
            self.burned = burned
            self.planned = planned
            self.eaten = eaten
            self.increment = nil
        }
    }
}

public extension NutrientMeter2.ViewModel {
    var remainingString: String {
        return "TODO"
//        guard let goal else { return "" }
//        return "\(Int(goal + burned - planned - (increment ?? 0)))"
    }
    
    var goalString: String {
        return "TODO"
//        guard let goal else { return "" }
//        return "\(Int(goal))"
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

//extension NutrientMeter2.ViewModel: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(component)
//        hasher.combine(goalLower)
//        hasher.combine(goalUpper)
//        hasher.combine(burned)
//        hasher.combine(planned)
//        hasher.combine(eaten)
//        hasher.combine(increment)
//    }
//}
//
//extension NutrientMeter2.ViewModel: Equatable {
//    public static func ==(lhs: NutrientMeter2.ViewModel, rhs: NutrientMeter2.ViewModel) -> Bool {
//        lhs.hashValue == rhs.hashValue
//    }
//}

public extension NutrientMeter2.ViewModel {
    var haveGoal: Bool {
        goalLower != nil || goalUpper != nil
    }
    
    var showingIncrement: Bool {
        increment != nil
    }
    
    var highestGoal: Double? {
        goalUpper ?? goalLower
    }
    
    var totalGoal: Double {
        /// Returned `planned` when we have no goal so that the entire meter becomes the planned amount
        guard let highestGoal else {
            return planned
        }
        return highestGoal + burned
    }
    
    var goalBoundsType: GoalBoundsType {
        if goalLower != nil {
            if goalUpper != nil {
                return .lowerAndUpper
            } else {
                return .lowerOnly
            }
        } else if goalUpper != nil {
            return .upperOnly
        } else {
            return .none
        }
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

    var percentageType: PercentageType {
        if let _ = increment {
            return incrementPercentageType
        } else {
            return preppedPercentageType
        }
    }
}

public extension NutrientMeter2.ViewModel {
    
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

public extension NutrientMeter2.ViewModel {
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

extension NutrientMeter2.ViewModel {
    
    var labelTextColor: Color {
        guard haveGoal else { return component.textColor }
        switch percentageType {
        case .empty:
            return Colors.Empty.text
        case .regular:
            return component.textColor
        case .complete:
            return Colors.Complete.text
        case .excess:
            return Colors.Excess.text
        }
    }
    
}
