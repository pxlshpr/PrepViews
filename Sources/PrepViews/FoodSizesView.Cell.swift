import SwiftUI
import PrepDataTypes

extension FoodSizesView {
    struct Cell: View {
        let size: FormSize
    }
}

extension FoodSizesView.Cell {
    
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .foregroundColor(Color(.secondarySystemFill))
            HStack(spacing: 5) {
                Text(name)
                    .foregroundColor(.primary)
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Text(amountString)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
    
    var name: String {
        size.fullNameString
    }
    
    var amountString: String {
        size.scaledAmountString
    }
}

import SwiftUISugar

struct CellPreviews: PreviewProvider {
    static var previews: some View {
//        FoodSizesView.Cell(size: standardSize)
        FormStyledScrollView {
            FormStyledSection(header: Text("Sizes")) {
                FoodSizesView(sizes: .constant(sizes))
            }
        }
    }
    
    
    static var sizes: [FormSize] {
        [
            FormSize(quantity: 1, name: "large", amount: 50, unit: .weight(.g)),
            FormSize(quantity: 1, name: "medium", amount: 45, unit: .weight(.g)),
            FormSize(quantity: 1, name: "small", amount: 38, unit: .weight(.g)),
            FormSize(quantity: 1, volumePrefixUnit: .volume(.cup), name: "shredded", amount: 220, unit: .weight(.g)),
            FormSize(quantity: 1, volumePrefixUnit: .volume(.cup), name: "diced", amount: 175, unit: .weight(.g)),
        ]
    }
}
