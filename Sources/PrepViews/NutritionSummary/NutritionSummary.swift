import SwiftUI
import PrepDataTypes

struct AnimatableMacroModifier: AnimatableModifier {
    
    var value: Double
    var color: Color
    
    let fontSize: CGFloat = 14
    let fontWeight: Font.Weight = .regular
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var uiFont: UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: fontWeight.uiFontWeight)
    }
    
    var size: CGSize {
        uiFont.fontSize(for: value.formattedNutrient)
    }
    
//    let unitFontSize: CGFloat = 10
//    let unitFontWeight: Font.Weight = .regular
//
//    var unitUIFont: UIFont {
//        UIFont.systemFont(ofSize: unitFontSize, weight: unitFontWeight.uiFontWeight)
//    }
//
//    var unitWidth: CGFloat {
//        unitUIFont.fontSize(for: unit.shortDescription).width
//    }
//
//    var textColor: Color {
//        shouldHighlight ? .white : .secondary
//    }
//
//    var unitcolor: Color {
//        shouldHighlight ? Color(hex: "C4C4C6") : Color(.tertiaryLabel)
//    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: 28, height: size.height)
            .overlay(
                Text(value.formattedNutritionViewMacro)
                    .font(.system(size: fontSize, weight: fontWeight, design: .default))
                    .foregroundColor(color)
            )
    }
}

extension View {
    func animatedMacro(value: Double, color: Color) -> some View {
        modifier(AnimatableMacroModifier(value: value, color: color))
    }
}

struct AnimatableEnergyModifier: AnimatableModifier {
    
    var value: Double
    var unit: EnergyUnit
    var shouldHighlight: Bool
    
    let fontSize: CGFloat = 14
    let fontWeight: Font.Weight = .regular
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var uiFont: UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: fontWeight.uiFontWeight)
    }
    
    var size: CGSize {
        uiFont.fontSize(for: value.formattedNutrient)
    }
    
    let unitFontSize: CGFloat = 10
    let unitFontWeight: Font.Weight = .regular
    
    var unitUIFont: UIFont {
        UIFont.systemFont(ofSize: unitFontSize, weight: unitFontWeight.uiFontWeight)
    }
    
    var unitWidth: CGFloat {
        unitUIFont.fontSize(for: unit.shortDescription).width
    }
    
    var textColor: Color {
        shouldHighlight ? .white : .secondary
    }
    
    var unitcolor: Color {
        shouldHighlight ? Color(hex: "C4C4C6") : Color(.tertiaryLabel)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width + 5 + 2 + unitWidth, height: size.height)
            .overlay(
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value.formattedNutrient)
                        .font(.system(size: fontSize, weight: fontWeight, design: .default))
                        .foregroundColor(textColor)
                    Text(unit.shortDescription)
                        .font(.system(size: unitFontSize, weight: unitFontWeight, design: .default))
                        .foregroundColor(unitcolor)
                        .offset(y: -1.5)
                }
            )
    }
}

extension View {
    func animatedEnergy(value: Double, unit: EnergyUnit, shouldHighlight: Bool) -> some View {
        modifier(AnimatableEnergyModifier(value: value, unit: unit, shouldHighlight: shouldHighlight))
    }
}


public struct NutritionSummary<Provider: NutritionSummaryProvider>: View {

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ObservedObject var dataProvider: Provider
    
    let showMacrosIndicator: Bool
    
    public init(
        dataProvider: Provider,
        showMacrosIndicator: Bool = false
    ) {
        self.dataProvider = dataProvider
        self.showMacrosIndicator = showMacrosIndicator
    }
    
