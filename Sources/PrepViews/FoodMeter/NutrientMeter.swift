import SwiftUI

public struct NutrientMeter: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: NutrientMeter.ViewModel
    
//    @Binding var goal: Double
//    @Binding var food: Double
//    var burned: Binding<Double>?
//    var eaten: Binding<Double>?
//    var increment: Binding<Double>?
//    var includeBurned: Binding<Bool>?

    //TODO: Rename this to style
//    @State var type: FoodMeterComponent
    @State private var hasAppeared = false
    
    public init(viewModel: NutrientMeter.ViewModel) {
        self.viewModel = viewModel
    }
}

public extension NutrientMeter {
    var body: some View {
        GeometryReader { proxy -> AnyView in
            return AnyView(
                capsulesPrototype(proxy)
            )
        }
        //TODO: Rewrite this
//        .if(hasAppeared, transform: { view in
//            /// Use this to make sure the animation only gets applied after the view has appeared, so that it doesn't animate it during it being transitioned into view
//            view
//                .animation(animation, value: eaten)
//        })
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
        }
        
        var eatenCapsule: some View {
            shape
                .fill(viewModel.eatenColor.gradient)
                .frame(width: eatenWidth(proxy: proxy))
        }

        var incrementCapsule: some View {
            shape
                .fill(viewModel.incrementColor.gradient)
                .frame(width: incrementWidth(proxy: proxy))
        }

        return ZStack(alignment: .leading) {
            placeholderCapsule
            incrementCapsule
            preppedCapsule
            eatenCapsule
        }
    }
    
    //MARK: - Accessors
    var food: Double {
        viewModel.planned
    }
    
    //MARK: - 📐 Widths
    func preppedWidth(for proxy: GeometryProxy) -> Double {
        
        proxy.size.width * viewModel.preppedPercentageForMeter

//        if let increment = increment?.wrappedValue,
//           totalGoal + increment > 0,
//           food / (totalGoal + increment) > preppedPercentage
//        {
//            percentage = food / (food + increment)
//        } else {
//            percentage = preppedPercentage
//        }
//        return proxy.size.width * percentage
    }
    
    func eatenWidth(proxy: GeometryProxy) -> Double {
        proxy.size.width * viewModel.eatenPercentage
//        (preppedWidth(proxy: proxy) * eatenPercentage) + preppedWidth(proxy: proxy)
    }
    
    func incrementWidth(proxy: GeometryProxy) -> Double {
        proxy.size.width * viewModel.incrementPercentageForMeter
    }

    //MARK: - % Percentages
   

    //MARK: - 🎨 Colors
    var placeholderColor: Color {
//        return PrepColor.statsEmptyFill.forColorScheme(colorScheme)
        return Colors.placeholder
        
        
//        switch preppedPercentageType {
//        case .complete:
//            if prepped > 1.0 {
//                return Color("StatsCompleteFill")
//                    .brighter(by: 120)
//                    .opacity(0.4)
//            } else {
//                return Color("StatsEmptyFill")
//            }
//        case .excess:
//            return Color("StatsExcessFill")
//                .brighter(by: 120)
//                .opacity(0.4)
//        default:
//            return Color("StatsEmptyFill")
//        }
    }
    

    //MARK: - 🎞 Animations
    var animation: Animation {
        .default
        //TODO: Rewrite this
//        if eaten <= 0.05 || eaten >= 0.95 {
//            /// don't bounce the bar if we're going to 0 or going close to 1
//            return .interactiveSpring()
//        } else {
//            return .interactiveSpring(response: 0.35, dampingFraction: 0.66, blendDuration: 0.35)
//        }
    }
    
    //MARK: - Enums
    struct Colors {
        static let placeholder = Color("StatsEmptyFill", bundle: .module)
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
    @State var previewType: PreviewType = .eaten

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
                goal: dataSet[gridIndex][i].goal,
                burned: 0,
                food: dataSet[gridIndex][i].prepped,
                increment: dataSet[gridIndex][i].increment
            )
        } else {
            return NutrientMeter.ViewModel(
                component: dataSet[gridIndex][i].type,
                goal: dataSet[gridIndex][i].goal,
                burned: 0,
                food: dataSet[gridIndex][i].prepped,
                eaten: dataSet[gridIndex][i].eaten
            )
        }
    }
    
    func foodMeter(gridIndex: Int, rowIndex i: Int, type: PreviewType) -> some View {
        let viewModel = viewModel(gridIndex: gridIndex, rowIndex: i, previewType: type)
        if !includeGoal {
            viewModel.goal = nil
        }
        return NutrientMeter(viewModel: viewModel)
        .frame(height: 26)
    }
}

struct FoodMeter_Previews: PreviewProvider {
    static var previews: some View {
        FoodMeterPreviewView()
    }
}
