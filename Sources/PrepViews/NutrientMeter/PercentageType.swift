public enum PercentageType {
    case empty, regular, complete, excess

//    static var cutoff: Double {
//        return PercentageType.CompletionCutOffPercentage/100.0
//    }
}

public extension PercentageType {
    init(_ value: Double) {
        if value == 0 {
            self = .empty
        } else if value == 1.0 {
            self = .complete
        } else if value > 1.0 {
            self = .excess
        } else {
            self = .regular
        }
    }
    
    /// Legacy init that was used with a cutoff to allow for completions to be registered close to the end (above or below it)
    /// We stopped using this after employing the new bound-based goals
//    init(_ value: Double) {
//        let CompletionCutOffPercentage: Double = 5
//        let cutoff = CompletionCutOffPercentage/100.0
//        let lowerCompletionBound = 1 - cutoff
//        let upperCompletionBound = 1 + cutoff
//
//        if value == 0 {
//            self = .empty
//        } else if value >= lowerCompletionBound && value <= upperCompletionBound {
//            self = .complete
//        } else if value > upperCompletionBound {
//            self = .excess
//        } else {
//            self = .regular
//        }
//    }
}
