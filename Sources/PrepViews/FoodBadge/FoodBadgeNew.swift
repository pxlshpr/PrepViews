//import SwiftUI
//import PrepDataTypes
//
//public struct FoodBadgeNew: View {
//
//    public static let DefaultWidth: CGFloat = 30
//
//    @Environment(\.colorScheme) var colorScheme
//    
//    @Binding var isZeroCalories: Bool
//    @Binding var carbWidth: CGFloat
//    @Binding var fatWidth: CGFloat
//    @Binding var proteinWidth: CGFloat
//
//    public init(carbWidth: Binding<CGFloat>, fatWidth: Binding<CGFloat>, proteinWidth: Binding<CGFloat>, isZeroCalories: Binding<Bool>) {
//        _carbWidth = carbWidth
//        _fatWidth = fatWidth
//        _proteinWidth = proteinWidth
//        _isZeroCalories = isZeroCalories
//    }
//
//    public var body: some View {
//        HStack(spacing: 0) {
//            if isZeroCalories {
//                Color.clear
//                    .background(Color(.quaternaryLabel).gradient)
//                    .frame(width: Self.DefaultWidth)
//            } else {
//                Color.clear
//                    .frame(width: carbWidth)
//                    .background(Macro.carb.fillColor(for: colorScheme).gradient)
//                Color.clear
//                    .frame(width: fatWidth)
//                    .background(Macro.fat.fillColor(for: colorScheme).gradient)
//                Color.clear
//                    .frame(width: proteinWidth)
//                    .background(Macro.protein.fillColor(for: colorScheme).gradient)
//            }
//        }
//        .frame(height: 10)
//        .cornerRadius(2)
////        .shadow(color: Color(.systemFill), radius: 1, x: 0, y: 1.5)
//    }
//}
//
//public struct FoodBadgeSimple: View {
//
//    @Environment(\.colorScheme) var colorScheme
//
//    public init() {
//    }
//
//    public var body: some View {
//        HStack(spacing: 0) {
//            Color.clear
//                .frame(width: 10)
//                .background(Macro.carb.fillColor(for: colorScheme).gradient)
//            Color.clear
//                .frame(width: 10)
//                .background(Macro.fat.fillColor(for: colorScheme).gradient)
//            Color.clear
//                .frame(width: 10)
//                .background(Macro.protein.fillColor(for: colorScheme).gradient)
//        }
//        .frame(height: 10)
//        .cornerRadius(2)
////        .shadow(color: Color(.systemFill), radius: 1, x: 0, y: 1.5)
//    }
//}
//
