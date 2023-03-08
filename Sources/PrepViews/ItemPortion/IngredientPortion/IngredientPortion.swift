import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics
import FoodLabel
import PrepCoreDataStack

public struct IngredientPortion: View {

    @Environment(\.colorScheme) var colorScheme
    @StateObject var model: Model
   
    @Binding var ingredientItem: IngredientItem
    @Binding var lastUsedGoalSet: GoalSet?

    @State var foodLabelData: FoodLabelData
    @State var showingRDASettings: Bool = false

    @State var showingRDA = true
    @State var usingDietGoalsInsteadOfRDA = true

    let didTapGoalSetButton: (Bool) -> ()
    let didUpdateUser = NotificationCenter.default.publisher(for: .didUpdateUser)
    
    public init(
        ingredientItem: Binding<IngredientItem>,
        lastUsedGoalSet: Binding<GoalSet?>,
        userUnits: UserOptions.Units,
        biometrics: Biometrics?,
        didTapGoalSetButton: @escaping (Bool) -> ()
    ) {
        _ingredientItem = ingredientItem
        _lastUsedGoalSet = lastUsedGoalSet
        
        let showingRDA = UserManager.showingRDAForPortion
        let usingDietGoalsInsteadOfRDA = UserManager.usingDietGoalsInsteadOfRDAForPortion
        _showingRDA = State(initialValue: UserManager.showingRDAForPortion)
        _usingDietGoalsInsteadOfRDA = State(initialValue: usingDietGoalsInsteadOfRDA)

        let model = Model(
            ingredientItem: ingredientItem.wrappedValue,
            lastUsedGoalSet: lastUsedGoalSet.wrappedValue,
            userUnits: userUnits,
            biometrics: biometrics
        )
        _model = StateObject(wrappedValue: model)

        let diet = lastUsedGoalSet.wrappedValue
        
        if usingDietGoalsInsteadOfRDA, let diet {
            _foodLabelData = State(initialValue: ingredientItem.wrappedValue.foodLabelData(
                showRDA: showingRDA,
                customRDAValues: diet.customRDAValues(with: model.goalCalcParams),
                dietName: model.dietNameWithEmoji
            ))
        } else {
            _foodLabelData = State(initialValue: ingredientItem.wrappedValue.foodLabelData(showRDA: showingRDA))
        }
        
        self.didTapGoalSetButton = didTapGoalSetButton
    }
    
    func didUpdateUser(notification: Notification) {
        withAnimation {
            self.showingRDA = UserManager.showingRDAForPortion
            self.usingDietGoalsInsteadOfRDA = UserManager.usingDietGoalsInsteadOfRDAForPortion
        }
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
                model.ingredientItem = newItem
            }
        }
        .onReceive(didUpdateUser, perform: didUpdateUser)
        .sheet(isPresented: $showingRDASettings) { rdaSettings }
    }
    
    var rdaSettings: some View {
        Text("RDA Settings go here")
    }
    
    var foodLabelSection: some View {
        FormStyledSection {
            VStack {
                foodLabel
                if showingRDA {
                    Toggle("Use daily goals", isOn: $usingDietGoalsInsteadOfRDA)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onChange(of: ingredientItem, perform: ingredientItemChanged)
            .onChange(of: showingRDA, perform: showingRDAChanged)
            .onChange(of: usingDietGoalsInsteadOfRDA, perform: usingDietGoalsInsteadOfRDAChanged)
        }
    }
    
    func usingDietGoalsInsteadOfRDAChanged(_ newValue: Bool) {
        updateFoodLabelData()
        UserManager.usingDietGoalsInsteadOfRDAForPortion = newValue
    }
    
    func updateFoodLabelData() {
        var customRDAValues: [AnyNutrient : (Double, NutrientUnit)] {
            guard usingDietGoalsInsteadOfRDA,
                  let diet = model.diet
            else { return [:] }
            return diet.customRDAValues(with: model.goalCalcParams)
        }
        withAnimation {
            foodLabelData = ingredientItem.foodLabelData(
                showRDA: showingRDA,
                customRDAValues: customRDAValues,
                dietName: model.dietNameWithEmoji
            )
        }
    }

    func showingRDAChanged(_ newValue: Bool) {
        updateFoodLabelData()
        UserManager.showingRDAForPortion = newValue
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
