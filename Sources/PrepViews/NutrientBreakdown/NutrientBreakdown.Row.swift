import SwiftUI
import PrepDataTypes

extension NutrientBreakdown {
    struct Row: View {
        @EnvironmentObject var breakdownModel: NutrientBreakdown.Model
        @Binding var foodMeterModel: NutrientMeter.Model
    }
}

extension NutrientBreakdown.Row {
    
    var body: some View {
        GridRow {
            label
            if showingDetails {
                totalGoalText
                if includeBurnedCalories {
                    plus
                    workoutsText
                }
                minus
                amountText
            }
            if showingDetails {
                equals
            } else {
                gauge
            }
            leftText
        }
        .frame(height: 22)
        .transition(.scale.combined(with: .opacity))
    }
    
    //MARK: Components
    
    var label: some View {
        
        return HStack(spacing: 0) {
            if let iconImageName = foodMeterModel.component.iconImageName {
                Image(systemName: iconImageName)
                Spacer().frame(width: 2)
                if !showingDetails {
                    Text(foodMeterModel.component.name)
                }
            } else {
                Text(foodMeterModel.component.initial)
                if !showingDetails {
                    Text(foodMeterModel.component.name.dropFirst())
                }
            }
        }
        //TODO: Separate this into an optional icon systemImageName and initial, both provided by the FoodMeterComponent
//        return HStack(spacing: 0) {
//            if macro == nil {
//                Image(systemName: "flame.fill")
//            }
//            if let macro = macro {
//                HStack(spacing: 0) {
//                    Text(macro.initial)
//                    if !showingDetails {
//                        Text(macro.rawValue.dropFirst())
//                    }
//                }
//            } else if !showingDetails {
//                Spacer().frame(width: 2)
//                Text("Energy")
//            }
//        }
        .gridColumnAlignment(showingDetails ? .center : .trailing)
        
        //TODO: Have all colors provided by FoodMeterComponent
        .foregroundColor(foodMeterModel.labelTextColor)
        .fontWeight(.bold)
        .font(.title3)
//        .font(FontEnergyLabel)
    }
    
    var workoutsText: some View {
        Text(burnedString)
            .foregroundColor(foodMeterModel.labelTextColor)
            .font(.subheadline)
            .fontWeight(.semibold)
//            .font(FontEnergyValue)
    }
    
    var amountText: some View {
        Text(foodString)
            .foregroundColor(foodMeterModel.labelTextColor)
            .font(.subheadline)
            .fontWeight(.semibold)
//            .font(FontEnergyValue)
    }

    var totalGoalText: some View {
        Text(goalString)
            .foregroundColor(foodMeterModel.labelTextColor)
            .font(.subheadline)
            .fontWeight(.semibold)
//            .foregroundColor(Colors.placeholder)
//            .font(FontEnergyValue)
    }

    var gauge: some View {
        //TODO: See if just using an ObservedObject here is sufficient (instead of a binding)
        NutrientMeter(model: $foodMeterModel)
//        FoodMeter(goal: $foodMeterModel.goal,
//                  food: $foodMeterModel.food,
//                  burned: $foodMeterModel.burned,
////                  eaten: $foodMeterModel.eaten,
//                  eaten: .constant(0),
//                  includeBurned: $breakdownModel.includeBurnedCalories,
//                  type: FoodMeterComponent(macro: macro)
//        )
    }

    var leftText: some View {
        HStack(spacing: 3) {
            Text(remainingString)
                .font(.headline)
                .fontWeight(.bold)
//            if !showingDetails {
            //TODO: have units provided by FoodMeterComponent, utilising associated value for micro
            Text(foodMeterModel.component.unit.shortestDescription)
//                Text(macro == nil ? "kcal" : "g")
                    .font(.footnote)
//            }
        }
        //TODO-NEXT: Replace this with the calculated massive possible value in the column
        .gridColumnAlignment(showingDetails ? .center : .leading)
        .frame(minWidth: 70, alignment: showingDetails ? .center : .leading)
        .foregroundColor(foodMeterModel.labelTextColor)
//        .foregroundColor(Color(.label))
    }

    //MARK: 🛠 Helpers
    struct Colors {
//        static let placeholder = Color("StatsEmptyFill")
        static let placeholder = Color.secondary
    }

    
    //MARK: Accessors
    
    var component: NutrientMeterComponent? { foodMeterModel.component }
    var remainingString: String { foodMeterModel.remainingString }
    var goalString: String { foodMeterModel.goalString }
    var burnedString: String { foodMeterModel.burnedString }
    var foodString: String { foodMeterModel.foodString }
    
    var showingDetails: Bool { breakdownModel.showingDetails }
    var includeBurnedCalories: Bool { breakdownModel.includeBurnedCalories }
}
