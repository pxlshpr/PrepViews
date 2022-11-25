import SwiftUI
import SwiftUISugar

let FontSizeRegular: CGFloat = 20
let FontSizeSmall: CGFloat = 13

let FontEnergyLabel: Font = .system(size: FontSizeRegular, weight: .bold)
let FontEnergyValue: Font = .system(size: FontSizeRegular, weight: .semibold)
let FontEnergyUnit: Font = .system(size: FontSizeSmall, weight: .medium)

//MARK: - 🔵 NutrientBreakdown
public struct NutrientBreakdown: View {
    
    @ObservedObject var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        gaugesGrid
    }
    
    var gaugesGrid: some View {
        Grid(horizontalSpacing: viewModel.showingDetails ? 0 : nil) {
            if viewModel.includeHeaderRow {
                headerRow
                Divider()
            }
            row(foodMeterViewModel: viewModel.energyViewModel)
            row(foodMeterViewModel: viewModel.carbViewModel)
            row(foodMeterViewModel: viewModel.fatViewModel)
            row(foodMeterViewModel: viewModel.proteinViewModel)
//            ForEach(viewModel.foodMeterViewModels, id: \.self) { foodMeterViewModel in
//                row(foodMeterViewModel: foodMeterViewModel)
//            }
        }
    }
    
    @ViewBuilder
    func row(foodMeterViewModel: NutrientMeter.ViewModel) -> some View {
        Row(foodMeterViewModel: foodMeterViewModel)
            .environmentObject(viewModel)
            .if(!viewModel.haveGoal) { view in
                view.redacted(reason: .placeholder)
            }
//        if viewModel.haveGoal {
//            Row(viewModel: rowViewModel)
//                .environmentObject(viewModel)
//        } else {
//            Row(viewModel: rowViewModel)
//                .environmentObject(viewModel)
//                .redacted(reason: .placeholder)
//        }
    }
    
    var headerRow: some View {

        func headerTitle(_ string: String) -> some View {
            Text(string)
//                .font(.headline)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        
        var leftHeader: some View {
            headerTitle("Remaining")
                .gridCellColumns(viewModel.showingDetails ? 1 : 3)
        }

        var emptyGridCell: some View {
            Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
        }

        var plannedHeader: some View {
            headerTitle("Food")
        }

        var totalGoalHeader: some View {
            headerTitle("Goal")
        }

        var burnedHeader: some View {
            headerTitle("Burned")
        }

        return GridRow {
            if viewModel.showingDetails {
                emptyGridCell
                totalGoalHeader
                if viewModel.includeBurnedCalories {
                    plus
                    burnedHeader
                }
                minus
                plannedHeader
                equals
            }
            leftHeader
        }
        .frame(height: 20)
    }
}

var minus: some View {
    artithmeticIcon(name: "minus")
}

var plus: some View {
    artithmeticIcon(name: "plus")
}

var equals: some View {
    artithmeticIcon(name: "equal", labelColor: Color(.secondaryLabel))
}

func artithmeticIcon(name: String, labelColor: Color? = nil) -> some View {
    Image(systemName: "\(name).square.fill")
        .font(.title3)
        .foregroundColor(labelColor ?? Color(.quaternaryLabel))
}

//MARK: - 🔵 NutrientBreakdown.ViewModel

public extension NutrientBreakdown {
    class ViewModel: ObservableObject {
        @Published public var haveGoal: Bool = true
        @Published public var showingDetails: Bool = false
        @Published public var includeBurnedCalories: Bool = true
        @Published public var includeHeaderRow: Bool = true
        
//        @Published var foodMeterViewModels: [FoodMeter.ViewModel]
//        init(foodMeterViewModels: [FoodMeter.ViewModel]) {
//            self.foodMeterViewModels = foodMeterViewModels
//        }
        
        @Published public var energyViewModel: NutrientMeter.ViewModel
        @Published public var carbViewModel: NutrientMeter.ViewModel
        @Published public var fatViewModel: NutrientMeter.ViewModel
        @Published public var proteinViewModel: NutrientMeter.ViewModel
        
        public required init(energyViewModel: NutrientMeter.ViewModel, carbViewModel: NutrientMeter.ViewModel, fatViewModel: NutrientMeter.ViewModel, proteinViewModel: NutrientMeter.ViewModel) {
            self.energyViewModel = energyViewModel
            self.carbViewModel = carbViewModel
            self.fatViewModel = fatViewModel
            self.proteinViewModel = proteinViewModel
        }
        
        public static var empty: ViewModel {
            Self.init(
                energyViewModel: NutrientMeter.ViewModel.empty(for: .energy),
                carbViewModel: NutrientMeter.ViewModel.empty(for: .carb),
                fatViewModel: NutrientMeter.ViewModel.empty(for: .fat),
                proteinViewModel: NutrientMeter.ViewModel.empty(for: .protein)
            )
        }
    }
}

public extension NutrientMeter.ViewModel {
    static func empty(for component: NutrientMeterComponent) -> NutrientMeter.ViewModel {
        NutrientMeter.ViewModel(component: component, goal: 0, burned: 0, food: 0, eaten: 0)
    }
}

//MARK: - 📲 Preview

let mockEatenFoodMeterViewModels: [NutrientMeter.ViewModel] = [
    NutrientMeter.ViewModel(component: .energy, goal: 1596, burned: 676, food: 2272, eaten: 0),
    NutrientMeter.ViewModel(component: .carb, goal: 130, burned: 84, food: 196, eaten: 156),
    NutrientMeter.ViewModel(component: .fat, goal: 44, burned: 27, food: 44, eaten: 34),
    NutrientMeter.ViewModel(component: .protein, goal: 190, burned: 0, food: 102, eaten: 82)
]

public let mockIncrementsFoodMeterViewModels: [NutrientMeter.ViewModel] = [
    NutrientMeter.ViewModel(component: .energy, goal: 1596, burned: 676, food: 2272, increment: 500),
    NutrientMeter.ViewModel(component: .carb, goal: 130, burned: 84, food: 196, increment: 100),
    NutrientMeter.ViewModel(component: .fat, goal: 44, burned: 27, food: 44, increment: 204),
    NutrientMeter.ViewModel(component: .protein, goal: 190, burned: 0, food: 102, increment: 52)
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
        energyViewModel: NutrientMeter.ViewModel(component: .energy, goal: K.Goal.energy, burned: 676, food: 2272, eaten: K.Eaten.energy),
        carbViewModel: NutrientMeter.ViewModel(component: .carb, goal: K.Goal.carb, burned: 84, food: 196, eaten: K.Eaten.carb),
        fatViewModel: NutrientMeter.ViewModel(component: .fat, goal: K.Goal.fat, burned: 27, food: 44, eaten: K.Eaten.fat),
        proteinViewModel: NutrientMeter.ViewModel(component: .protein, goal: K.Goal.protein, burned: 0, food: 102, eaten: K.Eaten.protein)
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
