import SwiftUI

public extension NutrientMeter {
    class ViewModel: ObservableObject {
        
        @Published public var component: NutrientMeterComponent

        /// Used to convey that this is for a component that has been generated (either an implicit daily goal or a meal subgoal),
        /// as we may want to style it differently
        @Published public var isGenerated: Bool
        
        @Published public var goalLower: Double?
        @Published public var goalUpper: Double?

        @Published public var planned: Double
        @Published public var eaten: Double?
        @Published public var increment: Double?

        //TODO: Remove this
        @Published public var burned: Double
        
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

public extension NutrientMeter.ViewModel {
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

extension NutrientMeter.ViewModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(component)
        hasher.combine(goalLower)
        hasher.combine(goalUpper)
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

public enum GoalBoundsType {
    case none
    case lowerOnly
    case upperOnly
    case lowerAndUpper
}

public extension NutrientMeter.ViewModel {
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

//MARK: - 📲 Preview

let mockEatenFoodMeterViewModels: [NutrientMeter.ViewModel] = [
    NutrientMeter.ViewModel(component: .energy, goalLower: 1596, burned: 676, planned: 2272, eaten: 0),
    NutrientMeter.ViewModel(component: .carb, goalLower: 130, burned: 84, planned: 196, eaten: 156),
    NutrientMeter.ViewModel(component: .fat, goalLower: 44, burned: 27, planned: 44, eaten: 34),
    NutrientMeter.ViewModel(component: .protein, goalLower: 190, burned: 0, planned: 102, eaten: 82)
]

public let mockIncrementsFoodMeterViewModels: [NutrientMeter.ViewModel] = [
    NutrientMeter.ViewModel(component: .energy, goalLower: 1596, burned: 676, planned: 2272, increment: 500),
    NutrientMeter.ViewModel(component: .carb, goalLower: 130, burned: 84, planned: 196, increment: 100),
    NutrientMeter.ViewModel(component: .fat, goalLower: 44, burned: 27, planned: 44, increment: 204),
    NutrientMeter.ViewModel(component: .protein, goalLower: 190, burned: 0, planned: 102, increment: 52)
]

public struct NutrientBreakdownPreviewView: View {
    
//    @StateObject var viewModel = NutrientBreakdown.ViewModel(foodMeterViewModels: mockEatenFoodMeterViewModels)
//    @StateObject var viewModel = NutrientBreakdown.ViewModel(foodMeterViewModels: mockIncrementsFoodMeterViewModels)

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
    
