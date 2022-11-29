import Foundation
import PrepDataTypes

public protocol NutritionSummaryProvider: ObservableObject {
    var forMeal: Bool { get }
    var isMarkedAsCompleted: Bool { get }

    var energyAmount: Double { get }
    var carbAmount: Double { get }
    var fatAmount: Double { get }
    var proteinAmount: Double { get }

    var haveMicros: Bool { get }
    var haveCustomMicros: Bool { get }
    func nutrient(ofType type: NutrientType) -> Double?
//    func nutrient(ofCustomType type: CustomNutrientType) -> Double?
}

public extension NutritionSummaryProvider {
    var forMeal: Bool { false }
    var isMarkedAsCompleted: Bool { false }
    var haveMicros: Bool { false }
    var haveCustomMicros: Bool { false }
    func nutrient(ofType type: NutrientType) -> Double? { nil }
//    func nutrient(ofCustomType type: CustomNutrientType) -> Double? { nil }
}
