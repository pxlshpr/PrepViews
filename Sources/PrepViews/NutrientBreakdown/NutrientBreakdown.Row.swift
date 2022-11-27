import SwiftUI

extension NutrientBreakdown {
    struct Row: View {
        @EnvironmentObject var breakdownViewModel: NutrientBreakdown.ViewModel
        @Binding var foodMeterViewModel: NutrientMeter.ViewModel
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
            if let iconImageName = foodMeterViewModel.component.iconImageName {
                Image(systemName: iconImageName)
                Spacer().frame(width: 2)
                if !showingDetails {
                    Text(foodMeterViewModel.component.name)
                }
            } else {
                Text(foodMeterViewModel.component.initial)
                if !showingDetails {
                    Text(foodMeterViewModel.component.name.dropFirst())
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
        .foregroundColor(foodMeterViewModel.labelTextColor)
        .fontWeight(.bold)
        .font(.title3)
//        .font(FontEnergyLabel)
    }
    
    var workoutsText: some View {
        Text(burnedString)
            .foregroundColor(foodMeterViewModel.labelTextColor)
            .font(.subheadline)
            .fontWeight(.semibold)
//            .font(FontEnergyValue)
    }
    
    var amountText: some View {
        Text(foodString)
            .foregroundColor(foodMeterViewModel.labelTextColor)
            .font(.subheadline)
            .fontWeight(.semibold)
//            .font(FontEnergyValue)
    }

    var totalGoalText: some View {
        Text(goalString)
            .foregroundColor(foodMeterViewModel.labelTextColor)
            .font(.subheadline)
            .fontWeight(.semibold)
//            .foregroundColor(Colors.placeholder)
//            .font(FontEnergyValue)
    }

    var gauge: some View {
        //TODO: See if just using an ObservedObject here is sufficient (instead of a binding)
        NutrientMeter(viewModel: $foodMeterViewModel)
//        FoodMeter(goal: $foodMeterViewModel.goal,
//                  food: $foodMeterViewModel.food,
//                  burned: $foodMeterViewModel.burned,
////                  eaten: $foodMeterViewModel.eaten,
//                  eaten: .constant(0),
//                  includeBurned: $breakdownViewModel.includeBurnedCalories,
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
            Text(foodMeterViewModel.component.unit)
//                Text(macro == nil ? "kcal" : "g")
                    .font(.footnote)
//            }
        }
        //TODO-NEXT: Replace this with the calculated massive possible value in the column
        .gridColumnAlignment(showingDetails ? .center : .leading)
        .frame(minWidth: 70, alignment: showingDetails ? .center : .leading)
        .foregroundColor(foodMeterViewModel.labelTextColor)
//        .foregroundColor(Color(.label))
    }

    //MARK: 🛠 Helpers
    struct Colors {
//        static let placeholder = Color("StatsEmptyFill")
        static let placeholder = Color.secondary
    }

    
    //MARK: Accessors
    
    var component: NutrientMeterComponent? { foodMeterViewModel.component }
    var remainingString: String { foodMeterViewModel.remainingString }
    var goalString: String { foodMeterViewModel.goalString }
    var burnedString: String { foodMeterViewModel.burnedString }
    var foodString: String { foodMeterViewModel.foodString }
    
    var showingDetails: Bool { breakdownViewModel.showingDetails }
    var includeBurnedCalories: Bool { breakdownViewModel.includeBurnedCalories }
}
