import SwiftUI
import PrepDataTypes

extension FoodCell {
    init(food: Food, isComparing: Binding<Bool>, didToggleSelection: @escaping (Bool) -> ()) {
        self.init(
            emoji: food.emoji,
            name: food.name,
            detail: food.detail,
            brand: food.brand,
            carb: food.info.nutrients.carb,
            fat: food.info.nutrients.fat,
            protein: food.info.nutrients.protein,
            isSelectable: isComparing,
            didToggleSelection: didToggleSelection
        )
    }
}
