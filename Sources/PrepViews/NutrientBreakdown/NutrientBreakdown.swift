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
            row(foodMeterViewModel: $viewModel.energyViewModel)
            row(foodMeterViewModel: $viewModel.carbViewModel)
            row(foodMeterViewModel: $viewModel.fatViewModel)
            row(foodMeterViewModel: $viewModel.proteinViewModel)
//            ForEach(viewModel.foodMeterViewModels, id: \.self) { foodMeterViewModel in
//                row(foodMeterViewModel: foodMeterViewModel)
//            }
        }
    }
    
    @ViewBuilder
    func row(foodMeterViewModel: Binding<NutrientMeter.ViewModel>) -> some View {
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
        NutrientMeter.ViewModel(component: component, goalLower: 0, burned: 0, planned: 0, eaten: 0)
    }
}
