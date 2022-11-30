import SwiftUI

public struct NutrientMeter: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var viewModel: NutrientMeter.ViewModel
    
    @State private var hasAppeared = false
    
    public init(viewModel: Binding<NutrientMeter.ViewModel>) {
        _viewModel = viewModel
    }
}

public extension NutrientMeter {
    var body: some View {
        GeometryReader { proxy -> AnyView in
            return AnyView(
                capsulesPrototype(proxy)
            )
        }
        .clipShape(
            shape
        )
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasAppeared = true
            }
        }
    }

    var shape: some Shape {
        RoundedRectangle(cornerRadius: 5)
//            Capsule()
    }
    

    func capsulesPrototype(_ proxy: GeometryProxy) -> some View {
        
        var placeholderCapsule: some View {
            shape
                .fill(placeholderColor)
        }
        
        var preppedCapsule: some View {
            shape
                .fill(viewModel.preppedColor.gradient)
                .frame(width: preppedWidth(for: proxy))
                .if(hasAppeared, transform: { view in
                    /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
                    view
                        .animation(animation, value: viewModel.eaten)
                        .animation(animation, value: viewModel.increment)
                })
        }
        
        var eatenCapsule: some View {
            shape
                .fill(viewModel.eatenColor.gradient)
                .frame(width: eatenWidth(proxy: proxy))
                .if(hasAppeared, transform: { view in
                    /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
                    view
                        .animation(animation, value: viewModel.eaten)
                        .animation(animation, value: viewModel.increment)
                })
        }

        var incrementCapsule: some View {
            shape
                .fill(viewModel.incrementColor.gradient)
                .frame(width: incrementWidth(proxy: proxy))
                .if(hasAppeared, transform: { view in
                    /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
                    view
                        .animation(animation, value: viewModel.eaten)
                        .animation(animation, value: viewModel.increment)
                })
        }
        
        @ViewBuilder
        var lowerGoalMark: some View {
            if viewModel.shouldShowLowerGoalMark {
                DottedLine()
                    .stroke(style: StrokeStyle(
                        lineWidth: viewModel.lowerGoalMarkLineWidth,
                        dash: [viewModel.lowerGoalMarkDash])
                    )
                    .frame(width: 1)
                    .foregroundColor(viewModel.lowerGoalMarkColor)
                    .opacity(viewModel.lowerGoalMarkOpacity)
                    .offset(x: lowerGoalMarkOffset(for: proxy))
            }
        }

        @ViewBuilder
        var upperGoalMark: some View {
            if viewModel.shouldShowUpperGoalMark {
                DottedLine()
                    .stroke(style: StrokeStyle(
                        lineWidth: viewModel.upperGoalMarkLineWidth,
                        dash: [viewModel.upperGoalMarkDash])
                    )
                    .frame(width: 1)
                    .foregroundColor(viewModel.upperGoalMarkColor)
                    .opacity(viewModel.upperGoalMarkOpacity)
                    .offset(x: upperGoalMarkOffset(for: proxy))
            }
        }

        return ZStack(alignment: .leading) {
            placeholderCapsule
            incrementCapsule
            preppedCapsule
            eatenCapsule
            lowerGoalMark
            upperGoalMark
        }
    }
    
    //MARK: - Accessors
    var food: Double {
        viewModel.planned
    }
    
    //MARK: - 📐 Widths
    /// If it's not at 0, return a minimum to account for the corner width
    func correctedWidth(_ width: Double) -> Double {
        guard width != 0 else { return width }
        return max(width, 5)
    }
    func preppedWidth(for proxy: GeometryProxy) -> Double {
        correctedWidth(proxy.size.width * viewModel.preppedPercentageForMeter)
    }
    
    func eatenWidth(proxy: GeometryProxy) -> Double {
        correctedWidth(proxy.size.width * viewModel.eatenPercentage)
    }
    
    func incrementWidth(proxy: GeometryProxy) -> Double {
        correctedWidth(proxy.size.width * viewModel.incrementPercentageForMeter)
    }
    
    func lowerGoalMarkOffset(for proxy: GeometryProxy) -> Double {
        (proxy.size.width * viewModel.lowerGoalPercentage) - 1.0
    }

    func upperGoalMarkOffset(for proxy: GeometryProxy) -> Double {
        (proxy.size.width * viewModel.upperGoalPercentage) - 1.0
    }

    //MARK: - 🎨 Colors
    var placeholderColor: Color {
        Colors.placeholder
    }

    //MARK: - 🎞 Animations
    var animation: Animation {
        
//        .default
        
        let shouldBounce = !viewModel.isCloseToEdges || !viewModel.haveGoal
        if shouldBounce {
            return .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)
        } else {
            /// don't bounce the bar if we're going to 0 or going close to 1
            return .interactiveSpring()
        }
    }
    
    //MARK: - Enums
    struct Colors {
        static let placeholder = Color("StatsEmptyFill", bundle: .module)
    }
}