    @StateObject var viewModel = NutrientBreakdown.ViewModel(
        energyViewModel: NutrientMeter.ViewModel(
            component: .energy,
            goalLower: K.Goal.energy,
            goalUpper: K.Goal.energy + 200,
            burned: 0, // 676,
            planned: 2272,
            eaten: K.Eaten.energy
        ),
        carbViewModel: NutrientMeter.ViewModel(
            component: .carb,
            goalUpper: K.Goal.carb,
            burned: 0, //84,
            planned: 196,
            eaten: K.Eaten.carb
        ),
        fatViewModel: NutrientMeter.ViewModel(
            component: .fat,
            goalUpper: K.Goal.fat,
            burned: 0, //27,
            planned: 44,
            eaten: K.Eaten.fat
        ),
        proteinViewModel: NutrientMeter.ViewModel(
            component: .protein,
            goalLower: K.Goal.protein,
            burned: 0,
            planned: 102,
            eaten: K.Eaten.protein
        )
    )
    
//    @StateObject var viewModel = NutrientBreakdown.ViewModel(foodMeterViewModels:
//        [
//            FoodMeter.ViewModel(component: .energy, goal: 1596, burned: 676, food: 2272, increment: 500),
//            FoodMeter.ViewModel(component: .carb, goal: 130, burned: 84, food: 196, increment: 100),
//            FoodMeter.ViewModel(component: .fat, goal: 44, burned: 27, food: 44, increment: 204),
//            FoodMeter.ViewModel(component: .protein, goal: 190, burned: 0, food: 102, increment: 52)
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
                NutrientBreakdown(viewModel: viewModel)
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
                viewModel.showingDetails = newValue
            }
        }
        .onChange(of: localIncludeBurnedCalories) { newValue in
            withAnimation(.spring()) {
                viewModel.includeBurnedCalories = newValue
            }
        }
        .onChange(of: localHaveGoal) { newValue in
            withAnimation(.spring()) {
                viewModel.haveGoal = newValue
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
                    Text("\(Int(viewModel.energyViewModel.planned))")
                case .eaten:
                    Text("\(Int(viewModel.energyViewModel.eaten ?? 0))")
                case .increment:
                    Text("\(Int(viewModel.energyViewModel.increment ?? 0))")
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
                slider(component: .carb, value: $viewModel.carbViewModel.planned, maxValue: K.Goal.carb * 3)
                slider(component: .fat, value: $viewModel.fatViewModel.planned, maxValue: K.Goal.fat * 3)
                slider(component: .protein, value: $viewModel.proteinViewModel.planned, maxValue: K.Goal.protein * 3)
            case .eaten:
//                slider(component: .carb, value: $incrementCarbValue, maxValue: 1500)
//                slider(component: .fat, value: $incrementFatValue, maxValue: 666.66666667)
//                slider(component: .protein, value: $incrementProteinValue, maxValue: 1500)
                //TODO-NEXT: Use modifiers to change values once triggered
                slider(component: .carb, value: $eatenCarbValue, maxValue: max(viewModel.carbViewModel.planned, 1))
                    .disabled(eatenCarbValue == 0)
                slider(component: .fat, value: $eatenFatValue, maxValue: max(viewModel.fatViewModel.planned, 1))
                    .disabled(eatenFatValue == 0)
                slider(component: .protein, value: $eatenProteinValue, maxValue: max(viewModel.proteinViewModel.planned, 1))
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
        .onChange(of: viewModel.carbViewModel.planned) { newValue in
            if newValue < eatenCarbValue {
                eatenCarbValue = newValue
            }
            if eatenCarbValue == 0 && newValue > 0 {
                eatenCarbValue = newValue
            }
            recalculateEnergy()
        }
        .onChange(of: viewModel.fatViewModel.planned) { newValue in
            if newValue < eatenFatValue {
                eatenFatValue = newValue
            }
            if eatenFatValue == 0 && newValue > 0 {
                eatenFatValue = newValue
            }
            recalculateEnergy()
        }
        .onChange(of: viewModel.proteinViewModel.planned) { newValue in
            if newValue < eatenProteinValue {
                eatenProteinValue = newValue
            }
            if eatenProteinValue == 0 && newValue > 0 {
                eatenProteinValue = newValue
            }
            recalculateEnergy()
        }
        .onChange(of: eatenCarbValue) { newValue in
            guard !(newValue == 0 && viewModel.carbViewModel.planned != 0) else {
                eatenCarbValue = 1
                return
            }
            viewModel.carbViewModel.eaten = newValue
            recalculateEatenEnergy()
            nullifyIncrementValues()
        }
        .onChange(of: eatenFatValue) { newValue in
            guard !(newValue == 0 && viewModel.fatViewModel.planned != 0) else {
                eatenFatValue = 1
                return
            }
            viewModel.fatViewModel.eaten = newValue
            recalculateEatenEnergy()
            nullifyIncrementValues()
        }
        .onChange(of: eatenProteinValue) { newValue in
            guard !(newValue == 0 && viewModel.proteinViewModel.planned != 0) else {
                eatenProteinValue = 1
                return
            }
            viewModel.proteinViewModel.eaten = newValue
            recalculateEatenEnergy()
            nullifyIncrementValues()
        }
        .onChange(of: incrementCarbValue) { newValue in
            viewModel.carbViewModel.increment = newValue
            nullifyEatenValues()
            recalculateIncrementEnergy()
        }
        .onChange(of: incrementFatValue) { newValue in
            viewModel.fatViewModel.increment = newValue
            nullifyEatenValues()
            recalculateIncrementEnergy()
        }
        .onChange(of: incrementProteinValue) { newValue in
            viewModel.proteinViewModel.increment = newValue
            nullifyEatenValues()
            recalculateIncrementEnergy()
        }
    }
    
    func nullifyIncrementValues() {
        viewModel.energyViewModel.increment = nil
        viewModel.carbViewModel.increment = nil
        viewModel.fatViewModel.increment = nil
        viewModel.proteinViewModel.increment = nil
    }

    func nullifyEatenValues() {
        viewModel.energyViewModel.eaten = nil
        viewModel.carbViewModel.eaten = nil
        viewModel.fatViewModel.eaten = nil
        viewModel.proteinViewModel.eaten = nil
    }

    func recalculateEnergy() {
        viewModel.energyViewModel.planned = (viewModel.proteinViewModel.planned * 4) + (viewModel.carbViewModel.planned * 4) + (viewModel.fatViewModel.planned * 9)
    }

    func recalculateEatenEnergy() {
        viewModel.energyViewModel.eaten = ((viewModel.proteinViewModel.eaten ?? 0) * 4) + ((viewModel.carbViewModel.eaten ?? 0) * 4) + ((viewModel.fatViewModel.eaten ?? 0) * 9)
    }

    func recalculateIncrementEnergy() {
        viewModel.energyViewModel.increment = ((viewModel.proteinViewModel.increment ?? 0) * 4) + ((viewModel.carbViewModel.increment ?? 0) * 4) + ((viewModel.fatViewModel.increment ?? 0) * 9)
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

extension NutrientMeter.ViewModel {
    
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
