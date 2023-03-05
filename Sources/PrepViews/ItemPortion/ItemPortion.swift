import SwiftUI
import SwiftUISugar
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics
import FoodLabel
import PrepCoreDataStack

public struct ItemPortion: View {

    @Environment(\.colorScheme) var colorScheme
    @StateObject var model: Model

    @State var showingRDASettings: Bool = false
    
    @Binding var foodItem: MealItem
    @Binding var meal: DayMeal
    @Binding var day: Day?
    @Binding var lastUsedGoalSet: GoalSet?
    //    var day: Binding<Day?>

    @State var showingRDA = true
    @State var usingDietGoalsInsteadOfRDA = true
    
    @State var foodLabelData: FoodLabelData
    
    let didTapGoalSetButton: (Bool) -> ()
    let didUpdateUser = NotificationCenter.default.publisher(for: .didUpdateUser)

    public init(
        foodItem: Binding<MealItem>,
        meal: Binding<DayMeal>,
        day: Binding<Day?>,
        lastUsedGoalSet: Binding<GoalSet?>,
        userUnits: UserOptions.Units,
        bodyProfile: BodyProfile?,
        shouldCreateSubgoals: Bool = true,
        didTapGoalSetButton: @escaping (Bool) -> ()
    ) {
        _foodItem = foodItem
        _meal = meal
        _day = day
        _lastUsedGoalSet = lastUsedGoalSet
        
        let showingRDA = UserManager.showingRDAForPortion
        let usingDietGoalsInsteadOfRDA = UserManager.usingDietGoalsInsteadOfRDAForPortion
        _showingRDA = State(initialValue: UserManager.showingRDAForPortion)
        _usingDietGoalsInsteadOfRDA = State(initialValue: usingDietGoalsInsteadOfRDA)

        let model = Model(
            foodItem: foodItem.wrappedValue,
            meal: meal.wrappedValue,
            day: day.wrappedValue,
            lastUsedGoalSet: lastUsedGoalSet.wrappedValue,
            userUnits: userUnits,
            bodyProfile: bodyProfile,
            shouldCreateSubgoals: shouldCreateSubgoals
        )
        _model = StateObject(wrappedValue: model)

        let diet: GoalSet?
        if let unwrappedDay = day.wrappedValue {
            diet = unwrappedDay.goalSet
        } else {
            diet = lastUsedGoalSet.wrappedValue
        }

//        let diet = day.wrappedValue?.goalSet ?? lastUsedGoalSet.wrappedValue
        if usingDietGoalsInsteadOfRDA, let diet {
            _foodLabelData = State(initialValue: foodItem.wrappedValue.foodLabelData(
                showRDA: showingRDA,
                customRDAValues: diet.customRDAValues(with: model.goalCalcParams),
                dietName: model.dietNameWithEmoji
            ))
        } else {
            _foodLabelData = State(initialValue: foodItem.wrappedValue.foodLabelData(showRDA: showingRDA))
        }
        
        self.didTapGoalSetButton = didTapGoalSetButton
        
//        var types: [MetersType] = []
//        if meal.wrappedValue.goalSet != nil {
//            types.append(.meal)
//        } else if day.wrappedValue != nil {
//            if let mealsCount = day.wrappedValue?.meals.count, mealsCount > 1 {
//                types.append(.meal)
//            }
//            types.append(.diet)
//        }
//        types.append(.nutrients)
//        _metersTypes = State(initialValue: types)
    }
    
//
//    var determineMetersTypes: [MetersType] {
//        var types: [MetersType] = []
//        if model.shouldShowMealGoals {
//            types.append(.meal)
//        }
//        if model.day != nil {
//            types.append(.diet)
//        }
//        types.append(.nutrients)
//        return types
//    }
//
    public var body: some View {
        Group {
            VStack(spacing: 7) {
                header
                typePickerRow
                pager
                footer
            }
        }
        .onChange(of: foodItem) { newFoodItem in
            withAnimation {
                model.foodItem = newFoodItem
            }
        }
        .onChange(of: meal) { newValue in
            withAnimation {
                model.meal = meal
            }
        }
        .onChange(of: day) { newValue in
            withAnimation {
                model.day = day
            }
        }
        .onReceive(didUpdateUser, perform: didUpdateUser)
        .sheet(isPresented: $showingRDASettings) { rdaSettings }
    }
    
    func didUpdateUser(notification: Notification) {
        withAnimation {
            self.showingRDA = UserManager.showingRDAForPortion
            self.usingDietGoalsInsteadOfRDA = UserManager.usingDietGoalsInsteadOfRDAForPortion
        }
    }

    var rdaSettings: some View {
        Text("RDA Settings go here")
    }
    
    //MARK: Pager
    