extension NutrientMeter.ViewModel {
    
    var isCloseToEdges: Bool {
        if showingIncrement {
            return incrementPercentage <= 0.05 || incrementPercentage >= 0.95
        } else {
            return eatenPercentage <= 0.05 || eatenPercentage >= 0.95
        }
    }
    
    var shouldShowLowerGoalMark: Bool {
        switch goalBoundsType {
            
        case .lowerAndUpper:
            /// Show as long as its not at 100%
            return lowerGoalPercentage < 1.0
//            /// Always shows
//            return true
            
        case .lowerOnly:
            /// Shows if the endPoint exceeds the lower mark
            guard let goalLower else { return false }
            return endPoint > goalLower
            
        default:
            return false
        }
    }
    
    var shouldShowUpperGoalMark: Bool {
        switch goalBoundsType {
            
        case .lowerAndUpper, .upperOnly:
            /// Shows if the endPoint exceeds the upper mark
            guard let goalUpper else { return false }
            return endPoint > goalUpper
            
        default:
            return false
        }
    }
    var preppedPercentageType: PercentageType {
        let defaultType = PercentageType(preppedPercentage)
        switch goalBoundsType {
        case .none, .lowerOnly:
            return preppedPercentage < 1 ? defaultType : .complete
        case .upperOnly:
            return preppedPercentage < 1 ? .complete : .excess
        case .lowerAndUpper:
            guard let goalLower, let goalUpper else { return defaultType }
            if planned < goalLower {
                return defaultType
            } else if planned < goalUpper {
                return .complete
            } else {
                return .excess
            }
        }
    }
    
    var incrementPercentageType: PercentageType {
        guard let increment else { return .regular }
        let defaultType = PercentageType(incrementPercentage)
        switch goalBoundsType {
        case .none, .lowerOnly:
            return incrementPercentage < 1 ? defaultType : .complete
        case .upperOnly:
            return incrementPercentage < 1 ? .complete : .excess
        case .lowerAndUpper:
            guard let goalLower, let goalUpper else { return defaultType }
            if planned + increment < goalLower {
                return defaultType
            } else if planned + increment < goalUpper {
                return .complete
            } else {
                return .excess
            }
        }
    }

    var incrementPercentage: Double {
        guard let increment = increment else { return 0 }
        guard totalGoal != 0 else {
            return 1
        }
        return (increment + planned) / totalGoal
    }
    
    var incrementPercentageForMeter: Double {
        incrementPercentage
    }
    
    var incrementPercentageForMeter_legacy: Double {
        guard let increment = increment, increment > 0 else { return 0 }
        //        guard let increment = increment?.wrappedValue, totalGoal != 0 else { return 0 }
        
        guard totalGoal != 0 else {
            return 1
        }
        
        /// Choose greater of goal or "prepped + increment"
        let total: Double
        if planned + increment > totalGoal {
            total = planned + increment
        } else {
            total = totalGoal
        }
        
        return ((increment / total) + preppedPercentage)
    }
    
    
    var endPoint: Double {
        if let increment {
            return planned + increment
        } else {
            return planned
        }
    }
    
    //MARK: Lower Goal
    var lowerGoalPercentage: CGFloat {
        guard let goalLower else { return 0 }
        //TODO: Possibly remove this redundant conditional by always using endPoint instead
        if let goalUpper, goalUpper > 0 {
            return goalLower / max(goalUpper, endPoint)
        } else {
            guard endPoint > 0 else { return 0}
            return goalLower / endPoint
        }
    }
    var lowerGoalMarkColor: Color {
        Color(.systemGroupedBackground)
//        Color.white
//        Color(.label)
//        let percentageType = showingIncrement ? incrementPercentageType : preppedPercentageType
//        switch percentageType {
//        case .excess:
//            return Colors.Excess.text
//        default:
//            return Colors.Complete.text
//        }
    }
    
