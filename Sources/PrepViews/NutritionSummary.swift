import SwiftUI
import PrepDataTypes

public struct NutritionSummary<Provider: NutritionSummaryProvider>: View {

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ObservedObject var dataProvider: Provider
    @Binding var showDetails: Bool
    
    /// For Plate and Recipe types
    @State var parentMultiplier: Double

    public init(dataProvider: Provider, showDetails: Binding<Bool>? = nil, parentMultiplier: Double = 1) {
        self.dataProvider = dataProvider
        self._showDetails = showDetails ?? .constant(true)
        self._parentMultiplier = State(initialValue: parentMultiplier)
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            nutrientsEnergy
            if showDetails {
                nutrientsMacros
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .move(edge: .trailing))
                                    .combined(with: .opacity)
                                    .combined(with: .scale)
                    )
//                    .transition(.asymmetric(insertion: .move(edge: .bottom),
//                                            removal: .move(edge: .top))
//                                    .combined(with: .opacity))
//                    .transition(.scale.combined(with: .opacity))

            }
        }
    }
    
    var shouldHighlight: Bool {
        dataProvider.forMeal && !dataProvider.isMarkedAsCompleted
    }
    
    var nutrientsEnergy: some View {
        HStack(alignment: .top, spacing: 1) {
            if !(!dataProvider.showQuantityAsSummaryDetail && showDetails)
                || !dataProvider.showQuantityAsSummaryDetail {
                Text("\(Int(dataProvider.energyAmount * parentMultiplier))")
                    .font(.subheadline)
                    .foregroundColor(shouldHighlight ?
                                     Color(.white) : Color(.secondaryLabel))
            }
//            if showDetails {
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(shouldHighlight ? Color(hex: "C4C4C6") : Color(.tertiaryLabel))
//                    .transition(.asymmetric(insertion: .move(edge: .trailing),
//                                            removal: .move(edge: .trailing))
//                                    .combined(with: .opacity))
//            }
        }
    }
    
    var nutrientsMacros: some View {
        let carb = dataProvider.carbAmount * parentMultiplier
        let fat = dataProvider.fatAmount * parentMultiplier
        let protein = dataProvider.proteinAmount * parentMultiplier
        let carbCalories = carb * 4.0
        let fatCalories = fat * 9.0
        let proteinCalories = protein * 4.0
        let carbHighlighted = carbCalories > fatCalories && carbCalories > proteinCalories
        let fatHighlighted = fatCalories > carbCalories && fatCalories > proteinCalories
        let proteinHighlighted = proteinCalories > fatCalories && proteinCalories > carbCalories
        return HStack(spacing: 4) {
            macroLabel(carb, macro: .carb, highlighted: carbHighlighted)
            macroLabel(fat, macro: .fat, highlighted: fatHighlighted)
            macroLabel(protein, macro: .protein, highlighted: proteinHighlighted)
        }
    }
    
    func macroLabel(_ amount: Double, macro: Macro, highlighted: Bool = false) -> some View {
        let string = amount.formattedNutritionViewMacro
        let valueColor: Color
        let backgroundColor: Color
        let unitLabelColor: Color
        
        if amount >= 1 {
            if highlighted {
                valueColor = Colors.Nutrient.Highlighted.Value.colorScheme(colorScheme)
                let macroBackgroundColor: Color
                switch macro {
                case .carb:
                    macroBackgroundColor = Colors.Nutrient.Highlighted.Background.Carb.colorScheme(colorScheme)
                case .fat:
                    macroBackgroundColor = Colors.Nutrient.Highlighted.Background.Fat.colorScheme(colorScheme)
                case .protein:
                    macroBackgroundColor = Colors.Nutrient.Highlighted.Background.Protein.colorScheme(colorScheme)
                }
                backgroundColor = macroBackgroundColor
                unitLabelColor = Colors.Nutrient.Highlighted.Unit.colorScheme(colorScheme)
//                valueColor = forMeal ? Color.white : Color(.label)
//                backgroundColor = forMeal ? macro.nutrientMealBackgroundColor : macro.labelColor
//                unitLabelColor = forMeal ? macro.nutrientMealUnitColor : Color(.secondaryLabel)
            } else {
                valueColor = shouldHighlight
                ? Colors.Nutrient.Regular.Value.colorScheme(colorScheme)
                : Colors.Nutrient.Muted.Regular.Value.colorScheme(colorScheme)

                backgroundColor = shouldHighlight
                ? Colors.Nutrient.Regular.Background.colorScheme(colorScheme)
                : Colors.Nutrient.Muted.Regular.Background.colorScheme(colorScheme)

                unitLabelColor = shouldHighlight
                ? Colors.Nutrient.Regular.Unit.colorScheme(colorScheme)
                : Colors.Nutrient.Muted.Regular.Unit.colorScheme(colorScheme)
            }
        } else {
            valueColor = shouldHighlight
            ? Colors.Nutrient.Zero.Value.colorScheme(colorScheme)
            : Colors.Nutrient.Muted.Zero.Value.colorScheme(colorScheme)

            backgroundColor = shouldHighlight
            ? Colors.Nutrient.Zero.Background.colorScheme(colorScheme)
            : Colors.Nutrient.Muted.Zero.Background.colorScheme(colorScheme)

            unitLabelColor = shouldHighlight
            ? Colors.Nutrient.Zero.Unit.colorScheme(colorScheme)
            : Colors.Nutrient.Muted.Zero.Unit.colorScheme(colorScheme)
        }
        
        return HStack(alignment: .bottom, spacing: 1) {
            if amount == -1 || (amount > 0 && amount < 1) {
                Text("<")
                    .font(.caption2)
                    .foregroundColor(Color(.quaternaryLabel))
            }
            Text(string)
                .font(.subheadline)
                .foregroundColor(valueColor)
            Text(macro.initial)
                .font(.caption)
                .foregroundColor(unitLabelColor)
        }
        .padding(5)
        .background(backgroundColor)
        .cornerRadius(5)
    }
}

