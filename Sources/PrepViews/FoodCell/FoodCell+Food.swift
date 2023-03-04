import SwiftUI
import PrepDataTypes

public extension FoodCell {
    init(
        food: Food,
        showEmoji: Binding<Bool>,
        isSelectable: Binding<Bool> = .constant(false),
        showMacrosIndicator: Bool = true,
        didTapMacrosIndicator: (() -> ())? = nil,
        didToggleSelection: ((Bool) -> ())? = nil
    ) {
        self.init(
            emoji: food.emoji,
            name: food.name,
            detail: food.detail,
            brand: food.brand,
            carb: food.info.nutrients.carb,
            fat: food.info.nutrients.fat,
            protein: food.info.nutrients.protein,
            showMacrosIndicator: showMacrosIndicator,
            showEmoji: showEmoji,
            isSelectable: isSelectable,
            didTapMacrosIndicator: didTapMacrosIndicator,
            didToggleSelection: didToggleSelection
        )
    }
}
