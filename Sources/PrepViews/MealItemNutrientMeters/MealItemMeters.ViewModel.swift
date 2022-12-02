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

        @Published var metersTypes: [MetersType] = []
        
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
            
            let metersTypes = MetersType.types(for: day, meal: meal)
            self.metersTypes = metersTypes
            
            let initialMetersType = MetersType.initialType(for: day, meal: meal)
            self.metersType = initialMetersType
            switch initialMetersType {
            case .meal:
                self.page = Page.withIndex(0)
            case .diet:
                self.page = Page.withIndex(1)
            case .nutrients:
                self.page = Page.withIndex(2)
            }
            
            self.pagerHeight = 0
            
            let numberOfRows = self.numberOfRows(for: self.metersType)
            self.pagerHeight = calculateHeight(numberOfRows: numberOfRows)
            
            self.nutrientMeterViewModels = calculatedNutrientMeterViewModels
            self.dietMeterViewModels = calculatedDietMeterViewModels
            self.mealMeterViewModels = calculatedMealMeterViewModels
            
        }
    }
}

extension MetersType {
    static func initialType(for day: Day?, meal: DayMeal) -> MetersType {
        /// If we have no `Day`, start with `.meal` if we have a meal type, otherwise fall back to `.nutrients`
        guard let day else {
            return meal.goalSet != nil ? .meal : .nutrients
        }
        
        /// If we have a `Day`, and have a `meal.goalSet`, start with `.meal`
        guard meal.goalSet == nil else {
            return .meal
        }
        
        /// If we have no `day.goalSet`, return `.nutrients`
        guard day.goalSet != nil else {
            return .nutrients
        }
        
        /// If we have more than 1 meal (and will show subgoals), start with `.meal`, otherwise start with `.diet`
        return day.meals.count > 1 ? .meal : .diet
    }

    static func types(for day: Day?, meal: DayMeal) -> [MetersType] {
        
        var shouldShowMealGoals: Bool {
            if meal.goalSet != nil {
                return true
            }
            
            /// Or have more than 1 meal (and a diet, since there's no meal type)
            guard let day, day.goalSet != nil else { return false }
            return day.meals.count > 1
        }
        
        var types: [MetersType] = []
//        if shouldShowMealGoals {
            types.append(.meal)
//        }
//        if day != nil {
            types.append(.diet)
//        }
        types.append(.nutrients)
        return types
    }
}

extension MealItemMeters.ViewModel {
    
    var shouldShowMealGoals: Bool {
        /// If we have a `MealType` associated
//        if meal?.goalSet != nil {
        if meal.goalSet != nil {
            return true
        }
        
        /// Or have more than 1 meal (and a diet, since there's no meal type)
        guard let day, day.goalSet != nil else { return false }
        return day.meals.count > 1
    }

    func recalculateHeight() {
        let numberOfRows = numberOfRows(for: metersType)
        pagerHeight = calculateHeight(numberOfRows: numberOfRows)
    }
    
    func mealChanged() {
        refresh()
    }
    
    func dayChanged() {
        refresh()
    }
    
    func refresh() {
        foodItemChanged()
        metersTypes = MetersType.types(for: day, meal: meal)
        page = .withIndex(pageIndex(for: self.metersType))
    }
    
    func foodItemChanged() {
        createViewModels()
        recalculateHeight()
    }
    
    func createViewModels() {
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
    
    var hasMealType: Bool {
        meal.goalSet != nil
    }
    
    func pageIndex(for type: MetersType) -> Int {
        if metersTypes.count == 3 {
            return type.rawValue - 1
        } else if metersTypes.count == 2 {
            /// Shift the back 1 more to account for missing `meal` type
            return type.rawValue - 2
        } else {
            print("Not supported")
            return 1
        }
    }
    
    var metersTypeBinding: Binding<MetersType> {
        Binding<MetersType>(
            get: { self.metersType },
            set: { newType in
                withAnimation {
                    self.metersType = newType
                    
                    self.page.update(.new(index: self.pageIndex(for: newType)))
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
            guard hasDiet else { return 4 }
            return calculatedDietMeterViewModels.count
        case .meal:
            guard (shouldShowMealContent) else { return 4 }
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
        let planned: Double
        switch type {
        case .nutrients, .diet:
            guard let day else { return 0 }
            planned = day.plannedValue(for: component, ignoring: meal.id) + meal.plannedValue(for: component)
        case .meal:
            planned = meal.plannedValue(for: component)
        }
        
        if meal.foodItems.contains(where: { $0.id == foodItem.id }) {
            /// If this meal already contains the item (ie. we're editing it), remove its amount from the current total
//            return planned - foodItem.scaledValue(for: component)
            return planned - meal.plannedValue(for: component)
        } else {
            return planned
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
                planned: plannedValue(for: component, type: .meal),
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
    
    var currentMeterViewModels: [NutrientMeter.ViewModel] {
        meterViewModels(for: metersType)
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
    
    var emptyMealFooterString: String {
        if hasDiet {
            return "Your meal goals will appear once you select a meal type or add more meals."
        } else {
            return "Your meal goals will appear once you select a meal type or a diet for the day."
        }
    }
    
    var shouldShowMealContent: Bool {
        hasMealType
        || (hasDiet && dayHasMoreThanOneMeal)
    }
    
    var dayHasMoreThanOneMeal: Bool {
        guard let day else { return false }
        return day.meals.count > 1
    }
}

extension NutrientMeterComponent {
    var defaultLowerGoal: Double? {
        switch self {
        case .energy:
            return 2000
        case .carb:
            return 50
        case .fat:
            return 35
        case .protein:
            return 50
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
