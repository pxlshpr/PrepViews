import SwiftUI
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics

extension IngredientPortion {
    
    class ViewModel: ObservableObject {
        
        @Published var ingredientItem: IngredientItem
        
        let userUnits: UserOptions.Units
        let bodyProfile: BodyProfile?
        let lastUsedGoalSet: GoalSet?
        
        init(
            ingredientItem: IngredientItem,
            lastUsedGoalSet: GoalSet?,
            userUnits: UserOptions.Units,
            bodyProfile: BodyProfile?
        ) {
            self.lastUsedGoalSet = lastUsedGoalSet
            self.ingredientItem = ingredientItem
            self.userUnits = userUnits
            self.bodyProfile = bodyProfile
        }
    }
}

extension IngredientPortion.ViewModel {
    

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
            bodyProfile: bodyProfile,
            energyGoal: diet?.energyGoal)
//            energyGoal: day?.goalSet?.energyGoal)
    }
}


extension IngredientPortion.ViewModel {
    var nutrients: FoodNutrients {
        ingredientItem.food.info.nutrients
    }
}
