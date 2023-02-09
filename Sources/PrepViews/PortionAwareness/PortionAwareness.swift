import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepMocks
import SwiftUIPager
import SwiftHaptics
import FoodLabel

public struct PortionAwareness: View {

    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: ViewModel

    @State var showingFoodLabel: Bool = false
//    @State var foodLabelHeight: CGFloat = 0
    
    @Binding var foodItem: MealFoodItem
    @Binding var meal: DayMeal
    @Binding var day: Day?
    //    var day: Binding<Day?>
    
    @State var foodLabelData: FoodLabelData
    
    let didTapGoalSetButton: (Bool) -> ()
    
    public init(
        foodItem: Binding<MealFoodItem>,
        meal: Binding<DayMeal>,
        day: Binding<Day?>,
        userUnits: UserUnits,
        bodyProfile: BodyProfile?,
        shouldCreateSubgoals: Bool = true,
        didTapGoalSetButton: @escaping (Bool) -> ()
    ) {
        _foodItem = foodItem
        _meal = meal
        _day = day
        
        _foodLabelData = State(initialValue: foodItem.wrappedValue.foodLabelData)

        let viewModel = ViewModel(
            foodItem: foodItem.wrappedValue,
            meal: meal.wrappedValue,
            day: day.wrappedValue,
            userUnits: userUnits,
            bodyProfile: bodyProfile,
            shouldCreateSubgoals: shouldCreateSubgoals
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        
        
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
//        if viewModel.shouldShowMealGoals {
//            types.append(.meal)
//        }
//        if viewModel.day != nil {
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
                viewModel.foodItem = newFoodItem
            }
        }
        .onChange(of: meal) { newValue in
            withAnimation {
                viewModel.meal = meal
            }
        }
        .onChange(of: day) { newValue in
            withAnimation {
                viewModel.day = day
            }
        }
        .onChange(of: viewModel.currentType) { newValue in
            UserDefaults.standard.setValue(newValue.rawValue, forKey: "portionAwarenessType")
        }
        .sheet(isPresented: $showingFoodLabel) { foodLabelSheet }
    }
    
    //MARK: Pager
    
    var pager: some View {
        Pager(
            page: viewModel.page,
            data: viewModel.metersTypes,
            id: \.self,
            content: { metersType in
                content(for: metersType)
                    .readSize { size in
                        viewModel.pagerHeights[metersType] = size.height
                    }
            }
        )
        .pagingPriority(.simultaneous)
        .onPageWillTransition(viewModel.pageWillTransition)
//        .frame(height: 200)
//        .frame(height: viewModel.pagerHeight)
        .frame(height: viewModel.pagerHeights[viewModel.currentType])
    }
    
    @ViewBuilder
    func content(for metersType: MetersType) -> some View {
        if metersType == .nutrients {
            FormStyledSection {
                foodLabel
                    .onChange(of: foodItem, perform: foodItemChanged)
            }
        } else {
            Meters(metersType)
                .environmentObject(viewModel)
                .frame(maxWidth: .infinity)
                .padding(.leading, 17)
                .padding(.vertical, 15)
                .background(FormCellBackground())
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    func foodItemChanged(_ newValue: MealFoodItem) {
        withAnimation {
            foodLabelData = foodItem.foodLabelData
        }
    }
    
    var foodLabel: FoodLabel {
        FoodLabel(data: $foodLabelData)
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
        if viewModel.metersTypes.count > 1 {
            typePicker
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }
    
    var footer: some View {
        Group {
            switch viewModel.currentType {
            case .nutrients:
                EmptyView()
//                legend
            case .diet:
                if viewModel.hasDiet {
                    legend
                } else {
                    Text("Your daily goals will appear once you select a diet for the day.")
                }
            case .meal:
                if viewModel.shouldShowMealContent {
                    legend
                } else {
                    Text(viewModel.emptyMealFooterString)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(.secondaryLabel))
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }
    
    var foodLabelSheet: some View {
        FoodLabelSheet(foodItem: foodItem)
    }

    var legend: some View {
        Legend(viewModel: viewModel)
    }
    
    var footer_legacy: some View {
        Text(viewModel.currentType.footerString)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(.secondaryLabel))
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .padding(.horizontal, 20)
    }

    var typePicker: some View {
        Picker("", selection: viewModel.metersTypeBinding) {
            ForEach(viewModel.metersTypes, id: \.self) {
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
        switch viewModel.currentType {
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
                Text("Food Label")
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
            )
        }
        
        var button: some View {
            return Button {
                Haptics.feedback(style: .soft)
                showingFoodLabel = true
            } label: {
                label
            }
        }
        
        return button
    }
    
    var dietPicker: some View {
        picker(for: viewModel.day?.goalSet)
    }
    
    var mealTypePicker: some View {
        picker(for: viewModel.meal.goalSet, forMeal: true)
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
            didTapGoalSetButton(viewModel.currentType == .meal)
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

//MARK: - MealItemMeters.ViewModel (Legend)

extension PortionAwareness.ViewModel {
    
    var showMealSubgoals: Bool {
        guard currentType == .meal else { return false }
        return currentMeterViewModels.contains {
            $0.isGenerated
        }
    }
    
    var showDietAutoGoals: Bool {
        guard currentType == .diet else { return false }
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
    
    var showingLegend: Bool {
        get {
            return UserDefaults.standard.object(forKey: "showingLegend") as? Bool ?? false
        }
        set(newValue) {
            UserDefaults.standard.setValue(newValue, forKey: "showingLegend")
        }
    }
}

extension PercentageType {
    var isPastCompletion: Bool {
        self == .complete || self == .excess
    }
}

extension NutrientMeter.ViewModel {
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

//MARK: - 👁‍🗨 Previews
import SwiftUISugar
import PrepDataTypes
import PrepMocks

public struct MealItemNutrientMetersPreview: View {
    
    public init() { }
    
    public var body: some View {
        NavigationView {
            FormStyledScrollView {
                textFieldSection
                portionAwareness
            }
            .navigationTitle("Log Food")
        }
    }
    
    var mockMeals: [DayMeal] {
        [
//            DayMeal(
//                name: "Breakfast",
//                time: 0,
//                goalSet: nil,
//                foodItems: []
//            ),
//            DayMeal(
//                name: "Lunch",
//                time: 0,
//                goalSet: nil,
//                foodItems: []
//            ),
//            DayMeal(
//                name: "Dinner",
//                time: 0,
//                goalSet: nil,
//                foodItems: []
//            ),
//            DayMeal(
//                name: "Supper",
//                time: 0,
//                goalSet: nil,
//                foodItems: [
//                    MealFoodItem(
//                        food: FoodMock.wheyProtein,
//                        amount: FoodValue(30, .g)
//                    )
//                ]
//            )
        ]
    }
    
    var mockDay: Day {
        Day(
            id: Date().calendarDayString,
            calendarDayString: Date().calendarDayString,
            goalSet: DietMock.cutting,
//            goalSet: nil,
            bodyProfile: BodyProfileMock.calculated,
            meals: mockMeals,
            syncStatus: .notSynced,
            updatedAt: 0
        )
    }
    
    var portionAwareness: some View {
        PortionAwareness(
            foodItem: foodItemBinding,
            meal: mealBinding,
            day: .constant(mockDay),
            userUnits: .standard,
            bodyProfile: BodyProfileMock.calculated,
            didTapGoalSetButton: { forMeal in
                
            }
        )
    }
    
    var mealBinding: Binding<DayMeal> {
        Binding<DayMeal>(
            get: {
                DayMeal(from: MealMock.preWorkoutWithItems)
//                DayMeal(
//                    name: "Temp meal",
//                    time: 0,
//                    goalSet: nil
//                )
            },
            set: { _ in }
        )
    }
    
    var foodItemBinding: Binding<MealFoodItem> {
        Binding<MealFoodItem>(
            get: {
                MealFoodItem(
                    food: FoodMock.wheyProtein,
                    amount: FoodValue(
                        value: value ?? 0,
                        unitType: .weight,
                        weightUnit: weightUnit),
                    isSoftDeleted: false
                )
            },
            set: { _ in }
        )
    }
    
    @State var weightUnit: WeightUnit = .g
    @State var value: Double? = 500
    @State var valueString: String = "500"

    var valueBinding: Binding<String> {
        Binding<String>(
            get: { valueString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    value = nil
                    valueString = newValue
                    return
                }
                guard let value = Double(newValue) else {
                    return
                }
                self.value = value
                withAnimation {
                    self.valueString = newValue
                }
            }
        )
    }
    
    var textFieldSection: some View {
        var unitPicker: some View {
            Button {
                weightUnit = weightUnit == .g ? .oz : .g
            } label: {
                HStack(spacing: 5) {
                    Text(weightUnit == .g ? "g" : "oz")
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
            }
            .buttonStyle(.borderless)
        }
        
        return FormStyledSection(header: Text("Weight")) {
            HStack {
                TextField("Required", text: valueBinding)
                    .keyboardType(.decimalPad)
                unitPicker
            }
        }
    }
}

extension MealFoodItem {
    var foodLabelData: FoodLabelData {
        FoodLabelData(
            energyValue: FoodLabelValue(amount: scaledValueForEnergyInKcal, unit: .kcal),
            carb: scaledValueForMacro(.carb),
            fat: scaledValueForMacro(.fat),
            protein: scaledValueForMacro(.protein),
            nutrients: microsDict,
            quantityValue: amount.value,
            quantityUnit: amount.unitDescription(sizes: food.info.sizes)
        )
    }
}
