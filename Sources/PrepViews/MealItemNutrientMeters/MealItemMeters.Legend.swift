import SwiftUI

extension MealItemMeters {
    struct Legend: View {
        
        let prepped: [NutrientMeterComponent]
        let increments: [NutrientMeterComponent]
        let showCompletion: Bool
        let showExcess: Bool
        
        static let spacing: CGFloat = 2
        static let colorSize: CGFloat = 10
        let cornerRadius: CGFloat = 2
        
        static let gridItem = GridItem(.fixed(colorSize), spacing: spacing)
        static let gridLayout = [gridItem, gridItem]
        
        init(
            prepped: [NutrientMeterComponent] = [],
            increments: [NutrientMeterComponent] = [],
            showCompletion: Bool = false,
            showExcess: Bool = false
        ) {
            self.prepped = prepped
            self.increments = increments
            self.showCompletion = showCompletion
            self.showExcess = showExcess
        }
    }
}

extension MealItemMeters.Legend {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                incrementsGrid
                //                    .padding(.top, Self.spacing)
                Text("This is how much of an increase adding this food will result in.")
            }
            HStack(alignment: .center) {
                preppedGrid
                //                    .padding(.top, Self.spacing)
                Text("This is what you have already planned for the day.")
            }
        }
    }
    
    var preppedGrid: some View {
        LazyVGrid(columns: Self.gridLayout, spacing: Self.spacing) {
            ForEach(prepped, id: \.self) {
                colorBox($0.preppedColor)
            }
            if showCompletion {
                colorBox(NutrientMeter.ViewModel.Colors.Complete.placeholder)
            }
            if showExcess {
                colorBox(NutrientMeter.ViewModel.Colors.Excess.placeholder)
            }
        }
        .fixedSize()
    }
    
    var incrementsGrid: some View {
        LazyVGrid(columns: Self.gridLayout, spacing: Self.spacing) {
            ForEach(increments, id: \.self) {
                colorBox($0.eatenColor)
            }
            if showCompletion {
                colorBox(NutrientMeter.ViewModel.Colors.Complete.fill)
            }
            if showExcess {
                colorBox(NutrientMeter.ViewModel.Colors.Excess.fill)
            }
        }
        .fixedSize()
    }
    
    func colorBox(_ color: Color) -> some View {
        color
            .frame(width: Self.colorSize, height: Self.colorSize)
            .cornerRadius(cornerRadius)
    }
}
