import SwiftUI
import PrepDataTypes

let MeterLabelFontStyle: Font.TextStyle = .body
let MeterLabelFont: Font = Font.system(MeterLabelFontStyle)

extension PortionAwareness {
    
    struct Meters: View {
        
        @EnvironmentObject var viewModel: PortionAwareness.ViewModel
        
        let type: MetersType
        
        init(_ type: MetersType) {
            self.type = type
        }
    }
}

extension PortionAwareness.Meters {
    
    var body: some View {
        metersGrid
    }
    
    var metersGrid: some View {
        Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
            if shouldShowEmptyRows {
                emptyRows
            } else {
                rows
            }
        }
    }
    
    var shouldShowEmptyRows: Bool {
        switch type {
        case .diet:
            return !viewModel.hasDiet
        case .meal:
            return !(viewModel.shouldShowMealContent)
        case .nutrients:
            return false
        }
    }
    
    var emptyRows: some View {
        let components: [NutrientMeterComponent] = [.energy, .carb, .fat, .protein]
        return ForEach(components, id: \.self) { component in
            MeterRow(emptyRowFor: component)
        }
    }
    
    @ViewBuilder
    var rows: some View {
        switch type {
        case .nutrients:
            ForEach(viewModel.nutrientMeterViewModels.indices, id: \.self) { index in
                MeterRow(meterViewModel: $viewModel.nutrientMeterViewModels[index])
            }
        case .diet:
            ForEach(viewModel.dietMeterViewModels.indices, id: \.self) { index in
                MeterRow(meterViewModel: $viewModel.dietMeterViewModels[index])
            }
        case .meal:
            ForEach(viewModel.mealMeterViewModels.indices, id: \.self) { index in
                MeterRow(meterViewModel: $viewModel.mealMeterViewModels[index])
            }
        }
    }
}

extension NutrientMeter.ViewModel {
    var convertedQuantity: (value: Double, unit: NutrientUnit) {
        guard let value = increment else { return (0, .g) }
        let unit = component.unit
        return unit.convertingLargeValue(value)
    }
}

struct MeterRow: View {
    
    @Binding var meterViewModel: NutrientMeter.ViewModel
    @State var value: Double
    @State var unit: NutrientUnit
    
    let styleAsPlaceholder: Bool
    
    init(emptyRowFor component: NutrientMeterComponent) {
        _meterViewModel = .constant(.init(component: component, customPercentage: 0, customValue: 0))
        _value = State(initialValue: 100)
        _unit = State(initialValue: .mg)
        styleAsPlaceholder = true
    }
    
    init(meterViewModel: Binding<NutrientMeter.ViewModel>) {
        _meterViewModel = meterViewModel
        _value = State(initialValue: meterViewModel.wrappedValue.convertedQuantity.value)
        _unit = State(initialValue: meterViewModel.wrappedValue.convertedQuantity.unit)
        styleAsPlaceholder = false
    }
    
    var body: some View {
        GridRow {
            label
            meter
            quantityLabel_animated
        }
        .onChange(of: meterViewModel.increment, perform: incrementChanged)
        .if(styleAsPlaceholder) { view in
            view.redacted(reason: .placeholder)
        }
    }
    
    func incrementChanged(to newValue: Double?) {
        withAnimation {
            self.value = meterViewModel.convertedQuantity.value
            self.unit = meterViewModel.convertedQuantity.unit
        }
    }
    
    var label: some View {
        HStack {
            Text(meterViewModel.component.description)
                .foregroundColor(meterViewModel.labelTextColor)
//                .font(.system(.callout, design: .rounded, weight: .light))
                .font(.system(size: 13, weight: .light, design: .rounded))
            if meterViewModel.isGenerated {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(meterViewModel.labelTextColor.opacity(0.5))
            }
        }
    }
    
    var meter: some View {
        NutrientMeter(viewModel: .constant(meterViewModel))
            .frame(height: MeterHeight)
    }
    
    var quantityLabel_animated: some View {
//        HStack(alignment: .bottom, spacing: 2) {
            /// Using an animated number here
            Color.clear
                .animatedNutrient(value: value, unit: unit, color: meterViewModel.labelTextColor)
//                .animatingOverlay(for: value, fontSize: 16, fontWeight: .medium)
//                .foregroundColor(meterViewModel.labelTextColor)
//            if unit != .kcal {
//                Text(unit.shortestDescription)
//                    .font(.caption)
//                    .fontWeight(.medium)
//                    .foregroundColor(meterViewModel.labelTextColor.opacity(0.5))
//                    .offset(y: -0.5)
//            }
//        }
    }