    public var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack(spacing: 0) {
                if showMacrosIndicator {
                    macrosIndicator
                        .padding(.leading, 2)
//                        .background(.green)
                    Spacer()
                }
                nutrientsEnergy
//                    .background(.blue)
            }
            nutrientsMacros
                .transition(.asymmetric(insertion: .move(edge: .trailing),
                                        removal: .move(edge: .trailing))
                                .combined(with: .opacity)
                                .combined(with: .scale)
                )
        }
        .fixedSize(horizontal: true, vertical: false)
        .onChange(of: dataProvider.energyAmount, perform: energyChanged)
    }
    
    func energyChanged(to newValue: Double) {
        
    }
    
    var macrosIndicator: some View {
        MacrosIndicator(
            c: dataProvider.carbAmount,
            f: dataProvider.fatAmount,
            p: dataProvider.proteinAmount
        )
    }
    
    var shouldHighlight: Bool {
        dataProvider.forMeal && !dataProvider.isMarkedAsCompleted
    }
    
    var nutrientsEnergy_new: some View {
        Color.clear
            .animatedEnergy(value: dataProvider.energyAmount,
                            unit: .kcal,
                            shouldHighlight: shouldHighlight
            )
    }
    
    var nutrientsEnergy: some View {
        HStack(alignment: .top, spacing: 1) {
            Text("\(Int(dataProvider.energyAmount))")
                .font(.subheadline)
                .foregroundColor(shouldHighlight ?
                                 Color(.white) : Color(.secondaryLabel))
            Text("kcal")
                .font(.caption)
                .foregroundColor(shouldHighlight ? Color(hex: "C4C4C6") : Color(.tertiaryLabel))
        }
    }
    
    var nutrientsMacros: some View {
        let carb = dataProvider.carbAmount
        let fat = dataProvider.fatAmount
        let protein = dataProvider.proteinAmount
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
        
        var valueText_new: some View {
            Color.clear
                .animatedMacro(value: amount, color: valueColor)
        }

        var valueText: some View {
            Text(string)
                .font(.subheadline)
                .foregroundColor(valueColor)
        }

        return HStack(alignment: .bottom, spacing: 1) {
            if amount == -1 || (amount > 0 && amount < 1) {
                Text("<")
                    .font(.caption2)
                    .foregroundColor(Color(.quaternaryLabel))
            }
            valueText
            Text(macro.initial)
                .font(.caption)
                .foregroundColor(unitLabelColor)
        }
        .padding(5)
        .background(backgroundColor)
        .cornerRadius(5)
    }
}

import SwiftUISugar

struct NutritionSummaryPreview: View {
    @StateObject var viewModel = ViewModel()
    var body: some View {
        ZStack {
            FormStyledScrollView {
                FormStyledSection {
                    NutritionSummary(
                        dataProvider: viewModel,
                        showMacrosIndicator: true
                    )
                }
            }
            VStack {
                Spacer()
                bottomButtons
            }
        }
    }
    
    var bottomButtons: some View {
        HStack {
            Button {
                viewModel.decrement()
            } label: {
                Text("- 50")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.accentColor)
                    )
            }
            Button {
                viewModel.increment()
            } label: {
                Text("+ 50")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.accentColor)
                    )
            }

        }
    }
    
    
    class ViewModel: ObservableObject {
        @Published var energy: Double = 40
        @Published var carb: Double = 69
        @Published var fat: Double = 30
        @Published var protein: Double = 12.5
        
        func increment() {
            withAnimation {
                energy += 100
                carb += 50
                fat += 5
                protein += 20
            }
        }
        
        func decrement() {
            withAnimation {
                energy = max(energy - 100, 0)
                carb = max(carb - 50, 0)
                fat = max(fat - 5, 0)
                protein = max(protein - 20, 0)
            }
        }
    }
}

extension NutritionSummaryPreview.ViewModel: NutritionSummaryProvider {
    var energyAmount: Double { energy }
    var carbAmount: Double { carb }
    var fatAmount: Double { fat }
    var proteinAmount: Double { protein }
}

struct NutritionSummary_Previews: PreviewProvider {
    static var previews: some View {
        NutritionSummaryPreview()
    }
}
