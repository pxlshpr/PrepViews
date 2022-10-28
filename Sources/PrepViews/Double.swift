import Foundation

extension Double {
    
    var formattedWithKorM: String {
        if self >= 100000 {
            return "\((self/1000000.0).rounded(toPlaces: 1).clean)m"
        } else if self >= 1000 {
            return "\((self/1000.0).rounded(toPlaces: 1).clean)k"
        } else {
            return "\(self.clean)"
        }
    }
    
    var formattedNutritionViewMacro: String {
        if self >= 1000 {
            return formattedWithKorM
        } else {
            return "\(Int(ceil(self)))"
        }
    }
    
    var formattedServings: String {
        if self >= 1000 {
            return formattedWithKorM
        } else {
            return "\(self.clean)"
        }
    }
}
