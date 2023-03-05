import SwiftUI
import SwiftHaptics
import PrepDataTypes
import SwiftUISugar

public struct FoodCell: View {

    @Environment(\.colorScheme) var colorScheme
    
    //TODO: Refactor this and move to PrepViews
    /// [ ] Rename it to `isSelectable`
    /// [ ] Make it optional so that we can disregard it if needed
    /// [ ] Conslidate it by moving it back to `PrepViews`

    @Binding var showingEmoji: Bool
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
    
    @State var showingEmojiAnimated: Bool
    
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
        showEmoji: Binding<Bool>,
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
        _showingEmoji = showEmoji
        _showingEmojiAnimated = State(initialValue: showEmoji.wrappedValue)
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
        .onChange(of: showingEmoji, perform: showingEmojiChanged)
//        .listRowBackground(
//            colorScheme == .light ? Color(.systemGroupedBackground) : Color(hex: "191919")
////            FormCellBackground()
//        )
    }
    
    func showingEmojiChanged(_ newValue: Bool) {
        withAnimation(.interactiveSpring()) {
            showingEmojiAnimated = newValue
        }
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
        if showingEmojiAnimated {
            Text(emoji)
                .transition(.scale)
        }
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
//            + Text(detail?.isEmpty == true ? "" : ", ")
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
        FoodBadge(c: carb, f: fat, p: protein)
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
                        showEmoji: .constant(true),
                        isSelectable: .constant(false),
                        didToggleSelection: { isSelected in
                            cprint("\(food) selection changed to: \(isSelected)")
                        }
                    )
                }
            }
            .navigationTitle("Foods")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
