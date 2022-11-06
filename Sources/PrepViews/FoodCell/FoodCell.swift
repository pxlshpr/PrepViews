import SwiftUI

public struct FoodCell: View {
    
    let emoji: String
    let name: String
    let detail: String?
    let brand: String?
    let carb: Double
    let fat: Double
    let protein: Double

    public init(emoji: String, name: String, detail: String? = nil, brand: String? = nil, carb: Double, fat: Double, protein: Double) {
        self.emoji = emoji
        self.name = name
        self.detail = detail
        self.brand = brand
        self.carb = carb
        self.fat = fat
        self.protein = protein
    }
    
    public var body: some View {
        HStack {
            emojiText
            nameTexts
            Spacer()
            macrosIndicator
        }
        .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
    
    @ViewBuilder
    var emojiText: some View {
        Text(emoji)
    }
    
    let nameWeight: Font.Weight = .regular
    let detailWeight: Font.Weight = .regular
    let brandWeight: Font.Weight = .regular
    
    let nameColor: Color = Color(.label)
    let detailColor: Color = Color(.secondaryLabel)
    let brandColor: Color = Color(.tertiaryLabel)
    
    var nameTexts: some View {
        var view = Text(name)
            .font(.body)
            .fontWeight(nameWeight)
            .foregroundColor(nameColor)
        if let detail = detail, !detail.isEmpty {
            view = view
            + Text(", ")
                .font(.callout)
                .fontWeight(detailWeight)
                .foregroundColor(detailColor)
            + Text(detail)
                .font(.callout)
                .fontWeight(detailWeight)
                .foregroundColor(detailColor)
        }
        if let brand = brand, !brand.isEmpty {
            view = view
            + Text(", ")
                .font(.callout)
                .fontWeight(brandWeight)
                .foregroundColor(brandColor)
            + Text(brand)
                .font(.callout)
                .fontWeight(brandWeight)
                .foregroundColor(brandColor)
        }
        view = view

        .font(.callout)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        
        return view
            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                dimensions[.leading]
            }
    }
    
    var macrosIndicator: some View {
        MacrosIndicator(c: carb, f: fat, p: protein)
    }
}


struct FoodCellPreview: View {
    
    struct CompactFood {
        let emoji, name : String
        var detail: String? = nil
        var brand: String? = nil
        let c, f, p: Double
    }
    
    let foods: [CompactFood] = [
        CompactFood(emoji: "🧀", name: "Cheese", c: 3, f: 35, p: 14),
        CompactFood(emoji: "🍚", name: "White Rice", c: 42, f: 1, p: 4),
        CompactFood(emoji: "🧀", name: "Parmesan Cheese", detail: "Shredded", brand: "Emborg Ness", c: 42, f: 1, p: 4),
        CompactFood(emoji: "🧀", name: "Parmesan Cheese", detail: "Big", brand: "Emborg", c: 42, f: 1, p: 4),
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(foods, id: \.name) { food in
                    FoodCell(
                        emoji: food.emoji,
                        name: food.name,
                        detail: food.detail,
                        brand: food.brand,
                        carb: food.c,
                        fat: food.f,
                        protein: food.p
                    )
                }
            }
            .navigationTitle("Foods")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FoodCell_Previews: PreviewProvider {
    static var previews: some View {
        FoodCellPreview()
    }
}