struct Colors {
    struct Nutrient {
        struct Highlighted {
            struct Value {
                static let light = Color(.label)
                static let dark = Color(.label)
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Background {
                struct Carb {
                    static let light = Color(hex: "FFE798")
                    static let dark = Color(hex: "987A20")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Fat {
                    static let light = Color(hex: "EAB0FF")
                    static let dark = Color(hex: "740773")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Protein {
                    static let light = Color(hex: "BAE2E3")
                    static let dark = Color(hex: "3D969A")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
            }
            struct Unit {
                static let light = Color(.secondaryLabel)
                static let dark = Color(.secondaryLabel)
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
        }

        struct Regular {
            struct Value {
                static let light = Color(hex: "DFD6FF")
                static let dark = Color(hex: "DFD6FF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Background {
                static let light = Color(hex: "9678FF")
                static let dark = Color(hex: "A78EFF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Unit {
                static let light = Color(hex: "C9BAFF")
                static let dark = Color(hex: "C9BAFF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
        }
        struct Zero {
            struct Value {
                static let light = Color(hex: "DFD6FF")
                static let dark = Color(hex: "DFD6FF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Background {
                static let light = Color(hex: "8562FF")
                static let dark = Color(hex: "9678FF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
            struct Unit {
                static let light = Color(hex: "C9BAFF")
                static let dark = Color(hex: "C9BAFF")
                static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                    colorScheme == .light ? light : dark
                }
            }
        }
        
        struct Muted {
            struct Regular {
                struct Value {
                    static let light = Color(.secondaryLabel)
                    static let dark = Color(.secondaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Background {
                    static let light = Color(hex: "E9E9EB")
                    static let dark = Color(hex: "39393D")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Unit {
                    static let light = Color(.tertiaryLabel)
                    static let dark = Color(.tertiaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
            }
            struct Zero {
                struct Value {
                    static let light = Color(.tertiaryLabel)
                    static let dark = Color(.tertiaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Background {
                    static let light = Color(hex: "EEEEF0")
                    static let dark = Color(hex: "313135")
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
                struct Unit {
                    static let light = Color(.quaternaryLabel)
                    static let dark = Color(.quaternaryLabel)
                    static func colorScheme(_ colorScheme: ColorScheme) -> Color {
                        colorScheme == .light ? light : dark
                    }
                }
            }
        }
    }
}
