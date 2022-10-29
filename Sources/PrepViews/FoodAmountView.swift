import SwiftUI
import PrepDataTypes

public struct FoodAmountPerView: View {
    
    @Binding var amountDescription: String
    @Binding var servingDescription: String?
    @Binding var numberOfSizes: Int
    
    public init(amountDescription: Binding<String>, servingDescription: Binding<String?>, numberOfSizes: Binding<Int>) {
        _amountDescription = amountDescription
        _servingDescription = servingDescription
        _numberOfSizes = numberOfSizes
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(amountDescription)
                    .foregroundColor(.primary)
                if let servingDescription {
                    Text("•")
                        .foregroundColor(Color(.quaternaryLabel))
                    Text(servingDescription)
                        .foregroundColor(.secondary)
                }
                Spacer()
                sizesCount
            }
        }
    }
    
    @ViewBuilder
    var sizesCount: some View {
        if numberOfSizes > 0 {
            HStack {
                Text("\(numberOfSizes) size\(numberOfSizes != 1 ? "s" : "")")
                    .foregroundColor(Color(.secondaryLabel))
            }
            .padding(.vertical, 5)
            .padding(.leading, 7)
            .padding(.trailing, 9)
            .background(
                Capsule(style: .continuous)
                    .foregroundColor(Color(.secondarySystemFill))
            )
            .padding(.vertical, 5)
        }
    }
}
