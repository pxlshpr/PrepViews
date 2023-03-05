import SwiftUI
import PrepDataTypes

let MeterLabelFontStyle: Font.TextStyle = .body
let MeterLabelFont: Font = Font.system(MeterLabelFontStyle)

struct ItemPortionMetrics: View {
    
    @EnvironmentObject var model: ItemPortion.Model
    
    let type: PortionPage
    
    init(_ type: PortionPage) {
        self.type = type
    }
    
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
            return !model.hasDiet
        case .meal:
            return !(model.shouldShowMealContent)
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
            ForEach(model.nutrientMeterModels.indices, id: \.self) { index in
                MeterRow(meterModel: $model.nutrientMeterModels[index])
            }
        case .diet:
            ForEach(model.dietMeterModels.indices, id: \.self) { index in
                MeterRow(meterModel: $model.dietMeterModels[index])
            }
        case .meal:
            ForEach(model.mealMeterModels.indices, id: \.self) { index in
                MeterRow(meterModel: $model.mealMeterModels[index])
            }
        }
    }
}

extension NutrientMeter.Model {
    var convertedQuantity: (value: Double, unit: NutrientUnit) {
        guard let value = increment else { return (0, .g) }
        let unit = component.unit
        return unit.convertingLargeValue(value)
    }
}

struct MeterRow: View {
    
    @Binding var meterModel: NutrientMeter.Model
    @State var value: Double
    @State var unit: NutrientUnit
    
    let styleAsPlaceholder: Bool
    
    init(emptyRowFor component: NutrientMeterComponent) {
        _meterModel = .constant(.init(component: component, customPercentage: 0, customValue: 0))
        _value = State(initialValue: 100)
        _unit = State(initialValue: .mg)
        styleAsPlaceholder = true
    }
    
    init(meterModel: Binding<NutrientMeter.Model>) {
        _meterModel = meterModel
        _value = State(initialValue: meterModel.wrappedValue.convertedQuantity.value)
        _unit = State(initialValue: meterModel.wrappedValue.convertedQuantity.unit)
        styleAsPlaceholder = false
    }
    
    var body: some View {
        GridRow {
            label
            meter
            quantityLabel_animated
        }
        .onChange(of: meterModel.increment, perform: incrementChanged)
        .if(styleAsPlaceholder) { view in
            view.redacted(reason: .placeholder)
        }
    }
    
    func incrementChanged(to newValue: Double?) {
        withAnimation {
            self.value = meterModel.convertedQuantity.value
            self.unit = meterModel.convertedQuantity.unit
        }
    }
    
    var label: some View {
        HStack {
            Text(meterModel.component.description)
                .foregroundColor(meterModel.labelTextColor)
//                .font(.system(.callout, design: .rounded, weight: .light))
                .font(.system(size: 13, weight: .light, design: .rounded))
            if meterModel.isGenerated {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(meterModel.labelTextColor.opacity(0.5))
            }
        }
    }
    
    var meter: some View {
        NutrientMeter(model: .constant(meterModel))
            .frame(height: MeterHeight)
    }
    
    var quantityLabel_animated: some View {
//        HStack(alignment: .bottom, spacing: 2) {
            /// Using an animated number here
            Color.clear
                .animatedNutrient(value: value, unit: unit, color: meterModel.labelTextColor)
//                .animatingOverlay(for: value, fontSize: 16, fontWeight: .medium)
//                .foregroundColor(meterModel.labelTextColor)
//            if unit != .kcal {
//                Text(unit.shortestDescription)
//                    .font(.caption)
//                    .fontWeight(.medium)
//                    .foregroundColor(meterModel.labelTextColor.opacity(0.5))
//                    .offset(y: -0.5)
//            }
//        }
    }

    var quantityLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value.formattedNutrient)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(meterModel.labelTextColor)
            if unit != .kcal {
                Text(unit.shortestDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(meterModel.labelTextColor.opacity(0.5))
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
