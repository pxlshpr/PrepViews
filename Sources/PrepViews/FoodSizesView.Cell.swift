import SwiftUI
import PrepDataTypes

extension FoodSizesView {
    struct Cell: View {
        let size: FormSize?
        let didTapAddSize: (() -> ())?

        init(for size: FormSize?, didTapAddSize: (() -> ())? = nil) {
            self.size = size
            self.didTapAddSize = didTapAddSize
        }
    }
}

extension FoodSizesView.Cell {
    
    @ViewBuilder
    var body: some View {
        if let didTapAddSize, isAddButton {
            Button {
                didTapAddSize()
            } label: {
                label
            }
        } else {
            label
        }
    }
    
    var label: some View {
        ZStack {
            Capsule(style: .continuous)
                .foregroundColor(Color(.secondarySystemFill))
            HStack(spacing: 5) {
                if isAddButton {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .imageScale(.small)
                        .frame(height: 25)
                }
                Text(name)
                    .foregroundColor(isAddButton ? .accentColor : .primary)
                if !amountString.isEmpty {
                    Text("•")
                        .foregroundColor(Color(.quaternaryLabel))
                    Text(amountString)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .frame(height: 25)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .fixedSize(horizontal: true, vertical: true)
    }
    
    var isAddButton: Bool {
        size == nil
    }
    
    var name: String {
        size?.fullNameString ?? "Add a size"
    }
    
    var amountString: String {
        size?.scaledAmountString ?? ""
    }
}

import SwiftUISugar

struct CellPreviews: PreviewProvider {
    static var previews: some View {
//        FoodSizesView.Cell(size: standardSize)
        FormStyledScrollView {
            FormStyledSection(header: Text("Sizes")) {
                FoodSizesView(sizes: .constant(sizes), didTapAddSize: { })
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
