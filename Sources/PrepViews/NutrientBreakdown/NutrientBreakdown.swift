import SwiftUI
import SwiftUISugar
import PrepDataTypes

let FontSizeRegular: CGFloat = 20
let FontSizeSmall: CGFloat = 13

let FontEnergyLabel: Font = .system(size: FontSizeRegular, weight: .bold)
let FontEnergyValue: Font = .system(size: FontSizeRegular, weight: .semibold)
let FontEnergyUnit: Font = .system(size: FontSizeSmall, weight: .medium)

//MARK: - 🔵 NutrientBreakdown
public struct NutrientBreakdown: View {
    
    @ObservedObject var model: Model

    public init(model: Model) {
        self.model = model
    }
    
    public var body: some View {
        gaugesGrid
    }
    
    var gaugesGrid: some View {
        Grid(horizontalSpacing: model.showingDetails ? 0 : nil) {
            if model.includeHeaderRow {
                headerRow
                Divider()
            }
            row(foodMeterModel: $model.energyModel)
            row(foodMeterModel: $model.carbModel)
            row(foodMeterModel: $model.fatModel)
            row(foodMeterModel: $model.proteinModel)
//            ForEach(model.foodMeterModels, id: \.self) { foodMeterModel in
//                row(foodMeterModel: foodMeterModel)
//            }
        }
    }
    
    @ViewBuilder
    func row(foodMeterModel: Binding<NutrientMeter.Model>) -> some View {
        Row(foodMeterModel: foodMeterModel)
            .environmentObject(model)
            .if(!model.haveGoal) { view in
                view.redacted(reason: .placeholder)
            }
//        if model.haveGoal {
//            Row(model: rowModel)
//                .environmentObject(model)
//        } else {
//            Row(model: rowModel)
//                .environmentObject(model)
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
                .gridCellColumns(model.showingDetails ? 1 : 3)
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
            if model.showingDetails {
                emptyGridCell
                totalGoalHeader
                if model.includeBurnedCalories {
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

//MARK: - 🔵 NutrientBreakdown.Model

public extension NutrientBreakdown {
    class Model: ObservableObject {
        @Published public var haveGoal: Bool = true
        @Published public var showingDetails: Bool = false
        @Published public var includeBurnedCalories: Bool = true
        @Published public var includeHeaderRow: Bool = true
        
//        @Published var foodMeterModels: [FoodMeter.Model]
//        init(foodMeterModels: [FoodMeter.Model]) {
//            self.foodMeterModels = foodMeterModels
//        }
        
        @Published public var energyModel: NutrientMeter.Model
        @Published public var carbModel: NutrientMeter.Model
        @Published public var fatModel: NutrientMeter.Model
        @Published public var proteinModel: NutrientMeter.Model
        
        public required init(energyModel: NutrientMeter.Model, carbModel: NutrientMeter.Model, fatModel: NutrientMeter.Model, proteinModel: NutrientMeter.Model) {
            self.energyModel = energyModel
            self.carbModel = carbModel
            self.fatModel = fatModel
            self.proteinModel = proteinModel
        }
        
        public static var empty: Model {
            Self.init(
                energyModel: NutrientMeter.Model.empty(for: .energy),
                carbModel: NutrientMeter.Model.empty(for: .carb),
                fatModel: NutrientMeter.Model.empty(for: .fat),
                proteinModel: NutrientMeter.Model.empty(for: .protein)
            )
        }
    }
}

public extension NutrientMeter.Model {
    static func empty(for component: NutrientMeterComponent) -> NutrientMeter.Model {
        NutrientMeter.Model(component: component, goalLower: 0, burned: 0, planned: 0, eaten: 0)
    }
}
