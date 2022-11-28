import SwiftUI
import SwiftHaptics

public struct FoodCell: View {

    //TODO: Refactor this and move to PrepViews
    /// [ ] Rename it to `isSelectable`
    /// [ ] Make it optional so that we can disregard it if needed
    /// [ ] Conslidate it by moving it back to `PrepViews`

    @Binding var isSelectable: Bool
    @State var isSelected: Bool = false

    let emoji: String
    let name: String
    let detail: String?
    let brand: String?
    let carb: Double
    let fat: Double
    let protein: Double
    
    let nameWeight: Font.Weight
    let detailWeight: Font.Weight = .regular
    let brandWeight: Font.Weight = .regular
    
    let nameColor: Color = Color(.label)
    let detailColor: Color = Color(.secondaryLabel)
    let brandColor: Color = Color(.tertiaryLabel)
    
    let showMacrosIndicator: Bool
    let didTapMacrosIndicator: (() -> ())?
    let didToggleSelection: ((Bool) -> ())?

    public init(
        emoji: String,
        name: String,
        detail: String? = nil,
        brand: String? = nil,
        carb: Double,
        fat: Double,
        protein: Double,
        nameFontWeight: Font.Weight = .medium,
        showMacrosIndicator: Bool = true,
        isSelectable: Binding<Bool> = .constant(false),
        didTapMacrosIndicator: (() -> ())? = nil,
        didToggleSelection: ((Bool) -> ())? = nil
    ) {
        self.emoji = emoji
        self.name = name
        self.detail = detail
        self.brand = brand
        self.carb = carb
        self.fat = fat
        self.protein = protein
        self.nameWeight = nameFontWeight
        
        self.showMacrosIndicator = showMacrosIndicator
        self.didTapMacrosIndicator = didTapMacrosIndicator
        self.didToggleSelection = didToggleSelection

        _isSelectable = isSelectable
    }
    
    public var body: some View {
        HStack {
            selectionButton
            emojiText
            nameTexts
            if showMacrosIndicator {
                Spacer()
                macrosIndicator
            }
        }
        .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
    
    @ViewBuilder
    var selectionButton: some View {
        if isSelectable {
            Button {
                Haptics.feedback(style: .soft)
                withAnimation {
                    isSelected.toggle()
                }
                didToggleSelection?(isSelected)
            } label: {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundColor(isSelected ? Color.accentColor : Color(.quaternaryLabel))
            }
        }
    }
    
    @ViewBuilder
    var emojiText: some View {
        Text(emoji)
    }
    
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
    
    @ViewBuilder
    var macrosIndicator: some View {
        if let didTapMacrosIndicator {
            Button {
                didTapMacrosIndicator()
            } label: {
                macrosIndicatorLabel
            }
            .buttonStyle(.borderless)
        } else {
            macrosIndicatorLabel
        }
    }
    
    var macrosIndicatorLabel: some View {
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
                        protein: food.p,
                        isSelectable: .constant(false),
                        didToggleSelection: { isSelected in
                            print("\(food) selection changed to: \(isSelected)")
                        }
                    )
                }
            }
            .navigationTitle("Foods")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

import SwiftUISugar
import PrepMocks
import PrepDataTypes

struct FoodCellAlignmentPreview: View {
    
    @StateObject var viewModel = ViewModel()
    
    var food: Food {
        var food = FoodMock.carrots
        food.detail = "Juicy, thick, meaty all those nice things"
        food.brand = "Some brand"
        return food
    }
    
    var body: some View {
        FormStyledScrollView {
            FormStyledSection(horizontalPadding: 0) {
                VStack {
                    foodLink
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    var foodLink: some View {
        Button {
        } label: {
            HStack {
                FoodCell(
                    food: food,
                    showMacrosIndicator: false
                )
                .fixedSize(horizontal: false, vertical: true)
                Spacer()
                NutritionSummary(
                    dataProvider: viewModel,
                    showMacrosIndicator: true
                )
                .fixedSize(horizontal: true, vertical: false)
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .fontWeight(.medium)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .multilineTextAlignment(.leading)
        }
    }
    
    class ViewModel: ObservableObject { }
}

extension FoodCellAlignmentPreview.ViewModel: NutritionSummaryProvider {
    var forMeal: Bool {
        true
    }
    
    var isMarkedAsCompleted: Bool {
        true
    }
    
    var showQuantityAsSummaryDetail: Bool {
        true
    }
    
    var energyAmount: Double {
        120
    }
    
    var carbAmount: Double {
        69
    }
    
    var fatAmount: Double {
        7
    }
    
    var proteinAmount: Double {
        42
    }
    
    
}

struct FoodCell_Previews: PreviewProvider {
    static var previews: some View {
//        FoodCellPreview()
        FoodCellAlignmentPreview()
    }
}