    var lowerGoalMarkOpacity: CGFloat {
        lowerGoalMarkOverBar ? 0.5 : 1.0
    }
    
    var lowerGoalMarkLineWidth: CGFloat {
        lowerGoalMarkOverBar ? 1 : 1.5
    }
    
    var lowerGoalMarkOverBar: Bool {
        guard let goalLower else { return false }
        return goalLower < endPoint
    }
    
    var lowerGoalMarkDash: CGFloat {
        lowerGoalMarkOverBar ? 2 : 100
    }
    
    //MARK: Upper Goal
    
    var upperGoalPercentage: CGFloat {
        guard let goalUpper, endPoint > 0 else { return 0 }
        return goalUpper / endPoint
    }
    var upperGoalMarkColor: Color {
        Color(.systemGroupedBackground)
//        Color.white
//        Color(.label)
//        let percentageType = showingIncrement ? incrementPercentageType : preppedPercentageType
//        switch percentageType {
//        case .excess:
//            return Colors.Excess.text
//        default:
//            return Colors.Complete.text
//        }
    }
    
    var upperGoalMarkOpacity: CGFloat {
        upperGoalMarkOverBar ? 0.5 : 1.0
    }
    
    var upperGoalMarkLineWidth: CGFloat {
        upperGoalMarkOverBar ? 1 : 1.5
    }
    
    var upperGoalMarkOverBar: Bool {
        guard let goalUpper else { return false }
        return goalUpper < endPoint
    }
    
    var upperGoalMarkDash: CGFloat {
        upperGoalMarkOverBar ? 2 : 100
    }
}

//MARK: - 📲 Preview
public struct FoodMeterPreviewView: View {
    
    enum MeterType {
        case eaten
        case increment
    }
    
    typealias EatenValues = (type: NutrientMeterComponent, goal: Double, prepped: Double, eaten: Double, increment: Double)
    @State var gridTitles: [String] = [
        "Standard",
        "Complete",
        "Excess"
    ]
    
    @State var gridDataPlanned: [[EatenValues]] = [
        [
            (type: .energy, goal: 1596, prepped: 1000, eaten: 0, increment: 0),
            (type: .carb, goal: 696, prepped: 600, eaten: 0, increment: 0),
            (type: .fat, goal: 1596, prepped: 1000, eaten: 0, increment: 0),
            (type: .protein, goal: 1596, prepped: 1000, eaten: 0, increment: 0),
        ],
        [
            (type: .energy, goal: 1596, prepped: 1596, eaten: 0, increment: 0),
            (type: .carb, goal: 200, prepped: 190, eaten: 0, increment: 0),
            (type: .fat, goal: 44, prepped: 45, eaten: 0, increment: 0),
            (type: .protein, goal: 220, prepped: 215, eaten: 0, increment: 0),
        ],
        [
            (type: .energy, goal: 1596, prepped: 2800, eaten: 0, increment: 0),
            (type: .carb, goal: 200, prepped: 320, eaten: 0, increment: 0),
            (type: .fat, goal: 44, prepped: 100, eaten: 0, increment: 0),
            (type: .protein, goal: 220, prepped: 1000, eaten: 0, increment: 0),
        ]
    ]
    
    @State var gridDataEaten: [[EatenValues]] = [
        [
            (type: .energy, goal: 1596, prepped: 1000, eaten: 600, increment: 0),
            (type: .carb, goal: 696, prepped: 600, eaten: 300, increment: 0),
            (type: .fat, goal: 1596, prepped: 1000, eaten: 600, increment: 0),
            (type: .protein, goal: 1596, prepped: 1000, eaten: 600, increment: 0),
        ],
        [
            (type: .energy, goal: 1596, prepped: 1596, eaten: 500, increment: 0),
            (type: .carb, goal: 200, prepped: 190, eaten: 100, increment: 0),
            (type: .fat, goal: 44, prepped: 45, eaten: 43, increment: 0),
            (type: .protein, goal: 220, prepped: 215, eaten: 212, increment: 0),
        ],
        [
            (type: .energy, goal: 1596, prepped: 2800, eaten: 2000, increment: 0),
            (type: .carb, goal: 200, prepped: 320, eaten: 100, increment: 0),
            (type: .fat, goal: 44, prepped: 100, eaten: 12, increment: 0),
            (type: .protein, goal: 220, prepped: 1000, eaten: 600, increment: 0),
        ]
    ]
    
