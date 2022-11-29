import SwiftUI
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics

let MeterSpacing = 5.0
let MeterHeight = 20.0

extension MealItemMeters {
    
    class ViewModel: ObservableObject {
        
        @Published var foodItem: MealFoodItem {
            didSet {
                foodItemChanged()
            }
        }
        
        @Published var meal: DayMeal {
            didSet {
                mealChanged()
            }
        }
        
        @Published var day: Day? {
            didSet {
                dayChanged()
            }
        }
        
        let userUnits: UserUnits
        let bodyProfile: BodyProfile?
        let shouldCreateSubgoals: Bool
        
        @Published var metersType: MetersType
        @Published var pagerHeight: CGFloat
        
        @Published var page: Page

        @Published var nutrientMeterViewModels: [NutrientMeter.ViewModel] = []
        @Published var dietMeterViewModels: [NutrientMeter.ViewModel] = []
        @Published var mealMeterViewModels: [NutrientMeter.ViewModel] = []

        init(
            foodItem: MealFoodItem,
            meal: DayMeal,
            day: Day?,
            userUnits: UserUnits,
            bodyProfile: BodyProfile?,
            shouldCreateSubgoals: Bool
        ) {
            self.foodItem = foodItem
            self.day = day
            self.meal = meal
            self.userUnits = userUnits
            self.bodyProfile = bodyProfile
            self.shouldCreateSubgoals = shouldCreateSubgoals
            
//            if day?.goalSet != nil {
////                self.metersType = .meal
////                //TODO: If we have a meal.goalSet, add any rows from there that aren't in the day.goalSet
////                self.page = Page.withIndex(2)
//                self.metersType = .diet
//                self.page = Page.withIndex(1)
//
//            } else {
                self.metersType = .nutrients
                self.page = Page.first()
//            }
            self.pagerHeight = 0
            
            let numberOfRows = self.numberOfRows(for: self.metersType)
            self.pagerHeight = calculateHeight(numberOfRows: numberOfRows)
            
            self.nutrientMeterViewModels = calculatedNutrientMeterViewModels
            self.dietMeterViewModels = calculatedDietMeterViewModels
            self.mealMeterViewModels = calculatedMealMeterViewModels
        }
    }
}


extension MealItemMeters.ViewModel {
    
    func recalculateHeight() {
        let numberOfRows = numberOfRows(for: metersType)
        pagerHeight = calculateHeight(numberOfRows: numberOfRows)
    }
    
    func mealChanged() {
        foodItemChanged()
    }
    
    func dayChanged() {
        foodItemChanged()
    }
    
    func foodItemChanged() {
        self.nutrientMeterViewModels = calculatedNutrientMeterViewModels
        let dietMeterViewModels = calculatedDietMeterViewModels
        let mealMeterViewModels = calculatedMealMeterViewModels
        
        var hasNewCompletion = false
        var hasNewExcess = false
        switch metersType {
        case .diet:
            for viewModel in dietMeterViewModels {
                if viewModel.percentageType == .complete {
                    /// Check if it was complete before
                    if let previous = self.dietMeterViewModels.first(where: { $0.component == viewModel.component }),
                       previous.percentageType != .complete
                    {
                        hasNewCompletion = true
                    }
                }
                if viewModel.percentageType == .excess {
                    /// Check if it was excess before
                    if let previous = self.dietMeterViewModels.first(where: { $0.component == viewModel.component }),
                       previous.percentageType != .excess
                    {
                        hasNewExcess = true
                    }
                }
            }
        case .meal:
            for viewModel in mealMeterViewModels {
                if viewModel.percentageType == .complete {
                    /// Check if it was complete before
                    if let previous = self.mealMeterViewModels.first(where: { $0.component == viewModel.component }),
                       previous.percentageType != .complete
                    {
                        hasNewCompletion = true
                    }
                }
                if viewModel.percentageType == .excess {
                    /// Check if it was excess before
                    if let previous = self.mealMeterViewModels.first(where: { $0.component == viewModel.component }),
                       previous.percentageType != .excess
                    {
                        hasNewExcess = true
                    }
                }
            }
        default:
            break
        }
        
        if hasNewExcess {
            Haptics.errorFeedback()
        } else if hasNewCompletion {
            Haptics.successFeedback()
        }
//        else {
//            Haptics.selectionFeedback()
//        }
        
        self.dietMeterViewModels = dietMeterViewModels
        self.mealMeterViewModels = mealMeterViewModels
        
    }
    
    var diet: GoalSet? {
        day?.goalSet
    }
    
    var hasDiet: Bool {
        diet != nil
    }
    
