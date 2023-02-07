//import SwiftUI
//import FoodLabel
//import SwiftHaptics
//import PrepDataTypes
//import SwiftUISugar
//
//struct FoodLabelSheet: View {
//
//    let foodItem: MealFoodItem
//
//    @Environment(\.dismiss) var dismiss
//    @State var foodLabelHeight: CGFloat = 0
//    
//    var body: some View {
//        NavigationStack {
//            content
//            .padding(.horizontal, 15)
//            .toolbar {
//                ToolbarItemGroup(placement: .navigationBarTrailing) {
//                    Button {
//                        Haptics.feedback(style: .soft)
//                        dismiss()
//                    } label: {
//                        CloseButtonLabel(forNavigationBar: true)
//                    }
//                }
//            }
//        }
//        .presentationDetents([.height(foodLabelHeight)])
//        .presentationDragIndicator(.hidden)
//    }
//    
//    @ViewBuilder
//    var content: some View {
//        if totalHeight > UIScreen.main.bounds.height {
//            ScrollView(showsIndicators: false) {
//                foodLabelAfterReadingSize
//            }
//        } else {
//            foodLabelAfterReadingSize
//        }
//    }
//    
//    var foodLabelAfterReadingSize: some View {
//        foodLabel
//            .readSize { size in
//                let navigationBarHeight = 58.0
//                foodLabelHeight = size.height + navigationBarHeight
//            }
//    }
//
//    var totalHeight: CGFloat {
//        let bottomSafeAreaHeight = 34.0
//        let topSafeAreaHeight = 69.0
//        return foodLabelHeight + bottomSafeAreaHeight + topSafeAreaHeight
//    }
//
//    var foodLabel: FoodLabel {
//        let energyBinding = Binding<FoodLabelValue>(
////            get: { fields.energy.value.value ?? .init(amount: 0, unit: .kcal)  },
//            get: {
//                .init(amount: foodItem.scaledValueForEnergyInKcal, unit: .kcal)
//            },
//            set: { _ in }
//        )
//
//        let carbBinding = Binding<Double>(
//            get: { foodItem.scaledValueForMacro(.carb) },
//            set: { _ in }
//        )
//
//        let fatBinding = Binding<Double>(
//            get: { foodItem.scaledValueForMacro(.fat) },
//            set: { _ in }
//        )
//
//        let proteinBinding = Binding<Double>(
//            get: { foodItem.scaledValueForMacro(.protein) },
//            set: { _ in }
//        )
//        
//        let microsBinding = Binding<[NutrientType : FoodLabelValue]>(
//            get: { foodItem.microsDict },
//            set: { _ in }
//        )
//        
//        let amountBinding = Binding<String>(
//            get: { foodItem.description },
//            set: { _ in }
//        )
//
//        return FoodLabel(
//            energyValue: energyBinding,
//            carb: carbBinding,
//            fat: fatBinding,
//            protein: proteinBinding,
//            nutrients: microsBinding,
//            amountPerString: amountBinding
//        )
//    }
//}
