import SwiftUI

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
            var valueString: String {
                guard let value = meterViewModel.increment else { return "" }
                if value < 50 {
                    return value.rounded(toPlaces: 1).cleanAmount
                } else {
                    return value.rounded().cleanAmount
                }
            }

            return HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(valueString)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(meterViewModel.labelTextColor)
//                    .foregroundColor(.secondary)
                Text(meterViewModel.component.unit)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(meterViewModel.labelTextColor.opacity(0.5))
//                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        
        var quantity_legacy: some View {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(meterViewModel.increment?.cleanAmount ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(meterViewModel.component.unit)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        
        return GridRow {
            label
            meter
            quantity
        }
    }
}