    var metersTypeBinding: Binding<MetersType> {
        Binding<MetersType>(
            get: { self.metersType },
            set: { newType in
                withAnimation {
                    self.metersType = newType
                    self.page.update(.new(index: newType.rawValue - 1))
                    self.pagerHeight = self.calculateHeight(numberOfRows: self.numberOfRows(for: newType))
                }
            }
        )
    }
    
    var goalCalcParams: GoalCalcParams {
        GoalCalcParams(
            userUnits: userUnits,
            bodyProfile: bodyProfile,
            energyGoal: day?.goalSet?.energyGoal)
    }
    
    func numberOfRows(for metersType: MetersType) -> Int {
        switch metersType {
        case .nutrients:
            return foodItem.food.numberOfNonZeroNutrients
        case .diet:
//            return day?.numberOfGoals(with: goalCalcParams) ?? 0
            return calculatedDietMeterViewModels.count
        case .meal:
            return calculatedMealMeterViewModels.count
        }
    }
    
    func pageWillTransition(_ result: Result<PageTransition, PageTransitionError>) {
        switch result {
        case .success(let transition):
            withAnimation {
                self.metersType = MetersType(rawValue: transition.nextPage + 1) ?? .nutrients
                self.pagerHeight = calculateHeight(numberOfRows: self.numberOfRows(for: self.metersType))
            }
        case .failure:
            break
        }
    }

    func calculateHeight(numberOfRows: Int) -> CGFloat {
        let rows = CGFloat(integerLiteral: numberOfRows)
        let meters = rows * MeterHeight
        let spacing = (rows - 1.0) * MeterSpacing
        let padding = (15.0 * 2.0)
        let extraPadding = 0.0 // (10.0 * 2.0)
        return meters + spacing + padding + extraPadding
    }
}

extension Food {
    func percentOfMicroComparedToHighest(_ nutrientType: NutrientType) -> Double? {
        guard let highestMicroValueInGrams,
              highestMicroValueInGrams > 0,
              let nutrient = info.nutrients.micros.first(where: { $0.nutrientType == nutrientType })
        else { return nil }
        return nutrient.valueInGrams / highestMicroValueInGrams
    }

    func percentOfMicroComparedToRDA(_ nutrientType: NutrientType) -> Double? {
        guard let nutrient = info.nutrients.micros.first(where: { $0.nutrientType == nutrientType }),
              let dailyValueInGrams = nutrientType.dailyValueInGrams,
              dailyValueInGrams > 0
        else { return nil }
        
        return nutrient.valueInGrams / dailyValueInGrams
    }

    var highestMicroValueInGrams: Double? {
        info.nutrients.micros.sorted {
            $0.valueInGrams > $1.valueInGrams
        }.first?.valueInGrams
    }
}

extension NutrientType {
    var dailyValueInGrams: Double? {
        guard let dailyValue else { return nil }
        
        let value = dailyValue.0
        let unit = dailyValue.1
        
        if unit.isMicrograms {
            return value / 1000000
        } else if unit.isMilligrams {
            return value / 1000
        } else if unit == .g {
            return value
        } else {
            return nil
        }
    }
}

extension FoodNutrient {
    var valueInGrams: Double {
        switch nutrientUnit {
        case .g:
            return value
        case .mg, .mgAT, .mgNE, .mgGAE:
            return value / 1000.0
        case .mcg, .mcgDFE, .mcgRAE:
            return value / 1000000.0
        default:
            return 0
        }
    }
}
extension MealItemMeters.ViewModel {
    
    var nutrients: FoodNutrients {
        foodItem.food.info.nutrients
    }
    
    func plannedValue(for component: NutrientMeterComponent, type: MetersType) -> Double {
        switch type {
        case .nutrients, .diet:
            guard let day else { return 0 }
//            if let meal {
                return day.plannedValue(for: component, ignoring: meal.id) + meal.plannedValue(for: component)
//            } else {
//                return day.plannedValue(for: component, ignoring: UUID())
//            }
        case .meal:
//            return meal?.plannedValue(for: component) ?? 0
            return meal.plannedValue(for: component)
        }
    }
    
    //MARK: Nutrient MeterViewModels
    var calculatedNutrientMeterViewModels: [NutrientMeter.ViewModel] {
//        if let meals = day?.meals, !meals.isEmpty {
//            return calculatedNutrientViewModelsRelativeToDay
//        } else {
            return calculatedNutrientViewModelsRelativeToRDA
//        }
    }
    