    var pager: some View {
        Pager(
            page: model.page,
            data: PortionPage.allCases,
            id: \.self,
            content: { portionPage in
                content(for: portionPage)
                    .readSize { size in
                        model.pagerHeights[portionPage] = size.height
                    }
            }
        )
        .pagingPriority(.simultaneous)
        .onPageWillTransition(model.pageWillTransition)
//        .frame(height: 200)
//        .frame(height: model.pagerHeight)
        .frame(height: model.pagerHeights[model.portionPage])
    }
    
    @ViewBuilder
    func content(for portionPage: PortionPage) -> some View {
        if portionPage == .nutrients {
            foodLabelSection
        } else {
            ItemPortionMetrics(portionPage)
                .environmentObject(model)
                .frame(maxWidth: .infinity)
                .padding(.leading, 17)
                .padding(.vertical, 15)
                .background(FormCellBackground())
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
        }
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
            .onChange(of: foodItem, perform: foodItemChanged)
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
            foodLabelData = foodItem.foodLabelData(
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

    func foodItemChanged(_ newValue: MealItem) {
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
    
    @ViewBuilder
    var typePickerRow: some View {
        typePicker
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
    
    var footer: some View {
        Group {
            switch model.portionPage {
            case .nutrients:
                EmptyView()
//                legend
            case .diet:
                if model.hasDiet {
                    legend
                } else {
                    Text("Your daily goals will appear once you select a diet for the day.")
                }
            case .meal:
                if model.shouldShowMealContent {
                    legend
                } else {
                    Text(model.emptyMealFooterString)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(.secondaryLabel))
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }
    
//    var foodLabelSheet: some View {
//        FoodLabelSheet(foodItem: foodItem)
//    }

    var legend: some View {
        Legend(model: model)
    }
    
    var footer_legacy: some View {
        Text(model.portionPage.footerString)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(.secondaryLabel))
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .padding(.horizontal, 20)
    }

    var typePicker: some View {
        Picker("", selection: model.metersTypeBinding) {
            ForEach(PortionPage.allCases, id: \.self) {
                Text($0.description).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var arrow: some View {
        Image(systemName: "arrowshape.forward.fill")
            .rotationEffect(.degrees(90))
            .foregroundColor(Color(.quaternaryLabel))
    }
    
    //MARK: - GoalSet Picker
    @ViewBuilder
    var goalSetPicker: some View {
        switch model.portionPage {
        case .nutrients:
            nutrientsPicker
                .transition(.move(edge: .leading)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        case .diet:
            dietPicker
                .transition(.move(edge: .leading)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        case .meal:
            mealTypePicker
                .transition(.move(edge: .trailing)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        }
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
    
    var dietPicker: some View {
        picker(for: model.day?.goalSet)
    }
    
    var mealTypePicker: some View {
        picker(for: model.meal.goalSet, forMeal: true)
    }
    
    /// We're allowing nil to be passed into this so it can be used as a transparent placeholder
    func picker(for goalSet: GoalSet? = nil, forMeal: Bool = false) -> some View {
        
        var label: some View {
            HStack(spacing: 2) {
                if let emoji = goalSet?.emoji {
                    Text(emoji)
                        .font(.footnote)
                }
                Text(goalSet?.name ?? "Select \(forMeal ? "Meal Type" : "Diet")")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.accentColor)
//                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.footnote)
                    .imageScale(.small)
            }
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(
                        colorScheme == .dark ? 0.1 : 0.15
                    ))
            )
        }
        
        return Button {
            didTapGoalSetButton(model.portionPage == .meal)
        } label: {
            label
//                .padding(.trailing, 20)
        }
    }
    
    func picker_legacy() -> some View {
        HStack(spacing: 2) {
            Text("🫃🏽")
            Text("Cutting")
                .font(.footnote)
                .bold()
                .foregroundColor(.accentColor)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundColor(Color(.tertiaryLabel))
                .font(.footnote)
                .imageScale(.small)
        }
        .padding(.vertical, 5.5)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .foregroundColor(Color(.tertiarySystemFill))
        )
    }
}

//MARK: - MealItemMeters.Model (Legend)

extension ItemPortion.Model {
    
    var showMealSubgoals: Bool {
        guard portionPage == .meal else { return false }
        return currentMeterViewModels.contains {
            $0.isGenerated
        }
    }
    
    var showDietAutoGoals: Bool {
        guard portionPage == .diet else { return false }
        return currentMeterViewModels.contains {
            $0.isGenerated
        }
    }

    var showCompletion: Bool {
        currentMeterViewModels.contains {
            $0.percentageType == .complete
        }
    }
    
    var showExcess: Bool {
        currentMeterViewModels.contains {
            $0.percentageType == .excess
        }
    }
    
    var showSolidLine: Bool {
        currentMeterViewModels.contains {
            $0.goalBoundsType == .lowerAndUpper
            && !$0.percentageType.isPastCompletion
        }
    }
    
    var showFirstDashedLine: Bool {
        currentMeterViewModels.contains {
            $0.goalBoundsType == .lowerAndUpper
            &&
            ($0.percentageType == .complete || $0.percentageType == .excess)
        }
    }

    var showSecondDashedLine: Bool {
        currentMeterViewModels.contains {
            $0.goalBoundsType == .lowerAndUpper
            && $0.percentageType == .excess
        }
    }

    var componentsFromFood: [NutrientMeterComponent] {
//        foodItem.food.componentsForLegend
        let viewModelsWithTotal = currentMeterViewModels.filter {
            guard let increment = $0.increment else { return false }
            return increment > 0 && !$0.percentageType.isPastCompletion
        }
        
        /// Get components except for micro first (because there may be multiples of those)
        var components = viewModelsWithTotal
            .filter { !$0.component.isMicro }
            .map { $0.component }
        if viewModelsWithTotal.contains(where: { $0.component.isMicro }) {
            components.append(.micro(nutrientType: .sodium, nutrientUnit: .mg))
        }
        return components
    }
    
    var componentsWithTotals: [NutrientMeterComponent] {
        let viewModelsWithTotal = currentMeterViewModels.filter {
            $0.planned > 0 && !$0.percentageType.isPastCompletion
        }
        
        /// Get components except for micro first (because there may be multiples of those)
        var components = viewModelsWithTotal
            .filter { !$0.component.isMicro }
            .map { $0.component }
        if viewModelsWithTotal.contains(where: { $0.component.isMicro }) {
            components.append(.micro(nutrientType: .sodium, nutrientUnit: .mg))
        }
        return components
    }
}

extension PercentageType {
    var isPastCompletion: Bool {
        self == .complete || self == .excess
    }
}

extension NutrientMeter.Model {
    var showsRemainderWithoutLowerBound: Bool {
        guard !percentageType.isPastCompletion else { return false }
        guard goalBoundsType != .lowerAndUpper else {
            return goalLower != goalUpper
        }
        return true
    }

    var showsBoundedRemainder: Bool {
        !percentageType.isPastCompletion && goalBoundsType == .lowerAndUpper
    }
}

extension NutrientMeterComponent {
    var isMicro: Bool {
        switch self {
        case .micro:
            return true
        default:
            return false
        }
    }
}

//MARK: Food (Legend)
extension Food {
    var componentsForLegend: [NutrientMeterComponent] {
        var components: [NutrientMeterComponent] = []
        if info.nutrients.energyInKcal > 0 { components.append(.energy) }
        if info.nutrients.carb > 0 { components.append(.carb) }
        if info.nutrients.fat > 0 { components.append(.fat) }
        if info.nutrients.protein > 0 { components.append(.protein) }
        if info.nutrients.micros.contains(where: { $0.value > 0 }) {
            /// Add any micronutrient as legend shows the same color for all
            components.append(.micro(nutrientType: .sodium, nutrientUnit: .mg))
        }
        return components
    }
}

extension MealItem {
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

extension GoalSet {
    func customRDAValues(with goalCalcParams: GoalCalcParams) -> [AnyNutrient : (Double, NutrientUnit)] {
        var values: [AnyNutrient : (Double, NutrientUnit)] = [:]
        for goal in goals {
            guard let value = goal.calculateLowerBound(with: goalCalcParams) else { continue }
            values[goal.anyNutrient] = (
                value,
                goal.nutrientUnit(userUnits: goalCalcParams.userUnits)
            )
        }
        return values
    }
}

extension Goal {
    var anyNutrient: AnyNutrient {
        switch type {
        case .energy:
            return .energy
        case .macro(_, let macro):
            return .macro(macro)
        case .micro(_, let nutrientType, _):
            return .micro(nutrientType)
        }
    }
    
    func nutrientUnit(userUnits: UserOptions.Units) -> NutrientUnit {
        switch type {
        case .energy(let energyGoalType):
            return energyGoalType.nutrientUnit(userUnits: userUnits)
        case .macro:
            return .g
        case .micro(_, _, let nutrientUnit):
            return nutrientUnit
        }
    }
}

extension EnergyGoalType {
    func nutrientUnit(userUnits: UserOptions.Units) -> NutrientUnit {
        switch self {
        case .fixed(let energyUnit):
            return energyUnit.nutrientUnit
        case .fromMaintenance(let energyUnit, _):
            return energyUnit.nutrientUnit
        case .percentFromMaintenance(_):
            return userUnits.energy.nutrientUnit
        }
    }
}

extension EnergyUnit {
    var nutrientUnit: NutrientUnit {
        switch self {
        case .kcal:
            return .kcal
        case .kJ:
            return .kJ
        }
    }
}
