import Foundation
import PrepDataTypes

extension Day {
    func numberOfGoals(with params: GoalCalcParams) -> Int {
        goalSet?.numberOfGoals(with: params) ?? 0
    }
    
    func plannedValue(for component: NutrientMeterComponent, ignoring mealID: UUID) -> Double {
        meals.reduce(0) { partialResult, dayMeal in
            partialResult + (dayMeal.id != mealID ? dayMeal.plannedValue(for: component) : 0)
        }
    }
    
    var mealsPlannedOrWithType: [DayMeal] {
        meals.filter { $0.isPlannedOrWithType }
    }
    
    var mealsNotPlannedAndWithoutType: [DayMeal] {
        meals.filter { !$0.isPlannedOrWithType }
    }
    
    
    func existingAmount(for component: NutrientMeterComponent, lowerBound: Bool, params: GoalCalcParams) -> Double {
        meals.reduce(0) { partialResult, meal in
            let value = meal.plannedOrTypeValue(for: component, lowerBound: lowerBound, params: params) ?? 0
            return partialResult + value
        }
    }
}


extension DayMeal {
    func plannedValue(for component: NutrientMeterComponent) -> Double {
        foodItems.reduce(0) { partialResult, mealFoodItem in
            partialResult + mealFoodItem.scaledValue(for: component)
        }
    }
    
    func plannedOrTypeValue(for component: NutrientMeterComponent, lowerBound: Bool, params: GoalCalcParams) -> Double? {
        if !foodItems.isEmpty {
            return plannedValue(for: component)
        } else {
            guard let goalSet else { return nil }
            return goalSet.value(for: component, lowerBound: lowerBound, params: params)
        }
    }
    
    var isPlannedOrWithType: Bool {
        !foodItems.isEmpty || goalSet != nil
    }
}

extension GoalSet {
    
    func value(for component: NutrientMeterComponent, lowerBound: Bool, params: GoalCalcParams) -> Double? {
        guard let goal = goals.first(where: { $0.nutrientMeterComponent == component }) else { return nil }
        if lowerBound {
            return goal.calculateLowerBound(with: params)
        } else {
            return goal.calculateUpperBound(with: params)
        }
    }
    
    func numberOfGoals(with params: GoalCalcParams) -> Int {
        if implicitGoal(with: params) != nil {
            return goals.count + 1
        } else {
            return goals.count
        }
    }
    
    func implicitGoal(with params: GoalCalcParams) -> Goal? {
        return implicitCarbGoal(with: params)
        ?? implicitEnergyGoal(with: params)
        ?? implicitFatGoal(with: params)
        ?? implicitProteinGoal(with: params)
    }
}

extension Goal {
    var nutrientMeterComponent: NutrientMeterComponent {
        switch type {
        case .energy:
            return .energy
        case .macro(_, let macro):
            switch macro {
            case .carb:
                return .carb
            case .fat:
                return .fat
            case .protein:
                return .protein
            }
        case .micro(_, let nutrientType, let nutrientUnit):
            return .micro(nutrientType: nutrientType, nutrientUnit: nutrientUnit)
        }
    }
}

public extension Food {
    var numberOfMicros: Int {
        info.nutrients.micros.count
    }
    
    var nonZeroMicros: [FoodNutrient] {
        info.nutrients.micros.filter { $0.value > 0 }
    }

    
    var baseNumberOfNutrients: Int {
        /// Energy + 3 Macros that are always present
        return 4
    }
    var numberOfNutrients: Int {
        return baseNumberOfNutrients + numberOfMicros
    }
    
    var numberOfNonZeroNutrients: Int {
        return baseNumberOfNutrients + nonZeroMicros.count
    }
    
    func quantity(for amount: FoodValue) -> FoodQuantity? {
        guard let unit = FoodQuantity.Unit(foodValue: amount, in: self) else { return nil }
        return FoodQuantity(value: amount.value, unit: unit, food: self)
    }
}

extension NutrientMeterComponent {
    var sortPosition: Int {
        switch self {
        case .energy:
            return 1
        case .carb:
            return 2
        case .fat:
            return 3
        case .protein:
            return 4
        case .micro(let nutrientType, _):
            return 5 + Int(nutrientType.rawValue)
        }
    }
}

public extension MealFoodItem {
    
    var nutrientScaleFactor: Double {
        guard let foodQuantity = food.quantity(for: amount) else { return 0 }
        return food.nutrientScaleFactor(for: foodQuantity) ?? 0
    }
    
    func scaledValue(for component: NutrientMeterComponent) -> Double {
        guard let value = food.info.nutrients.value(for: component) else { return 0 }
        return value * nutrientScaleFactor
    }
}

public extension FoodNutrients {
    func value(for component: NutrientMeterComponent) -> Double? {
        //TODO: Complete this by doing the following
        /// [x] Account for `FoodValue` and multiply the values accordingly
        /// [x] Modify micro to include actual `NutrientType` and not just the `String` of the description
        switch component {
        case .energy:
            return energyInKcal
        case .carb:
            return carb
        case .fat:
            return fat
        case .protein:
            return protein
        case .micro(let nutrientType, _):
            //TODO: Consider nutrientUnit mistmatches here as we may have a different unit in the goal than was the food is described in. Do this for energy kcal/kj too.
            return micros.first(where: { $0.nutrientType == nutrientType })?.value
        }
    }
}