    var calculatedNutrientViewModelsRelativeToRDA: [NutrientMeter.ViewModel] {
        func s(_ component: NutrientMeterComponent) -> Double {
            foodItem.scaledValue(for: component)
        }
        
//        func p(_ component: NutrientMeterComponent) -> Double {
//            let scaledValue = s(component)
//            let scaledEnergy = foodItem.scaledValue(for: .energy)
//            switch component {
//            case .energy:
//                return scaledValue / 2000
//            case .carb:
//                return (scaledValue * KcalsPerGramOfCarb) / scaledEnergy
//            case .fat:
//                return  (scaledValue * KcalsPerGramOfFat) / scaledEnergy
//            case .protein:
//                return  (scaledValue * KcalsPerGramOfProtein) / scaledEnergy
//            case .micro(let nutrientType, _):
////                return foodItem.food.percentOfMicroComparedToHighest(nutrientType) ?? 0
//                return foodItem.food.percentOfMicroComparedToRDA(nutrientType) ?? 0
//            }
//        }
        
        func p(_ component: NutrientMeterComponent) -> Double {
            plannedValue(for: component, type: .nutrients)
        }

        func vm(_ component: NutrientMeterComponent) -> NutrientMeter.ViewModel {
            NutrientMeter.ViewModel(
                component: component,
                goalLower: component.defaultLowerGoal,
                goalUpper: component.defaultUpperGoal,
                planned: p(component),
                increment: s(component)
//                eaten: s(component)
            )
        }

        var viewModels: [NutrientMeter.ViewModel] = []
        viewModels.append(vm(.energy))

        viewModels.append(vm(.carb))
        viewModels.append(vm(.fat))
        viewModels.append(vm(.protein))

        for micro in nutrients.micros {
            guard let nutrientType = micro.nutrientType, micro.value > 0 else { continue }
            //TODO: Handle unit conversions and displaying the correct one here
            let component: NutrientMeterComponent = .micro(
                nutrientType: nutrientType,
                nutrientUnit: micro.nutrientUnit
            )
            
            viewModels.append(vm(component))
        }
        return viewModels
    }
    
    var calculatedNutrientViewModelsRelativeToDay: [NutrientMeter.ViewModel] {
        func p(_ component: NutrientMeterComponent) -> Double {
            plannedValue(for: component, type: .nutrients)
        }

        func i(_ component: NutrientMeterComponent) -> Double {
            foodItem.scaledValue(for: component)
        }
        
        var viewModels: [NutrientMeter.ViewModel] = []
        viewModels.append(NutrientMeter.ViewModel(component: .energy, planned: p(.energy), increment: i(.energy)))

        viewModels.append(NutrientMeter.ViewModel(component: .carb, planned: p(.carb), increment: i(.carb)))
        viewModels.append(NutrientMeter.ViewModel(component: .fat, planned: p(.fat), increment: i(.fat)))
        viewModels.append(NutrientMeter.ViewModel(component: .protein, planned: p(.protein), increment: i(.protein)))

        for micro in nutrients.micros {
            guard let nutrientType = micro.nutrientType, micro.value > 0 else { continue }
            //TODO: Handle unit conversions and displaying the correct one here
            let component: NutrientMeterComponent = .micro(
                nutrientType: nutrientType,
                nutrientUnit: micro.nutrientUnit
            )
            viewModels.append(NutrientMeter.ViewModel(
                component: component,
                planned: p(component),
                increment: i(component)
            ))
        }
        return viewModels
    }
    
    func nutrientMeterViewModel(for goal: Goal, metersType: MetersType) -> NutrientMeter.ViewModel {
        let component = goal.nutrientMeterComponent
        return NutrientMeter.ViewModel(
            component: component,
            goalLower: goal.calculateLowerBound(with: goalCalcParams),
            goalUpper: goal.calculateUpperBound(with: goalCalcParams),
            burned: 0,
            planned: plannedValue(for: component, type: metersType),
            increment: foodItem.scaledValue(for: component)
        )
    }
    
    //MARK: Diet MeterViewModels
    var calculatedDietMeterViewModels: [NutrientMeter.ViewModel] {
        guard let diet = day?.goalSet else { return [] }
        
        var viewModels = diet.goals.map {
            nutrientMeterViewModel(for: $0, metersType: .diet)
        }
        if let implicitGoal = diet.implicitGoal(with: goalCalcParams) {
            var viewModel = nutrientMeterViewModel(for: implicitGoal, metersType: .diet)
            viewModel.isGenerated = true
            viewModels.append(viewModel)
        }
        
        /// Sort them in case we appended an implicit goal
        viewModels.sort(by: {$0.component.sortPosition < $1.component.sortPosition })
        
        return viewModels
    }
    