    @State var gridDataIncrement: [[EatenValues]] = [
        [
            (type: .energy, goal: 1596, prepped: 1200, eaten: 0, increment: 100),
            (type: .carb, goal: 300, prepped: 200, eaten: 0, increment: 50),
            (type: .fat, goal: 44, prepped: 20, eaten: 0, increment: 10),
            (type: .protein, goal: 220, prepped: 100, eaten: 0, increment: 65),
        ],
        [
            (type: .energy, goal: 1596, prepped: 1396, eaten: 0, increment: 200),
            (type: .carb, goal: 300, prepped: 200, eaten: 0, increment: 95),
            (type: .fat, goal: 44, prepped: 20, eaten: 0, increment: 26),
            (type: .protein, goal: 220, prepped: 10, eaten: 0, increment: 208),
        ],
        [
            (type: .energy, goal: 1596, prepped: 1200, eaten: 0, increment: 500),
            (type: .carb, goal: 300, prepped: 200, eaten: 0, increment: 300),
            (type: .fat, goal: 44, prepped: 20, eaten: 0, increment: 40),
            (type: .protein, goal: 220, prepped: 100, eaten: 0, increment: 400),
        ]
    ]
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationView {
            scrollView
                .toolbar { navigationTitleToolbarContent }
                .toolbar { bottomContent }
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @State var includeGoal: Bool = true
    
    var bottomContent: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Picker("", selection: $includeGoal) {
                Text("With Goal").tag(true)
                Text("Without Goal").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }
    
//    @State var previewType: PreviewType = .planned
    @State var previewType: PreviewType = .increment

    var navigationTitleToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            Picker("", selection: $previewType) {
                ForEach(PreviewType.allCases, id: \.self) { previewType in
//                ForEach([PreviewType.eaten], id: \.self) { previewType in
                    Text(previewType.rawValue).tag(previewType.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    enum PreviewType: String, CaseIterable {
        case planned = "Planned"
        case eaten = "Eaten"
        case increment = "Increment"
    }
    
    var scrollView: some View {
        scrollView(type: previewType)
    }
    
    func scrollView(type: PreviewType) -> some View {
        ScrollView(showsIndicators: false) {
            VStack {
                ForEach(Array(gridTitles.indices), id: \.self) { gridIndex in
//                ForEach([2], id: \.self) { gridIndex in
                    VStack(alignment: .leading) {
                        Text(gridTitles[gridIndex])
                            .font(.title2)
                            .fontWeight(.bold)
                        Grid {
                            ForEach(0...3, id: \.self) { i in
                                GridRow {
                                    Text(gridDataPlanned[gridIndex][i].type.description)
                                    foodMeter(gridIndex: gridIndex, rowIndex: i, type: previewType)
                                }
                            }
                        }
                    }
                }
            }
            .padding(50)
        }
    }
    
    func gridData(for previewType: PreviewType) -> [[EatenValues]] {
        switch previewType {
        case .eaten:
            return gridDataEaten
        case .increment:
            return gridDataIncrement
        case .planned:
            return gridDataPlanned
        }
    }
    
    func viewModel(gridIndex: Int, rowIndex i: Int, previewType: PreviewType) -> NutrientMeter.ViewModel {
        let dataSet = gridData(for: previewType)
        if previewType == .increment {
            return NutrientMeter.ViewModel(
                component: dataSet[gridIndex][i].type,
                goalLower: dataSet[gridIndex][i].goal,
                goalUpper: dataSet[gridIndex][i].goal + 200,
                burned: 0,
                planned: dataSet[gridIndex][i].prepped,
                increment: dataSet[gridIndex][i].increment
            )
        } else {
            return NutrientMeter.ViewModel(
                component: dataSet[gridIndex][i].type,
                goalLower: dataSet[gridIndex][i].goal,
                goalUpper: dataSet[gridIndex][i].goal + 100,
                burned: 0,
                planned: dataSet[gridIndex][i].prepped,
                eaten: dataSet[gridIndex][i].eaten
            )
        }
    }
    
    func foodMeter(gridIndex: Int, rowIndex i: Int, type: PreviewType) -> some View {
        var viewModel = viewModel(gridIndex: gridIndex, rowIndex: i, previewType: type)
        if !includeGoal {
            viewModel.goalLower = nil
        }
        return NutrientMeter(viewModel: .constant(viewModel))
        .frame(height: 26)
    }
}

struct FoodMeter_Previews: PreviewProvider {
    static var previews: some View {
        FoodMeterPreviewView()
    }
}
