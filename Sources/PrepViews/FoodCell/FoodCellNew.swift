//import SwiftUI
//import SwiftHaptics
//import PrepDataTypes
//import SwiftSugar
//
//public class FoodCellViewModel: ObservableObject, Identifiable {
//    public let id: UUID = UUID()
//    let emoji: String
//    let name: String
//    let detail: String?
//    let brand: String?
//    let carb: Double
//    let fat: Double
//    let protein: Double
//    
//    let width: CGFloat = 30
//    
//    @Published var carbWidth: CGFloat? = nil
//    @Published var fatWidth: CGFloat? = nil
//    @Published var proteinWidth: CGFloat? = nil
//    @Published var isZeroCalories: Bool = false
//
//    public init(emoji: String, name: String, detail: String?, brand: String?, carb: Double, fat: Double, protein: Double) {
//        self.emoji = emoji
//        self.name = name
//        self.detail = detail
//        self.brand = brand
//        self.carb = carb
//        self.fat = fat
//        self.protein = protein
//        
//        Task(priority: .low) {
//            await calculateWidths()
//        }
//    }
//    
//    public convenience init(food: Food) {
//        self.init(
//            emoji: food.emoji,
//            name: food.name,
//            detail: food.detail,
//            brand: food.brand,
//            carb: food.info.nutrients.carb,
//            fat: food.info.nutrients.fat,
//            protein: food.info.nutrients.protein
//        )
//    }
//    
//    func calculateWidths() async {
//        let carbWidth = calculatedCarbWidth
//        let proteinWidth = calculatedProteinWidth
//        let fatWidth = calculatedFatWidth
//        
//        await MainActor.run {
//            withAnimation {
//                self.carbWidth = carbWidth
//                self.proteinWidth = proteinWidth
//                self.fatWidth = fatWidth
//                self.isZeroCalories = totalEnergy == 0
//                cprint("Calculated widths for: \(emoji) \(name)")
//            }
//        }
//    }
//    
//    var totalEnergy: CGFloat {
//        (carb * KcalsPerGramOfCarb) + (protein * KcalsPerGramOfProtein) + (fat * KcalsPerGramOfFat)
//    }
//    var calculatedCarbWidth: CGFloat {
//        guard totalEnergy != 0 else { return 0 }
//        return ((carb * KcalsPerGramOfCarb) / totalEnergy) * width
//    }
//    
//    var calculatedProteinWidth: CGFloat {
//        guard totalEnergy != 0 else { return 0 }
//        return ((protein * KcalsPerGramOfProtein) / totalEnergy) * width
//    }
//    
//    var calculatedFatWidth: CGFloat {
//        guard totalEnergy != 0 else { return 0 }
//        return ((fat * KcalsPerGramOfFat) / totalEnergy) * width
//    }
//}
//
//public struct FoodCellNew: View {
//
//    @AppStorage(UserDefaultsKeys.showingFoodEmojis) var showingFoodEmojis = true
//
//    @Binding var isSelectable: Bool
//    @State var isSelected: Bool = false
//
//    @ObservedObject var viewModel: FoodCellViewModel
//    
//    let showMacrosIndicator: Bool
//    let didTapMacrosIndicator: (() -> ())?
//    let didToggleSelection: ((Bool) -> ())?
//
//    public init(
//        viewModel: FoodCellViewModel,
//        showMacrosIndicator: Bool = true,
//        isSelectable: Binding<Bool> = .constant(false),
//        didTapMacrosIndicator: (() -> ())? = nil,
//        didToggleSelection: ((Bool) -> ())? = nil
//    ) {
//        self.viewModel = viewModel
//        
//        self.showMacrosIndicator = showMacrosIndicator
//        self.didTapMacrosIndicator = didTapMacrosIndicator
//        self.didToggleSelection = didToggleSelection
//
//        _isSelectable = isSelectable
//    }
//    
//    public var body: some View {
//        HStack {
//            selectionButton
//            emojiText
//            nameTexts
//            if showMacrosIndicator {
//                Spacer()
//                macrosIndicator
//            }
//        }
//        .listRowBackground(Color(.secondarySystemGroupedBackground))
//    }
//    
//    @ViewBuilder
//    var selectionButton: some View {
//        if isSelectable {
//            Button {
//                Haptics.feedback(style: .soft)
//                withAnimation {
//                    isSelected.toggle()
//                }
//                didToggleSelection?(isSelected)
//            } label: {
//                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
//                    .foregroundColor(isSelected ? Color.accentColor : Color(.quaternaryLabel))
//            }
//        }
//    }
//    
//    @ViewBuilder
//    var emojiText: some View {
//        if showingFoodEmojis {
//            Text(viewModel.emoji)
//        }
//    }
//    
//    var nameTexts: some View {
//        var view = Text(viewModel.name)
//            .font(.body)
//            .fontWeight(.medium)
//            .foregroundColor(Color(.label))
//        if let detail = viewModel.detail, !detail.isEmpty {
//            view = view
//            + Text(", ")
//            
//                .font(.callout)
//                .fontWeight(.regular)
//                .foregroundColor(Color(.secondaryLabel))
//            + Text(detail)
//                .font(.callout)
//                .fontWeight(.regular)
//                .foregroundColor(Color(.secondaryLabel))
//        }
//        if let brand = viewModel.brand, !brand.isEmpty {
//            view = view
////            + Text(detail?.isEmpty == true ? "" : ", ")
//            + Text(", ")
//                .font(.callout)
//                .fontWeight(.regular)
//                .foregroundColor(Color(.tertiaryLabel))
//            + Text(brand)
//                .font(.callout)
//                .fontWeight(.regular)
//                .foregroundColor(Color(.tertiaryLabel))
//        }
//        view = view
//
//        .font(.callout)
//        .fontWeight(.semibold)
//        .foregroundColor(.secondary)
//        
//        return view
//            .alignmentGuide(.listRowSeparatorLeading) { dimensions in
//                dimensions[.leading]
//            }
//    }
//    
//    @ViewBuilder
//    var macrosIndicator: some View {
//        if let didTapMacrosIndicator {
//            Button {
//                didTapMacrosIndicator()
//            } label: {
//                macrosIndicatorLabel
//            }
//            .buttonStyle(.borderless)
//        } else {
//            macrosIndicatorLabel
//        }
//    }
//    
//    var macrosIndicatorLabel: some View {
//        let carbWidth = Binding<CGFloat>(
//            get: { viewModel.carbWidth ?? 0 },
//            set: { _ in }
//        )
//        let fatWidth = Binding<CGFloat>(
//            get: { viewModel.fatWidth ?? 0 },
//            set: { _ in }
//        )
//        let proteinWidth = Binding<CGFloat>(
//            get: { viewModel.proteinWidth ?? 0 },
//            set: { _ in }
//        )
//        let isZeroCalories = Binding<Bool>(
//            get: { viewModel.isZeroCalories },
//            set: { _ in }
//        )
//        return FoodBadgeNew(
//            carbWidth: carbWidth,
//            fatWidth: fatWidth,
//            proteinWidth: proteinWidth,
//            isZeroCalories: isZeroCalories
//        )
////        return FoodBadgeSimple()
//    }
//}
