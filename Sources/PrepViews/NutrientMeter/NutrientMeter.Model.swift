import SwiftUI
import PrepDataTypes

public extension NutrientMeter {
    struct Model {
        
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
        
        public init(
            component: NutrientMeterComponent,
            isGenerated: Bool = false,
            customPercentage: Double,
            customValue: Double
        ) {
            self.component = component
            self.isGenerated = isGenerated
            self.goalLower = nil
            self.goalUpper = nil
            self.burned = 0
            self.planned = customPercentage == 0 ? 0 : (customValue / customPercentage)
            self.eaten = customValue
            self.increment = nil
        }
    }
}

public extension NutrientMeter.Model {
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

//extension NutrientMeter2.Model: Hashable {
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
//extension NutrientMeter2.Model: Equatable {
//    public static func ==(lhs: NutrientMeter2.Model, rhs: NutrientMeter2.Model) -> Bool {
//        lhs.hashValue == rhs.hashValue
//    }
//}

public extension NutrientMeter.Model {
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

public extension NutrientMeter.Model {
    
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
//        case .empty:
//            return Color("StatsEmptyFill", bundle: .module)
        case .regular, .empty:
            return component.eatenColor
        case .complete:
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        case .excess:
            return haveGoal ? Colors.Excess.fill : component.eatenColor
        }
    }
    
    var textColor: Color {
        guard preppedPercentageType != .complete else {
            return haveGoal ? Colors.Complete.fill : component.eatenColor
        }
        
        /// Override the empty color only
        if eatenPercentageType == .empty { return component.eatenColor }
        return eatenColor
    }
}

public extension NutrientMeter.Model {
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

extension NutrientMeter.Model {
    
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

//MARK: - 📲 Preview

let mockEatenFoodMeterModels: [NutrientMeter.Model] = [
    NutrientMeter.Model(component: .energy, goalLower: 1596, burned: 676, planned: 2272, eaten: 0),
    NutrientMeter.Model(component: .carb, goalLower: 130, burned: 84, planned: 196, eaten: 156),
    NutrientMeter.Model(component: .fat, goalLower: 44, burned: 27, planned: 44, eaten: 34),
    NutrientMeter.Model(component: .protein, goalLower: 190, burned: 0, planned: 102, eaten: 82)
]

public let mockIncrementsFoodMeterModels: [NutrientMeter.Model] = [
    NutrientMeter.Model(component: .energy, goalLower: 1596, burned: 676, planned: 2272, increment: 500),
    NutrientMeter.Model(component: .carb, goalLower: 130, burned: 84, planned: 196, increment: 100),
    NutrientMeter.Model(component: .fat, goalLower: 44, burned: 27, planned: 44, increment: 204),
    NutrientMeter.Model(component: .protein, goalLower: 190, burned: 0, planned: 102, increment: 52)
]

public struct NutrientBreakdownPreviewView: View {
    
//    @StateObject var model = NutrientBreakdown.Model(foodMeterModels: mockEatenFoodMeterModels)
//    @StateObject var model = NutrientBreakdown.Model(foodMeterModels: mockIncrementsFoodMeterModels)

    struct K {
        struct Goal {
            static let energy: Double = 1676
            static let carb: Double = 130
            static let fat: Double = 44
            static let protein: Double = 190
        }
        
        struct Eaten {
            static let energy: Double = 918
            static let carb: Double = 100
            static let fat: Double = 22
            static let protein: Double = 80
        }
    }
    
    @StateObject var model = NutrientBreakdown.Model(
        energyModel: NutrientMeter.Model(
            component: .energy,
            goalLower: K.Goal.energy,
            goalUpper: K.Goal.energy + 200,
            burned: 0, // 676,
            planned: 2272,
            eaten: K.Eaten.energy
        ),
        carbModel: NutrientMeter.Model(
            component: .carb,
            goalUpper: K.Goal.carb,
            burned: 0, //84,
            planned: 196,
            eaten: K.Eaten.carb
        ),
        fatModel: NutrientMeter.Model(
            component: .fat,
            goalUpper: K.Goal.fat,
            burned: 0, //27,
            planned: 44,
            eaten: K.Eaten.fat
        ),
        proteinModel: NutrientMeter.Model(
            component: .protein,
            goalLower: K.Goal.protein,
            burned: 0,
            planned: 102,
            eaten: K.Eaten.protein
        )
    )
    
//    @StateObject var model = NutrientBreakdown.Model(foodMeterModels:
//        [
//            FoodMeter.Model(component: .energy, goal: 1596, burned: 676, food: 2272, increment: 500),
//            FoodMeter.Model(component: .carb, goal: 130, burned: 84, food: 196, increment: 100),
//            FoodMeter.Model(component: .fat, goal: 44, burned: 27, food: 44, increment: 204),
//            FoodMeter.Model(component: .protein, goal: 190, burned: 0, food: 102, increment: 52)
//        ]
//    )

