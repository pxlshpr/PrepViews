import SwiftUI
import PrepDataTypes

public extension FoodCell {
    init(
        food: Food,
        isSelectable: Binding<Bool>,
        didTapMacrosIndicator: (() -> ())? = nil,
        didToggleSelection: @escaping (Bool) -> ()
    ) {
        self.init(
            emoji: food.emoji,
            name: food.name,
            detail: food.detail,
            brand: food.brand,
            carb: food.info.nutrients.carb,
            fat: food.info.nutrients.fat,
            protein: food.info.nutrients.protein,
            isSelectable: isSelectable,
            didTapMacrosIndicator: didTapMacrosIndicator,
            didToggleSelection: didToggleSelection
        )
    }
}
