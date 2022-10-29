import SwiftUI
import PrepDataTypes
import SwiftUISugar

public struct FoodSizesView: View {
    
    struct SizeCell {
        let size: FormSize?
    }
    
    let cells: [SizeCell]
    let didTapAddSize: (() -> ())?
    
    public init(sizes: Binding<[FormSize]>, didTapAddSize: (() -> ())? = nil) {
        self.didTapAddSize = didTapAddSize
        
        var cells = sizes.wrappedValue.map { SizeCell(size: $0) }
        if didTapAddSize != nil {
            cells.append(SizeCell(size: nil))
        }
        self.cells = cells
    }
    
    public var body: some View {
        FlowLayout(
            mode: .scrollable,
            items: cells,
            itemSpacing: 4,
            shouldAnimateHeight: .constant(false)
        ) { cell in
            Cell(for: cell.size, didTapAddSize: didTapAddSize)
        }
    }
}
