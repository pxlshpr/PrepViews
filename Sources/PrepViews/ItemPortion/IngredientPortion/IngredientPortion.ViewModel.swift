import SwiftUI
import PrepDataTypes
import SwiftUIPager
import SwiftHaptics

extension IngredientPortion {
    
    class ViewModel: ObservableObject {
        
        @Published var ingredientItem: IngredientItem
        
        let userOptions: UserOptions
        let bodyProfile: BodyProfile?
        let lastUsedGoalSet: GoalSet?
        
        init(
            ingredientItem: IngredientItem,
            lastUsedGoalSet: GoalSet?,
            userOptions: UserOptions,
            bodyProfile: BodyProfile?
        ) {
            self.lastUsedGoalSet = lastUsedGoalSet
            self.ingredientItem = ingredientItem
            self.userOptions = userOptions
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
            userOptions: userOptions,
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
