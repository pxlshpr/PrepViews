import SwiftUI
import PrepDataTypes
import SwiftUIPager

let MeterSpacing = 5.0
let MeterHeight = 20.0

extension MealItemMeters {
    
    class ViewModel: ObservableObject {
        
        @Published var foodItem: MealFoodItem
        
        let meal: DayMeal
        let day: Day
        let userUnits: UserUnits
        let bodyProfile: BodyProfile?
        let shouldCreateSubgoals: Bool
        
        @Published var metersType: MetersType
        @Published var pagerHeight: CGFloat
        
        @Published var page: Page

        @Published var dietMeterViewModels: [NutrientMeter.ViewModel] = []
        
        init(
            foodItem: MealFoodItem,
            meal: DayMeal,
            day: Day,
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
            
            if let diet = day.goalSet {
//                self.metersType = .meal
//                //TODO: If we have a meal.goalSet, add any rows from there that aren't in the day.goalSet
//                self.page = Page.withIndex(2)
                self.metersType = .diet
                self.page = Page.withIndex(1)

            } else {
                self.metersType = .nutrients
                self.page = Page.first()
            }
            self.pagerHeight = 0
            
            let numberOfRows = self.numberOfRows(for: self.metersType)
            self.pagerHeight = calculateHeight(numberOfRows: numberOfRows)
            self.dietMeterViewModels = calculatedDietMeterViewModels
        }
    }
}

extension MealItemMeters.ViewModel {
    var diet: GoalSet? {
        day.goalSet
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
            energyGoal: day.goalSet?.energyGoal)
    }
    
    func numberOfRows(for metersType: MetersType) -> Int {
        switch metersType {
        case .nutrients:
            return foodItem.food.numberOfNonZeroNutrients
        case .diet:
            return day.numberOfGoals(with: goalCalcParams)
        case .meal:
            //TODO: Add MealType goals we may not have in Diet
            return day.numberOfGoals(with: goalCalcParams)
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

extension MealItemMeters.ViewModel {
    
    var nutrients: FoodNutrients {
        foodItem.food.info.nutrients
    }
    
    func plannedValue(for component: NutrientMeterComponent, type: MetersType) -> Double {
        switch type {
        case .nutrients, .diet:
            return day.plannedValue(for: component, ignoring: meal.id) + meal.plannedValue(for: component)
        case .meal:
            return meal.plannedValue(for: component)
        }
    }
    
    //MARK: Nutrient MeterViewModels
    var nutrientMeterViewModels: [NutrientMeter.ViewModel] {
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
        guard let diet = day.goalSet else { return [] }
        
        var viewModels = diet.goals.map {
            nutrientMeterViewModel(for: $0, metersType: .diet)
        }
        if let implicitGoal = diet.implicitGoal(with: goalCalcParams) {
            let viewModel = nutrientMeterViewModel(for: implicitGoal, metersType: .diet)
            viewModel.isGenerated = true
            viewModels.append(viewModel)
        }
        
        /// Sort them in case we appended an implicit goal
        viewModels.sort(by: {$0.component.sortPosition < $1.component.sortPosition })
        
        return viewModels
    }
    
    //MARK: Meal MeterViewModels
    var mealMeterViewModels: [NutrientMeter.ViewModel] {

        let mealType = meal.goalSet
        
        var viewModels: [NutrientMeter.ViewModel] = []
        
        /// First get any explicit goals we have for the `mealType`
        
        
        var subgoals: [NutrientMeter.ViewModel] = dietMeterViewModels.compactMap { dietMeterViewModel in
            
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
//        var viewModels = diet.goals.map {
//            nutrientMeterViewModel(for: $0)
//        }
//        if let implicitGoal = diet.implicitGoal(with: goalCalcParams) {
//            var viewModel = nutrientMeterViewModel(for: implicitGoal)
//            viewModel.isGenerated = true
//            viewModels.append(viewModel)
//        }
        
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
}