    @State var localShowingDetails: Bool = false
    @State var localIncludeBurnedCalories: Bool = true
    @State var localHaveGoal: Bool = true

    public init() {
        
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                Spacer()
                NutrientBreakdown(model: model)
                Spacer()
                valueSliders
                haveGoalPicker
                includeBurnedCaloriesPicker
                detailsPicker
            }
            .padding(.horizontal, 20)
        }
        .onChange(of: localShowingDetails) { newValue in
            withAnimation(.spring()) {
                model.showingDetails = newValue
            }
        }
        .onChange(of: localIncludeBurnedCalories) { newValue in
            withAnimation(.spring()) {
                model.includeBurnedCalories = newValue
            }
        }
        .onChange(of: localHaveGoal) { newValue in
            withAnimation(.spring()) {
                model.haveGoal = newValue
            }
        }

    }
    
//    @State var foodEnergyValue: Double = 0
//    @State var foodCarbValue: Double = 0
//    @State var foodFatValue: Double = 0
//    @State var foodProteinValue: Double = 0
//
    @State var eatenEnergyValue: Double = K.Eaten.energy
    @State var eatenCarbValue: Double = K.Eaten.carb
    @State var eatenFatValue: Double = K.Eaten.fat
    @State var eatenProteinValue: Double = K.Eaten.protein

    @State var incrementEnergyValue: Double = 0
    @State var incrementCarbValue: Double = 0
    @State var incrementFatValue: Double = 0
    @State var incrementProteinValue: Double = 0

    @State var inputValueType: InputValueType = .food
    
