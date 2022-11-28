import SwiftUI
import PrepDataTypes

let MeterLabelFontStyle: Font.TextStyle = .body
let MeterLabelFont: Font = Font.system(MeterLabelFontStyle)

extension MealItemMeters {
    
    struct Meters: View {
        
        @EnvironmentObject var viewModel: MealItemMeters.ViewModel
        
        let type: MetersType
        
        init(_ type: MetersType) {
            self.type = type
        }
    }
}

extension MealItemMeters.Meters {
    var body: some View {
        VStack {
            Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
                ForEach(viewModel.meterViewModels(for: type), id: \.self.component) { meterViewModel in
                    meterRow(for: meterViewModel)
                }
            }
        }
    }

    func meterRow(for meterViewModel: NutrientMeter.ViewModel) -> some View {
        var label: some View {
            HStack {
                Text(meterViewModel.component.description)
                    .foregroundColor(meterViewModel.labelTextColor)
                    .font(.system(.callout, design: .rounded, weight: .light))
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

        var quantity: some View {
            
            var convertedValue: (value: Double, unit: NutrientUnit) {
                guard let value = meterViewModel.increment else { return (0, .g) }
                let unit = meterViewModel.component.unit
                return unit.convertingLargeValue(value)
            }
            
            var valueString: String {
//                guard let value = meterViewModel.increment else { return "" }
                let value = convertedValue.value
                let rounded: Double
                if value < 50 {
                    rounded = value.rounded(toPlaces: 1)
                } else {
                    rounded = value.rounded()
                }
                return rounded.formattedWithCommas
            }
            
            return HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(valueString)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(meterViewModel.labelTextColor)
                if convertedValue.unit != .kcal {
                    Text(convertedValue.unit.shortestDescription)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(meterViewModel.labelTextColor.opacity(0.5))
                }
            }
        }
               
        return GridRow {
            label
            meter
            quantity
        }
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

extension NutrientUnit {
    
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
