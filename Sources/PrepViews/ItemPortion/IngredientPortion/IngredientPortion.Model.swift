import SwiftUI
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics

extension IngredientPortion {
    
    class Model: ObservableObject {
        
        @Published var ingredientItem: IngredientItem
        
        let userUnits: UserOptions.Units
        let biometrics: Biometrics?
        let lastUsedGoalSet: GoalSet?
        
        init(
            ingredientItem: IngredientItem,
            lastUsedGoalSet: GoalSet?,
            userUnits: UserOptions.Units,
            biometrics: Biometrics?
        ) {
            self.lastUsedGoalSet = lastUsedGoalSet
            self.ingredientItem = ingredientItem
            self.userUnits = userUnits
            self.biometrics = biometrics
        }
    }
}

extension IngredientPortion.Model {
    

    var dietNameWithEmoji: String? {
        guard let diet else { return nil }
        return "\(diet.emoji) \(diet.name)"
    }
    
    var diet: GoalSet? {
        lastUsedGoalSet
    }
    
    var hasDiet: Bool {
        diet != nil
    }
    
    var goalCalcParams: GoalCalcParams {
        GoalCalcParams(
            userUnits: userUnits,
            biometrics: biometrics,
            energyGoal: diet?.energyGoal)
//            energyGoal: day?.goalSet?.energyGoal)
    }
}


extension IngredientPortion.Model {
    var nutrients: FoodNutrients {
        ingredientItem.food.info.nutrients
    }
}