    var quantityLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value.formattedNutrient)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(meterViewModel.labelTextColor)
            if unit != .kcal {
                Text(unit.shortestDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(meterViewModel.labelTextColor.opacity(0.5))
            }
        }
    }
}

public extension Double {
    var formattedNutrient: String {
        let rounded: Double
        if self < 50 {
            rounded = self.rounded(toPlaces: 1)
        } else {
            rounded = self.rounded()
        }
        return rounded.formattedWithCommas
    }
    
    var formattedMealItemAmount: String {
        let rounded: Double
//        if self < 50 {
//            rounded = self.rounded(toPlaces: 1)
//        } else {
            rounded = self.rounded()
//        }
        return rounded.formattedWithCommas
    }

}

public extension Font.Weight {
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .medium:
            return .medium
        case .black:
            return .black
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .light:
            return .light
        case .regular:
            return .regular
        case .semibold:
            return .semibold
        case .thin:
            return .thin
        case .ultraLight:
            return .ultraLight
        default:
            return .regular
        }
    }
}
struct AnimatableNutrientModifier: AnimatableModifier {
    
    var value: Double
    var unit: NutrientUnit
    var color: Color
    
    let fontSize: CGFloat = 16
    let fontWeight: Font.Weight = .medium
    
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
    
    let unitFontSize: CGFloat = 12
    let unitFontWeight: Font.Weight = .medium
    
    var unitUIFont: UIFont {
        UIFont.systemFont(ofSize: unitFontSize, weight: unitFontWeight.uiFontWeight)
    }
    
    var unitWidth: CGFloat {
        unitUIFont.fontSize(for: unit.shortDescription).width
    }
    
    func body(content: Content) -> some View {
        content
//            .frame(width: size.width, height: size.height)
            .frame(width: 50 + unitWidth, height: size.height)
            .overlay(
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value.formattedNutrient)
                        .font(.system(size: fontSize, weight: fontWeight, design: .default))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(color)
                    if unit != .kcal {
                        Text(unit.shortestDescription)
                            .font(.system(size: unitFontSize, weight: unitFontWeight, design: .default))
//                            .font(.caption)
//                            .fontWeight(.medium)
                            .foregroundColor(color.opacity(0.5))
                            .offset(y: -0.5)
                    }
                    Spacer()
                }
            )
    }
}

public extension View {
    func animatedNutrient(value: Double, unit: NutrientUnit, color: Color) -> some View {
        modifier(AnimatableNutrientModifier(value: value, unit: unit, color: color))
    }
}

extension Double {
    var formattedWithCommas: String {
        guard self >= 1000 else {
            return cleanAmount
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let number = NSNumber(value: Int(self))
        
        guard let formatted = numberFormatter.string(from: number) else {
            return "\(Int(self))"
        }
        return formatted
    }
}

extension NutrientType {
    var shortestDescription: String {
        
        if let letter = vitaminLetterName {
            return "Vit. \(letter)"
        }
        
        switch self {
        case .saturatedFat:
            return "Sat. Fat"
        case .monounsaturatedFat:
            return "MUFA"
        case .polyunsaturatedFat:
            return "PUFA"
        case .dietaryFiber:
            return "Fiber"
        case .potassium:
            return "Potass."
        default:
            return description
        }
    }
}

public extension NutrientUnit {
    
    /// Converts things like 1000 mg → 1g, 1000 ug → 1mg
    func convertingLargeValue(_ value: Double) -> (Double, NutrientUnit) {
        var value = value
        var unit = self
        
        if unit.isMicrograms, value >= 1000 {
            value = value / 1000.0
            unit = .mg
        }
        
        if unit.isMilligrams, value >= 1000 {
            value = value / 1000.0
            unit = .g
        }
            
        return (value, unit)
    }
    
    var isMilligrams: Bool {
        switch self {
        case .mg, .mgAT, .mgNE, .mgGAE:
            return true
        default:
            return false
        }
    }
    
    var isMicrograms: Bool {
        switch self {
        case .mcg, .mcgDFE, .mcgRAE:
            return true
        default:
            return false
        }
    }
    
    var shortestDescription: String {
        switch self {
        case .mgAT, .mgNE, .mgGAE:
            return "mg"
        case .mcg, .mcgDFE, .mcgRAE:
            return "μg"
        default:
            return shortDescription
        }
    }
}