    func slider(component: NutrientMeterComponent, value: Binding<Double>, maxValue: Double) -> some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("\(component.name):")
                    .font(.headline)
                    .foregroundColor(component.textColor)
//                    .bold()
                Text("\(Int(value.wrappedValue))")
                    .font(.subheadline)
                Spacer()
            }
            Slider(value: value, in: 0...maxValue, step: 1)
        }
        .accentColor(component.textColor)
    }
    
    enum InputValueType: String, CaseIterable {
        case food = "Food"
        case eaten = "Eaten"
        case increment = "Increment"
    }
    
    var energyValue: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(NutrientMeterComponent.energy.name):")
                .font(.headline)
                .foregroundColor(NutrientMeterComponent.energy.textColor)
            //                    .bold()
            Group {
                switch inputValueType {
                case .food:
                    Text("\(Int(model.energyModel.planned))")
                case .eaten:
                    Text("\(Int(model.energyModel.eaten ?? 0))")
                case .increment:
                    Text("\(Int(model.energyModel.increment ?? 0))")
                }
            }
            .font(.subheadline)
            Text("kcal")
        }
    }
    
    var valueSliders: some View {
        VStack {
            Picker("", selection: $inputValueType) {
                ForEach(InputValueType.allCases, id: \.self) { inputValueType in
                    Text(inputValueType.rawValue)
                }
            }
            .pickerStyle(.segmented)
            switch inputValueType {
            case .food:
                slider(component: .carb, value: $model.carbModel.planned, maxValue: K.Goal.carb * 3)
                slider(component: .fat, value: $model.fatModel.planned, maxValue: K.Goal.fat * 3)
                slider(component: .protein, value: $model.proteinModel.planned, maxValue: K.Goal.protein * 3)
            case .eaten:
//                slider(component: .carb, value: $incrementCarbValue, maxValue: 1500)
//                slider(component: .fat, value: $incrementFatValue, maxValue: 666.66666667)
//                slider(component: .protein, value: $incrementProteinValue, maxValue: 1500)
                //TODO-NEXT: Use modifiers to change values once triggered
                slider(component: .carb, value: $eatenCarbValue, maxValue: max(model.carbModel.planned, 1))
                    .disabled(eatenCarbValue == 0)
                slider(component: .fat, value: $eatenFatValue, maxValue: max(model.fatModel.planned, 1))
                    .disabled(eatenFatValue == 0)
                slider(component: .protein, value: $eatenProteinValue, maxValue: max(model.proteinModel.planned, 1))
                    .disabled(eatenProteinValue == 0)
            case .increment:
                slider(component: .carb, value: $incrementCarbValue, maxValue: K.Goal.carb * 3)
                slider(component: .fat, value: $incrementFatValue, maxValue: K.Goal.fat * 3)
                slider(component: .protein, value: $incrementProteinValue, maxValue: K.Goal.protein * 3)
            }
            energyValue
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 15.0)
                .stroke(lineWidth: 2.0)
                .foregroundColor(Color(.secondarySystemFill))
        )
        .onChange(of: model.carbModel.planned) { newValue in
            if newValue < eatenCarbValue {
                eatenCarbValue = newValue
            }
            if eatenCarbValue == 0 && newValue > 0 {
                eatenCarbValue = newValue
            }
            recalculateEnergy()
        }
        .onChange(of: model.fatModel.planned) { newValue in
            if newValue < eatenFatValue {
                eatenFatValue = newValue
            }
            if eatenFatValue == 0 && newValue > 0 {
                eatenFatValue = newValue
            }
            recalculateEnergy()
        }
        .onChange(of: model.proteinModel.planned) { newValue in
            if newValue < eatenProteinValue {
                eatenProteinValue = newValue
            }
            if eatenProteinValue == 0 && newValue > 0 {
                eatenProteinValue = newValue
            }
            recalculateEnergy()
        }
        .onChange(of: eatenCarbValue) { newValue in
            guard !(newValue == 0 && model.carbModel.planned != 0) else {
                eatenCarbValue = 1
                return
            }
            model.carbModel.eaten = newValue
            recalculateEatenEnergy()
            nullifyIncrementValues()
        }
        .onChange(of: eatenFatValue) { newValue in
            guard !(newValue == 0 && model.fatModel.planned != 0) else {
                eatenFatValue = 1
                return
            }
            model.fatModel.eaten = newValue
            recalculateEatenEnergy()
            nullifyIncrementValues()
        }
        .onChange(of: eatenProteinValue) { newValue in
            guard !(newValue == 0 && model.proteinModel.planned != 0) else {
                eatenProteinValue = 1
                return
            }
            model.proteinModel.eaten = newValue
            recalculateEatenEnergy()
            nullifyIncrementValues()
        }
        .onChange(of: incrementCarbValue) { newValue in
            model.carbModel.increment = newValue
            nullifyEatenValues()
            recalculateIncrementEnergy()
        }
        .onChange(of: incrementFatValue) { newValue in
            model.fatModel.increment = newValue
            nullifyEatenValues()
            recalculateIncrementEnergy()
        }
        .onChange(of: incrementProteinValue) { newValue in
            model.proteinModel.increment = newValue
            nullifyEatenValues()
            recalculateIncrementEnergy()
        }
    }
    
    func nullifyIncrementValues() {
        model.energyModel.increment = nil
        model.carbModel.increment = nil
        model.fatModel.increment = nil
        model.proteinModel.increment = nil
    }

    func nullifyEatenValues() {
        model.energyModel.eaten = nil
        model.carbModel.eaten = nil
        model.fatModel.eaten = nil
        model.proteinModel.eaten = nil
    }

    func recalculateEnergy() {
        model.energyModel.planned = (model.proteinModel.planned * 4) + (model.carbModel.planned * 4) + (model.fatModel.planned * 9)
    }

    func recalculateEatenEnergy() {
        model.energyModel.eaten = ((model.proteinModel.eaten ?? 0) * 4) + ((model.carbModel.eaten ?? 0) * 4) + ((model.fatModel.eaten ?? 0) * 9)
    }

    func recalculateIncrementEnergy() {
        model.energyModel.increment = ((model.proteinModel.increment ?? 0) * 4) + ((model.carbModel.increment ?? 0) * 4) + ((model.fatModel.increment ?? 0) * 9)
    }

    var detailsPicker: some View {
        HStack {
            Text("Details: ")
            Picker("", selection: $localShowingDetails) {
                Text("Hide").tag(false)
                Text("Show").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    var haveGoalPicker: some View {
        HStack {
            Text("Goal: ")
            Picker("", selection: $localHaveGoal) {
                Text("Set").tag(true)
                Text("Not Set").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }

    var includeBurnedCaloriesPicker: some View {
        HStack {
            Text("Burned Calories: ")
            Picker("", selection: $localIncludeBurnedCalories) {
                Text("Include").tag(true)
                Text("Exclude").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }
}

struct NutrientBreakdown_Previews: PreviewProvider {

    static var previews: some View {
        NutrientBreakdownPreviewView()
//            .preferredColorScheme(.dark)
    }

}