    //MARK: Meal MeterViewModels
    var calculatedMealMeterViewModels: [NutrientMeter.ViewModel] {

//        guard let meal, let day else { return [] }
        guard let day else { return [] }

        var viewModels: [NutrientMeter.ViewModel] = []
        
        /// First get any explicit goals we have for the `mealType`
        if let mealType = meal.goalSet {
            viewModels.append(contentsOf: mealType.goals.map {
                nutrientMeterViewModel(for: $0, metersType: .meal)
            })
        }
        
        let subgoals: [NutrientMeter.ViewModel] = calculatedDietMeterViewModels.compactMap { dietMeterViewModel in
//        let subgoals: [NutrientMeter.ViewModel] = dietMeterViewModels.compactMap { dietMeterViewModel in
            
            let component = dietMeterViewModel.component
            /// Make sure we don't already have a ViewModel for this
            guard !viewModels.contains(where: { $0.component == component }) else {
                return nil
            }

            let remainingMeals = day.mealsNotPlannedAndWithoutType
            var numberOfRemainingMeals = remainingMeals.count
            /// If we don't have this current meal included in the list (if we've already added foods to it perhaps), make sure we're including it to divide amongst
            if !remainingMeals.contains(where: { $0.id == meal.id }) {
                numberOfRemainingMeals += 1
            }

            /// Guard against division by zero error
//            guard numberOfRemainingMeals > 0 else { return nil }
            
            let subgoalLower: Double?
            if let lower = dietMeterViewModel.goalLower {
                let existingAmount = day.existingAmount(for: component, lowerBound: true, params: goalCalcParams)
                let remainingAmount = max(lower - existingAmount, 0)
                subgoalLower = remainingAmount / Double(numberOfRemainingMeals)
            } else {
                subgoalLower = nil
            }
            
            let subgoalUpper: Double?
            if let upper = dietMeterViewModel.goalUpper {
                let existingAmount = day.existingAmount(for: component, lowerBound: false, params: goalCalcParams)
                let remainingAmount = max(upper - existingAmount, 0)
                subgoalUpper = remainingAmount / Double(numberOfRemainingMeals)
            } else {
                subgoalUpper = nil
            }

            return NutrientMeter.ViewModel(
                component: component,
                isGenerated: true,
                goalLower: subgoalLower,
                goalUpper: subgoalUpper,
                burned: 0,
                planned: meal.plannedValue(for: component),
                increment: foodItem.scaledValue(for: component)
            )
            /// Now if we have any `dietMeterViewModels` go through all of them, and add subgoals for any that we don't have an explicit goal for
            /// Do this by:
            ///     Take each bound
            ///         let numberOfMealsToSpreadOver = how many meals we have that both, hasn't been planned *and* hasn't got any mealtypes associated with it
            ///         let existingAmount = add for each unplanned-meal, either its total planned value, or the value (for the respective bound) indicated in the mealtype
            ///         let amountToSpread = bound - existingAmount
            ///         let subgoal bound = amountToSpread / numberOfMealsToSpreadOver
        }
        
        viewModels.append(contentsOf: subgoals)
        
        viewModels.sort(by: {$0.component.sortPosition < $1.component.sortPosition })
        
        return viewModels
    }
    
    func meterViewModels(for type: MetersType) -> [NutrientMeter.ViewModel] {
        switch type {
        case .nutrients:
            return nutrientMeterViewModels
        case .diet:
            return dietMeterViewModels
        case .meal:
            return mealMeterViewModels
        }
    }
    
    var shouldShowMealGoals: Bool {
        /// If we have a `MealType` associated
//        if meal?.goalSet != nil {
        if meal.goalSet != nil {
            return true
        }
        
        /// Or have more than 1 meal
        guard let day else { return false }
        return day.meals.count > 1
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
                metersSection
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
            bodyProfile: BodyProfileMock.calculated,
            meals: mockMeals,
            syncStatus: .notSynced,
            updatedAt: 0
        )
    }
    
    var metersSection: some View {
        MealItemMeters(
            foodItem: foodItemBinding,
//            meal: DayMeal(from: MealMock.preWorkoutWithItems),
            meal: mealBinding,
//            meal: .constant(nil),
            day: .constant(mockDay),
//            day: nil,
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
//                    goalSet: MealTypeMock.preWorkout
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
                    amount: FoodValue(value: value ?? 0, unitType: .weight, weightUnit: weightUnit)
                )
            },
            set: { _ in }
        )
    }
    
    @State var weightUnit: WeightUnit = .g
    @State var value: Double? = 30.4
    @State var valueString: String = "30.4"

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

struct MealItemNutrientMeters_Previews: PreviewProvider {
    static var previews: some View {
        MealItemNutrientMetersPreview()
    }
}

extension NutrientMeterComponent {
    var defaultLowerGoal: Double? {
        switch self {
        case .energy:
            return 2500
        case .carb:
            return 325
        case .fat:
            return 100
        case .protein:
            return 250
        case .micro(let nutrientType, _):
            return nutrientType.dailyValue?.0
        }
    }

    var defaultUpperGoal: Double? {
        switch self {
        case .energy:
            return 2500
        case .carb:
            return 325
        case .fat:
            return 100
        case .protein:
            return 250
        case .micro(let nutrientType, _):
            return nutrientType.dailyValueMax?.0
        }
    }
}
