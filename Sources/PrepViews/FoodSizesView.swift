import SwiftUI
import PrepDataTypes
import SwiftUISugar

public struct FoodSizesView: View {
    
    @Binding var sizes: [FormSize]
    
    public init(sizes: Binding<[FormSize]>) {
        _sizes = sizes
    }
    
    public var body: some View {
        FlowLayout(
            mode: .scrollable,
            items: sizes,
            itemSpacing: 4,
            shouldAnimateHeight: .constant(false)
        ) { size in
            Cell(size: size)
        }
    }
}
