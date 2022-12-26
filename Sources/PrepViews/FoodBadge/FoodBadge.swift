import SwiftUI
import PrepDataTypes

public struct FoodBadge: View {

    public static let DefaultWidth: CGFloat = 30

    @Environment(\.colorScheme) var colorScheme
    
    let carb, fat, protein: Double
    @Binding var width: CGFloat

    public init(_ searchResult: FoodSearchResult) {
        self.carb = searchResult.carb
        self.fat = searchResult.fat
        self.protein = searchResult.protein
        _width = .constant(Self.DefaultWidth)
    }
    
    public init(_ food: Food) {
        self.carb = food.info.nutrients.carb
        self.fat = food.info.nutrients.fat
        self.protein = food.info.nutrients.protein
        _width = .constant(Self.DefaultWidth)
    }

    public init(
        c: Double,
        f: Double,
        p: Double,
        width: Binding<CGFloat> = .constant(Self.DefaultWidth)
    ) {
        self.carb = c
        self.fat = f
        self.protein = p
        _width = width
    }
    
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
        /// No shadows 🙅🏽‍♂️ as this causes stuttering while scrolling (even on the most performant devices)
//        .shadow(radius: 1, x: 0, y: 1.5)
//        .shadow(color: Color(.systemFill), radius: 1, x: 0, y: 1.5)
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

struct FoodBadgePreview: View {
    
    struct Food {
        let emoji, name: String
        let c, f, p: Double
    }
    
    let foods: [Food] = [
        Food(emoji: "🧀", name: "Cheese", c: 3, f: 35, p: 14),
        Food(emoji: "🍚", name: "White Rice", c: 42, f: 1, p: 4)
    ]
    var body: some View {
        NavigationView {
            List {
                ForEach(foods, id: \.name) { food in
                    HStack {
                        Text(food.emoji)
                        Text(food.name)
                        Spacer()
                        FoodBadge(c: food.c, f: food.f, p: food.p)
                    }
                }
            }
            .navigationTitle("Foods")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MacrosIndicator_Previews: PreviewProvider {
    static var previews: some View {
        FoodBadgePreview()
    }
}
