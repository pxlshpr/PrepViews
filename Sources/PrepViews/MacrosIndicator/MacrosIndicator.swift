import SwiftUI
import PrepDataTypes

public struct MacrosIndicator: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let carb, fat, protein: Double
    
    public init(_ searchResult: FoodSearchResult) {
        self.carb = searchResult.carb
        self.fat = searchResult.fat
        self.protein = searchResult.protein
    }
    
    public init(_ food: Food) {
        self.carb = food.info.nutrients.carb
        self.fat = food.info.nutrients.fat
        self.protein = food.info.nutrients.protein
    }
    
    let width: CGFloat = 30
    
    public var body: some View {
        HStack(spacing: 0) {
            if totalEnergy == 0 {
                Color.clear
                    .background(Color(.quaternaryLabel).gradient)
            } else {
                Color.clear
                    .frame(width: carbWidth)
                    .background(Macro.carb.fillColor(for: colorScheme).gradient)
                Color.clear
                    .frame(width: fatWidth)
                    .background(Macro.fat.fillColor(for: colorScheme).gradient)
                Color.clear
                    .frame(width: proteinWidth)
                    .background(Macro.protein.fillColor(for: colorScheme).gradient)
            }
        }
        .frame(width: width, height: 10)
        .cornerRadius(2)
        .shadow(radius: 1.5, x: 0, y: 1.5)
    }
    
    var totalEnergy: CGFloat {
        (carb * KcalsPerGramOfCarb) + (protein * KcalsPerGramOfProtein) + (fat * KcalsPerGramOfFat)
    }
    var carbWidth: CGFloat {
        guard totalEnergy != 0 else { return 0 }
        return ((carb * KcalsPerGramOfCarb) / totalEnergy) * width
    }
    
    var proteinWidth: CGFloat {
        guard totalEnergy != 0 else { return 0 }
        return ((protein * KcalsPerGramOfProtein) / totalEnergy) * width
    }
    
    var fatWidth: CGFloat {
        guard totalEnergy != 0 else { return 0 }
        return ((fat * KcalsPerGramOfFat) / totalEnergy) * width
    }
}
