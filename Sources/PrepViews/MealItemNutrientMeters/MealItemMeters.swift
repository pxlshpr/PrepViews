import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepMocks
import SwiftUIPager

public struct MealItemMeters: View {
    
    @StateObject var viewModel: ViewModel
    
    @Binding var foodItem: MealFoodItem
    @Binding var meal: DayMeal
    @Binding var day: Day?
    //    var day: Binding<Day?>
    
    let didTapGoalSetButton: (Bool) -> ()
    
    public init(
        foodItem: Binding<MealFoodItem>,
        meal: Binding<DayMeal>,
        day: Binding<Day?>,
        userUnits: UserUnits,
        bodyProfile: BodyProfile?,
        shouldCreateSubgoals: Bool = true,
        didTapGoalSetButton: @escaping (Bool) -> ()
    ) {
        _foodItem = foodItem
        _meal = meal
        _day = day
        
        let viewModel = ViewModel(
            foodItem: foodItem.wrappedValue,
            meal: meal.wrappedValue,
            day: day.wrappedValue,
            userUnits: userUnits,
            bodyProfile: bodyProfile,
            shouldCreateSubgoals: shouldCreateSubgoals
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        
        self.didTapGoalSetButton = didTapGoalSetButton
        
        
//        var types: [MetersType] = []
//        if meal.wrappedValue.goalSet != nil {
//            types.append(.meal)
//        } else if day.wrappedValue != nil {
//            if let mealsCount = day.wrappedValue?.meals.count, mealsCount > 1 {
//                types.append(.meal)
//            }
//            types.append(.diet)
//        }
//        types.append(.nutrients)
//        _metersTypes = State(initialValue: types)
    }
    
//
//    var determineMetersTypes: [MetersType] {
//        var types: [MetersType] = []
//        if viewModel.shouldShowMealGoals {
//            types.append(.meal)
//        }
//        if viewModel.day != nil {
//            types.append(.diet)
//        }
//        types.append(.nutrients)
//        return types
//    }
//
    public var body: some View {
        Group {
//            arrow
            VStack(spacing: 7) {
                typePickerRow
                header
                pager
                footer
            }
//            .padding(.top, 10)
        }
        .onChange(of: foodItem) { newFoodItem in
            withAnimation {
                viewModel.foodItem = newFoodItem
            }
        }
        .onChange(of: meal) { newValue in
            withAnimation {
                viewModel.meal = meal
            }
        }
        .onChange(of: day) { newValue in
            withAnimation {
                viewModel.day = day
            }
        }
    }
    
    //MARK: Pager
    
    var pager: some View {
        Pager(
            page: viewModel.page,
            data: viewModel.metersTypes,
            id: \.self,
            content: { metersType in
                Meters(metersType)
                    .environmentObject(viewModel)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 17)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
        )
        .pagingPriority(.simultaneous)
        .onPageWillTransition(viewModel.pageWillTransition)
//        .frame(height: 200)
        .frame(height: viewModel.pagerHeight)
    }
    
    var header: some View {
        HStack(alignment: .bottom) {
            Text(viewModel.metersType.headerString)
                .font(.footnote)
                .textCase(.uppercase)
                .padding(.leading, 20)
            Spacer()
            goalSetPicker
        }
        .foregroundColor(Color(.secondaryLabel))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    var typePickerRow: some View {
        if viewModel.metersTypes.count > 1 {
            typePicker
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }
    
    var footer: some View {
        Group {
            switch viewModel.metersType {
            case .nutrients:
                legend
            case .diet:
                if viewModel.hasDiet {
                    legend
                } else {
                    Text("Pick a diet to see your goals for the day.")
                }
            case .meal:
                if viewModel.hasMealType || viewModel.hasDiet {
                    legend
                } else {
                    Text("Pick a diet or meal type to see meal goals for this meal.")
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(.secondaryLabel))
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }
    
    var legend: some View {
        Legend(
//            metersType: $viewModel.metersType,
//            componentsWithTotals: viewModel.componentsWithTotalBinding,
//            componentsFromFood: viewModel.componentsFromFoodBinding,
//            showCompletion: viewModel.showCompletionLegendBinding,
//            showExcess: viewModel.showExcessLegendBinding,
//            showSolidLine: viewModel.showSolidLineLegendBinding,
//            showFirstDashedLine: viewModel.showFirstDashedLineLegendBinding,
//            showSecondDashedLine: viewModel.showSecondDashedLineLegendBinding,
//            showLegend: viewModel.showingLegendBinding
        )
        .environmentObject(viewModel)
    }
    
    var footer_legacy: some View {
        Text(viewModel.metersType.footerString)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(.secondaryLabel))
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .padding(.horizontal, 20)
    }

    var typePicker: some View {
        Picker("", selection: viewModel.metersTypeBinding) {
            ForEach(viewModel.metersTypes, id: \.self) {
                Text($0.description).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var arrow: some View {
        Image(systemName: "arrowshape.forward.fill")
            .rotationEffect(.degrees(90))
            .foregroundColor(Color(.quaternaryLabel))
    }
    
    //MARK: - GoalSet Picker
    @ViewBuilder
    var goalSetPicker: some View {
        switch viewModel.metersType {
        case .nutrients:
            emptyPicker
                .transition(.move(edge: .leading)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        case .diet:
            dietPicker
                .transition(.move(edge: .leading)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        case .meal:
            mealTypePicker
                .transition(.move(edge: .trailing)
                    .combined(with: .opacity)
                    .combined(with: .scale)
                )
        }
    }
    
    var emptyPicker: some View {
        picker().opacity(0)
    }
    
    var dietPicker: some View {
        picker(for: viewModel.day?.goalSet)
    }
    
    var mealTypePicker: some View {
        picker(for: viewModel.meal.goalSet, forMeal: true)
    }
    
    /// We're allowing nil to be passed into this so it can be used as a transparent placeholder
    func picker(for goalSet: GoalSet? = nil, forMeal: Bool = false) -> some View {
        Button {
            didTapGoalSetButton(viewModel.metersType == .meal)
        } label: {
            HStack(spacing: 2) {
                Text(goalSet?.emoji ?? "🫃🏽")
                    .opacity(goalSet == nil ? 0 : 1)
                    .font(.footnote)
                Text(goalSet?.name ?? "Select \(forMeal ? "Meal Type" : "Diet")")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.accentColor)
                    .foregroundColor(Color(.tertiaryLabel))
                    .font(.footnote)
                    .imageScale(.small)
            }
            .padding(.trailing, 20)
        }
    }
    
    func picker_legacy() -> some View {
        HStack(spacing: 2) {
            Text("🫃🏽")
            Text("Cutting")
                .font(.footnote)
                .bold()
                .foregroundColor(.accentColor)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundColor(Color(.tertiaryLabel))
                .font(.footnote)
                .imageScale(.small)
        }
        .padding(.vertical, 5.5)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .foregroundColor(Color(.tertiarySystemFill))
        )
    }
}

//MARK: - MealItemMeters.ViewModel (Legend)

extension MealItemMeters.ViewModel {
    
    var showMealSubgoals: Bool {
        guard metersType == .meal else { return false }
        return currentMeterViewModels.contains {
            $0.isGenerated
        }
    }
    
    var showDietAutoGoals: Bool {
        guard metersType == .diet else { return false }
        return currentMeterViewModels.contains {
            $0.isGenerated
        }
    }

    var showCompletion: Bool {
        currentMeterViewModels.contains {
            $0.percentageType == .complete
        }
    }
    
    var showExcess: Bool {
        currentMeterViewModels.contains {
            $0.percentageType == .excess
        }
    }
    
    var showSolidLine: Bool {
        currentMeterViewModels.contains {
            $0.goalBoundsType == .lowerAndUpper
            && !$0.percentageType.isPastCompletion
        }
    }
    
    var showFirstDashedLine: Bool {
        currentMeterViewModels.contains {
            $0.goalBoundsType == .lowerAndUpper
            &&
            ($0.percentageType == .complete || $0.percentageType == .excess)
        }
    }

    var showSecondDashedLine: Bool {
        currentMeterViewModels.contains {
            $0.goalBoundsType == .lowerAndUpper
            && $0.percentageType == .excess
        }
    }

    var componentsFromFood: [NutrientMeterComponent] {
//        foodItem.food.componentsForLegend
        let viewModelsWithTotal = currentMeterViewModels.filter {
            guard let increment = $0.increment else { return false }
            return increment > 0 && !$0.percentageType.isPastCompletion
        }
        
        /// Get components except for micro first (because there may be multiples of those)
        var components = viewModelsWithTotal
            .filter { !$0.component.isMicro }
            .map { $0.component }
        if viewModelsWithTotal.contains(where: { $0.component.isMicro }) {
            components.append(.micro(nutrientType: .sodium, nutrientUnit: .mg))
        }
        return components
    }
    
    var componentsWithTotals: [NutrientMeterComponent] {
        let viewModelsWithTotal = currentMeterViewModels.filter {
            $0.planned > 0 && !$0.percentageType.isPastCompletion
        }
        
        /// Get components except for micro first (because there may be multiples of those)
        var components = viewModelsWithTotal
            .filter { !$0.component.isMicro }
            .map { $0.component }
        if viewModelsWithTotal.contains(where: { $0.component.isMicro }) {
            components.append(.micro(nutrientType: .sodium, nutrientUnit: .mg))
        }
        return components
    }
    
    var showingLegend: Bool {
        get {
            return UserDefaults.standard.object(forKey: "showingLegend") as? Bool ?? false
        }
        set(newValue) {
            UserDefaults.standard.setValue(newValue, forKey: "showingLegend")
        }
    }
}

extension PercentageType {
    var isPastCompletion: Bool {
        self == .complete || self == .excess
    }
}

extension NutrientMeter.ViewModel {
    var showsRemainderWithoutLowerBound: Bool {
        guard !percentageType.isPastCompletion else { return false }
        guard goalBoundsType != .lowerAndUpper else {
            return goalLower != goalUpper
        }
        return true
    }

    var showsBoundedRemainder: Bool {
        !percentageType.isPastCompletion && goalBoundsType == .lowerAndUpper
    }
}

extension NutrientMeterComponent {
    var isMicro: Bool {
        switch self {
        case .micro:
            return true
        default:
            return false
        }
    }
}

//MARK: Food (Legend)
extension Food {
    var componentsForLegend: [NutrientMeterComponent] {
        var components: [NutrientMeterComponent] = []
        if info.nutrients.energyInKcal > 0 { components.append(.energy) }
        if info.nutrients.carb > 0 { components.append(.carb) }
        if info.nutrients.fat > 0 { components.append(.fat) }
        if info.nutrients.protein > 0 { components.append(.protein) }
        if info.nutrients.micros.contains(where: { $0.value > 0 }) {
            /// Add any micronutrient as legend shows the same color for all
            components.append(.micro(nutrientType: .sodium, nutrientUnit: .mg))
        }
        return components
    }
}

//MARK: - Legend

extension MealItemMeters {
    struct Legend: View {
        
        @Environment(\.colorScheme) var colorScheme
        
        let spacing: CGFloat = 2
        let colorSize: CGFloat = 10
        let cornerRadius: CGFloat = 2
        
        let barCornerRadius: CGFloat = 3.5
        let barHeight: CGFloat = 14

        @EnvironmentObject var viewModel: ViewModel
        @State var showingLegend: Bool = false
    }
}

extension MealItemMeters.Legend {
    
    var body: some View {
        VStack(alignment: .leading) {
            legendButton
            if showingLegend {
                grid
            }
        }
        .onAppear { showingLegend = viewModel.showingLegend }
    }
    
    var legendButton: some View {
        HStack(spacing: 5) {
            Text("\(showingLegend ? "Hide" : "Show") Legend")
            Image(systemName: "chevron.right")
                .rotationEffect(showingLegend ? .degrees(90) : .degrees(0))
                .font(.caption2)
                .imageScale(.small)
        }
        .foregroundColor(showingLegend ? .accentColor : .secondary)
        .onTapGesture {
            withAnimation {
                showingLegend.toggle()
                /// Set the binding too so it's saved to `UserDefaults`
                viewModel.showingLegend = showingLegend
            }
        }
    }
    
    var totalText: Text {
        var relativeColor: String {
            return colorScheme == .light ? "lighter" : "darker"
        }
        switch viewModel.metersType {
        case .nutrients, .diet:
            return Text("**Today's** total (\(relativeColor))")
        case .meal:
            return Text("This **meal's** total (\(relativeColor))")
        }
    }
    
    var foodText: Text {
        var relativeColor: String {
            return colorScheme == .light ? "darker" : "lighter"
        }
        return Text("What this **food** adds (\(relativeColor))")
    }
    
    var unboundedRemainderText: some View {
        VStack(alignment: .leading) {
            Text("Remainder till your RDA* is reached:")
            HStack(spacing: 2) {
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Text("If the bar is in green, this is your **upper limit**")
            }
            HStack(spacing: 2) {
                Text("•")
                    .foregroundColor(Color(.quaternaryLabel))
                Text("Otherwise, it's your **minimum**")
            }
        }
    }
    
    var boundedRemainderText: some View {
        var goalDescription: String {
            switch viewModel.metersType {
            case .nutrients:
                return "RDA*"
            case .meal:
                return "meal goals"
            case .diet:
                return "daily goals"
            }
        }

        var showMinimumGoal: Bool {
            viewModel.showFirstDashedLine || viewModel.showSolidLine
        }
        
        return Group {
            VStack(alignment: .leading, spacing: 3) {
//                Text("Lines marking your \(goalDescription)")
                if showMinimumGoal {
                    HStack(alignment: .top, spacing: 2) {
                        if viewModel.showSecondDashedLine {
                            Text("•")
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        if viewModel.showFirstDashedLine && viewModel.showSolidLine {
                            if viewModel.showSecondDashedLine {
                                Text("Solid or first dotted lines indicate **minimum** \(goalDescription)")
                            } else {
                                Text("Solid or dotted lines indicate **minimum** \(goalDescription)")
                            }
                        } else if viewModel.showFirstDashedLine {
                            if viewModel.showSecondDashedLine {
                                Text("First dotted lines indicate **minimum** \(goalDescription)")
                            } else {
                                Text("Dotted lines indicate **minimum** \(goalDescription)")
                            }
                        } else if viewModel.showSolidLine {
                            Text("Lines indicate **minimum** \(goalDescription)")
                        }
                    }
                }
                
                if viewModel.showSecondDashedLine {
                    HStack(spacing: 2) {
                        if showMinimumGoal {
                            Text("•")
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        Text("Second dotted lines indicate **upper limits**")
                    }
                }
            }
        }
    }
    
    var completeGoalsText: Text {
        switch viewModel.metersType {
        case .nutrients:
            return Text("RDA* met")
        case .meal:
            return Text("Meal goal met")
        case .diet:
            return Text("Daily goal met")
        }
    }
    
    var excessGoalsText: Text {
        Text("Upper limit exceeded")
    }
    
    var grid: some View {
        func goalCompletionBar(isExcess: Bool) -> some View {
            var fillColor: Color {
                isExcess
                ? NutrientMeter.ViewModel.Colors.Excess.fill
                : NutrientMeter.ViewModel.Colors.Complete.fill
            }
            
            var placeholderColor: Color {
                isExcess
                ? NutrientMeter.ViewModel.Colors.Excess.placeholder
                : NutrientMeter.ViewModel.Colors.Complete.placeholder
            }
            
            var text: Text {
                isExcess
                ? excessGoalsText
                : completeGoalsText
            }
            
            return GridRow {
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(fillColor.gradient)
                        if !viewModel.componentsWithTotals.isEmpty {
                            RoundedRectangle(cornerRadius: barCornerRadius)
                                .fill(placeholderColor.gradient)
                                .frame(width: barWidth / 2.0)
                        }
                    }
                }
                .frame(width: barWidth, height: barHeight)
                .cornerRadius(barCornerRadius)
                text
            }
        }
        
        @ViewBuilder
        var totalRow: some View {
            if !viewModel.componentsWithTotals.isEmpty {
                GridRow {
                    totalColors
                    totalText
                }
            }
        }
        
        @ViewBuilder
        var foodRow: some View {
            if !viewModel.componentsFromFood.isEmpty {
                GridRow {
                    foodColors
                    foodText
                }
            }
        }
        
        var showLinesRow: Bool {
            viewModel.showSolidLine ||
            viewModel.showFirstDashedLine ||
            viewModel.showSecondDashedLine
        }
        
        var showDashedLine: Bool {
            viewModel.showFirstDashedLine ||
            viewModel.showSecondDashedLine
        }
        
        @ViewBuilder
        var linesRow: some View {
            if showLinesRow {
                GridRow(alignment: .top) {
//                GridRow {
                    ZStack(alignment: .leading) {
                        NutrientMeter.ViewModel.Colors.Empty.fill
                            .frame(width: barWidth, height: barHeight)
                            .cornerRadius(barCornerRadius)
                        if viewModel.showSolidLine {
                            DottedLine()
                                .stroke(style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [100])
                                )
                                .frame(width: 1)
                                .foregroundColor(Color(.systemGroupedBackground))
                                .offset(x: (barWidth / (showDashedLine ? 3.0 : 2.0)) - 1.0)
                        }
                        if viewModel.showFirstDashedLine || viewModel.showSecondDashedLine {
                            DottedLine()
                                .stroke(style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [2])
                                )
                                .frame(width: 1)
                                .foregroundColor(Color(.systemGroupedBackground))
                                .offset(x: (barWidth / (viewModel.showSolidLine ? 1.5 : 2.0)) - 1.0)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: 1)
                    boundedRemainderText
                }
            }
        }
        
        @ViewBuilder
        var completionRow: some View {
            if viewModel.showCompletion {
                goalCompletionBar(isExcess: false)
            }
        }
        
        @ViewBuilder
        var excessRow: some View {
            if viewModel.showExcess {
                goalCompletionBar(isExcess: true)
            }
        }
        
        @ViewBuilder
        var rdaExplanation: some View {
            if viewModel.metersType == .nutrients && showLinesRow {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("*")
                        .font(.callout)
                        .offset(y: 3)
                    Text("**Recommended Dietary Allowance (RDA)**: Average daily level of intake sufficient to meet your nutrient requirements. [You can customise this in settings.](http://something.com)")
                }
            }
        }
        
        @ViewBuilder
        var generatedGoals: some View {
            if viewModel.showMealSubgoals || viewModel.showDietAutoGoals {
                GridRow {
                    Group {
                        HStack {
                            Spacer()
                            Image(systemName: "sparkles")
                        }
                        .frame(width: barWidth)
                        if viewModel.showMealSubgoals {
                            Text("Generated by remaning goal ÷ unplanned meals")
                        } else {
                            Text("Generated using energy equation")
                        }
                    }
                    .padding(.top, 5)
                }
            }
        }
        
        return VStack(alignment: .leading) {
            Grid(alignment: .leading) {
                totalRow
                foodRow
                completionRow
                excessRow
                linesRow
                generatedGoals
            }
            rdaExplanation
        }
    }
    
    var maxColorCount: Int {
        var count = max(viewModel.componentsWithTotals.count, viewModel.componentsFromFood.count)
        if viewModel.showExcess { count += 1 }
        if viewModel.showCompletion { count += 1 }
        return count
    }
    var barWidth: CGFloat {
        let MinimumBarWidth: CGFloat = colorSize * 2
        let count = CGFloat(maxColorCount)
        let calculated = (count * colorSize) + ((count - 1) * spacing)
        return max(MinimumBarWidth, calculated)
    }
    
    var totalColors: some View {
        HStack(spacing: spacing) {
            ForEach(viewModel.componentsWithTotals, id: \.self) {
                colorBox($0.preppedColor)
            }
            if viewModel.showCompletion {
                colorBox(NutrientMeter.ViewModel.Colors.Complete.placeholder)
            }
            if viewModel.showExcess {
                colorBox(NutrientMeter.ViewModel.Colors.Excess.placeholder)
            }
        }
    }
    
    var foodColors: some View {
        HStack(spacing: spacing) {
            ForEach(viewModel.componentsFromFood, id: \.self) {
                colorBox($0.eatenColor)
            }
            if viewModel.showCompletion {
                colorBox(NutrientMeter.ViewModel.Colors.Complete.fill)
            }
            if viewModel.showExcess {
                colorBox(NutrientMeter.ViewModel.Colors.Excess.fill)
            }
        }
    }
    
    func colorBox(_ color: Color) -> some View {
        color
            .frame(width: colorSize, height: colorSize)
            .cornerRadius(cornerRadius)
    }
}


//MARK: - 👁‍🗨 Previews
import SwiftUISugar
import PrepDataTypes
import PrepMocks

public struct MealItemNutrientMetersPreview: View {
    
    public init() { }
    
    public var body: some View {
        NavigationView {
            FormStyledScrollView {
                textFieldSection
                metersSection
            }
            .navigationTitle("Log Food")
        }
    }
    
    var mockMeals: [DayMeal] {
        [
//            DayMeal(
//                name: "Breakfast",
//                time: 0,
//                goalSet: nil,
//                foodItems: []
//            ),
//            DayMeal(
//                name: "Lunch",
//                time: 0,
//                goalSet: nil,
//                foodItems: []
//            ),
//            DayMeal(
//                name: "Dinner",
//                time: 0,
//                goalSet: nil,
//                foodItems: []
//            ),
//            DayMeal(
//                name: "Supper",
//                time: 0,
//                goalSet: nil,
//                foodItems: [
//                    MealFoodItem(
//                        food: FoodMock.wheyProtein,
//                        amount: FoodValue(30, .g)
//                    )
//                ]
//            )
        ]
    }
    
    var mockDay: Day {
        Day(
            id: Date().calendarDayString,
            calendarDayString: Date().calendarDayString,
            goalSet: DietMock.cutting,
//            goalSet: nil,
            bodyProfile: BodyProfileMock.calculated,
            meals: mockMeals,
            syncStatus: .notSynced,
            updatedAt: 0
        )
    }
    
    var metersSection: some View {
        MealItemMeters(
            foodItem: foodItemBinding,
            meal: mealBinding,
            day: .constant(mockDay),
            userUnits: .standard,
            bodyProfile: BodyProfileMock.calculated,
            didTapGoalSetButton: { forMeal in
                
            }
        )
    }
    
    var mealBinding: Binding<DayMeal> {
        Binding<DayMeal>(
            get: {
                DayMeal(from: MealMock.preWorkoutWithItems)
//                DayMeal(
//                    name: "Temp meal",
//                    time: 0,
//                    goalSet: nil
//                )
            },
            set: { _ in }
        )
    }
    
    var foodItemBinding: Binding<MealFoodItem> {
        Binding<MealFoodItem>(
            get: {
                MealFoodItem(
                    food: FoodMock.wheyProtein,
                    amount: FoodValue(value: value ?? 0, unitType: .weight, weightUnit: weightUnit)
                )
            },
            set: { _ in }
        )
    }
    
    @State var weightUnit: WeightUnit = .g
    @State var value: Double? = 500
    @State var valueString: String = "500"

    var valueBinding: Binding<String> {
        Binding<String>(
            get: { valueString },
            set: { newValue in
                guard !newValue.isEmpty else {
                    value = nil
                    valueString = newValue
                    return
                }
                guard let value = Double(newValue) else {
                    return
                }
                self.value = value
                withAnimation {
                    self.valueString = newValue
                }
            }
        )
    }
    
    var textFieldSection: some View {
        var unitPicker: some View {
            Button {
                weightUnit = weightUnit == .g ? .oz : .g
            } label: {
                HStack(spacing: 5) {
                    Text(weightUnit == .g ? "g" : "oz")
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
            }
            .buttonStyle(.borderless)
        }
        
        return FormStyledSection(header: Text("Weight")) {
            HStack {
                TextField("Required", text: valueBinding)
                    .keyboardType(.decimalPad)
                unitPicker
            }
        }
    }

}

struct MealItemNutrientMeters_Previews: PreviewProvider {
    static var previews: some View {
        MealItemNutrientMetersPreview()
    }
}
