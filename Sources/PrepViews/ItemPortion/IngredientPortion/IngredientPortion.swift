import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics
import FoodLabel

public struct IngredientPortion: View {

    @AppStorage(UserDefaultsKeys.showingRDA) private var showingRDA = true
    @AppStorage(UserDefaultsKeys.usingDietGoalsInsteadOfRDA) private var usingDietGoalsInsteadOfRDA = true

    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: ViewModel
   
    @Binding var ingredientItem: IngredientItem
    @Binding var lastUsedGoalSet: GoalSet?

    @State var foodLabelData: FoodLabelData
    @State var showingRDASettings: Bool = false

    let didTapGoalSetButton: (Bool) -> ()
    
    public init(
        ingredientItem: Binding<IngredientItem>,
        lastUsedGoalSet: Binding<GoalSet?>,
        userUnits: UserOptions.Units,
        bodyProfile: BodyProfile?,
        didTapGoalSetButton: @escaping (Bool) -> ()
    ) {
        _ingredientItem = ingredientItem
        _lastUsedGoalSet = lastUsedGoalSet
        
        let viewModel = ViewModel(
            ingredientItem: ingredientItem.wrappedValue,
            lastUsedGoalSet: lastUsedGoalSet.wrappedValue,
            userUnits: userUnits,
            bodyProfile: bodyProfile
        )
        _viewModel = StateObject(wrappedValue: viewModel)

        let showingRDA: Bool
        if let showingRDAValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.showingRDA) {
            showingRDA = showingRDAValue as? Bool ?? true
        } else {
            /// Make sure the initial value (if not set) is always `true`
            showingRDA = true
        }

        /// Make sure the initial value (if not set) is always `true`
        let usingDietGoalsInsteadOfRDA: Bool
        if let usingDietGoalsInsteadOfRDAValue = UserDefaults.standard.value(forKey: UserDefaultsKeys.usingDietGoalsInsteadOfRDA) {
            usingDietGoalsInsteadOfRDA = usingDietGoalsInsteadOfRDAValue as? Bool ?? true
        } else {
            /// Make sure the initial value (if not set) is always `true`
            usingDietGoalsInsteadOfRDA = true
        }

        let diet = lastUsedGoalSet.wrappedValue
        
        if usingDietGoalsInsteadOfRDA, let diet {
            _foodLabelData = State(initialValue: ingredientItem.wrappedValue.foodLabelData(
                showRDA: showingRDA,
                customRDAValues: diet.customRDAValues(with: viewModel.goalCalcParams),
                dietName: viewModel.dietNameWithEmoji
            ))
        } else {
            _foodLabelData = State(initialValue: ingredientItem.wrappedValue.foodLabelData(showRDA: showingRDA))
        }
        
        self.didTapGoalSetButton = didTapGoalSetButton
    }
    
    public var body: some View {
        Group {
            VStack(spacing: 7) {
                header
                foodLabelSection
            }
        }
        .onChange(of: ingredientItem) { newItem in
            withAnimation {
                viewModel.ingredientItem = newItem
            }
        }
        .sheet(isPresented: $showingRDASettings) { rdaSettings }
    }
    
    var rdaSettings: some View {
        Text("RDA Settings go here")
    }
    
    var foodLabelSection: some View {
        FormStyledSection {
            VStack {
                foodLabel
                Toggle("Use daily goals", isOn: $usingDietGoalsInsteadOfRDA)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .onChange(of: ingredientItem, perform: ingredientItemChanged)
            .onChange(of: showingRDA, perform: showingRDAChanged)
            .onChange(of: usingDietGoalsInsteadOfRDA, perform: usingDietGoalsInsteadOfRDAChanged)
        }
    }
    
    func usingDietGoalsInsteadOfRDAChanged(_ newValue: Bool) {
        updateFoodLabelData()
    }
    
    func updateFoodLabelData() {
        var customRDAValues: [AnyNutrient : (Double, NutrientUnit)] {
            guard usingDietGoalsInsteadOfRDA,
                  let diet = viewModel.diet
            else { return [:] }
            return diet.customRDAValues(with: viewModel.goalCalcParams)
        }
        withAnimation {
            foodLabelData = ingredientItem.foodLabelData(
                showRDA: showingRDA,
                customRDAValues: customRDAValues,
                dietName: viewModel.dietNameWithEmoji
            )
        }
    }

    func showingRDAChanged(_ newValue: Bool) {
        updateFoodLabelData()
    }

    func ingredientItemChanged(_ newValue: IngredientItem) {
        updateFoodLabelData()
    }
    
    var foodLabel: FoodLabel {
        FoodLabel(
            data: $foodLabelData,
            didTapFooter: didTapFoodLabelFooter
        )
    }
    
    func didTapFoodLabelFooter() {
        Haptics.feedback(style: .soft)
        showingRDASettings = true
    }
    
    var header: some View {
        HStack {
            Text("Portion Awareness")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
            Spacer()
            goalSetPicker
        }
        .foregroundColor(Color(.secondaryLabel))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 5)
    }
    
    //MARK: - GoalSet Picker
    
    @ViewBuilder
    var goalSetPicker: some View {
        nutrientsPicker
            .transition(.move(edge: .leading)
                .combined(with: .opacity)
                .combined(with: .scale)
            )
    }
    
    var nutrientsPicker: some View {
        var label: some View {
            HStack(spacing: 2) {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("% Daily Value")
            }
            .font(.footnote)
            .foregroundColor(.accentColor)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
                    .opacity(showingRDA ? 1 : 0)
            )
        }
        
        var button: some View {
            return Button {
                Haptics.feedback(style: .soft)
                showingRDA.toggle()
                
            } label: {
                label
            }
        }
        
        return button
    }
}

extension IngredientItem {
    func foodLabelData(
        showRDA: Bool,
        customRDAValues: [AnyNutrient : (Double, NutrientUnit)] = [:],
        dietName: String? = nil
    ) -> FoodLabelData {
        FoodLabelData(
            energyValue: FoodLabelValue(amount: scaledValueForEnergyInKcal, unit: .kcal),
            carb: scaledValueForMacro(.carb),
            fat: scaledValueForMacro(.fat),
            protein: scaledValueForMacro(.protein),
            nutrients: microsDict,
            quantityValue: amount.value,
            quantityUnit: amount.unitDescription(sizes: food.info.sizes),
            showRDA: showRDA,
            customRDAValues: customRDAValues,
            dietName: dietName
        )
    }
}
