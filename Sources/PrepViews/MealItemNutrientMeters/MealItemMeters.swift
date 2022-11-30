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
        
        
        var types = [MetersType.nutrients]
        if day.wrappedValue != nil {
            types.append(.diet)
            if let mealsCount = day.wrappedValue?.meals.count, mealsCount > 1 {
                types.append(.meal)
            }
        } else if meal.wrappedValue.goalSet != nil {
            types.append(.meal)
        }
        _metersTypes = State(initialValue: types)
    }
    
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
                viewModel.recalculateHeight()
//                viewModel.foodItem.amount = newFoodItem.amount
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
                metersTypes = determineMetersTypes
            }
        }
    }
    
    @State var metersTypes: [MetersType] = []
    
    var determineMetersTypes: [MetersType] {
        var types = [MetersType.nutrients]
        if viewModel.day != nil {
            types.append(.diet)
        }
        if viewModel.shouldShowMealGoals {
            types.append(.meal)
        }
        return types
    }
    
    //MARK: Pager
    
    var pager: some View {
        Pager(
            page: viewModel.page,
            data: metersTypes,
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
        if metersTypes.count > 1 {
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
            metersType: $viewModel.metersType,
            componentsWithTotals: viewModel.componentsWithTotalBinding,
            componentsFromFood: viewModel.componentsFromFoodBinding,
            showCompletion: viewModel.showCompletionLegendBinding,
            showExcess: viewModel.showExcessLegendBinding,
            showRemainder: viewModel.showRemainderLegendBinding,
            showRemainderWithLowerBound: viewModel.showRemainderWithLowerBoundLegendBinding,
            showingLegend: viewModel.showingLegendBinding
        )
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
            ForEach(metersTypes, id: \.self) {
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
    var componentsWithTotalBinding: Binding<[NutrientMeterComponent]> {
        Binding<[NutrientMeterComponent]>(
            get: { self.componentsWithTotal },
            set: { _ in }
        )
    }
    var componentsFromFoodBinding: Binding<[NutrientMeterComponent]> {
        Binding<[NutrientMeterComponent]>(
            get: { self.componentsFromFood },
            set: { _ in }
        )
    }
    var showCompletionLegendBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.shouldShowCompletionInLegend },
            set: { _ in }
        )
    }
    var showExcessLegendBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.shouldShowExcessInLegend },
            set: { _ in }
        )
    }
    var showRemainderLegendBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.shouldShowRemainderInLegend },
            set: { _ in }
        )
    }
    var showRemainderWithLowerBoundLegendBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.shouldShowRemainderWithLowerBoundInLegend },
            set: { _ in }
        )
    }
    
    var shouldShowCompletionInLegend: Bool {
        currentMeterViewModels.contains {
            $0.percentageType == .complete
        }
    }
    
    var shouldShowExcessInLegend: Bool {
        currentMeterViewModels.contains {
            $0.percentageType == .excess
        }
    }
    
    var shouldShowRemainderInLegend: Bool {
        currentMeterViewModels.contains {
            $0.goalUpper == nil
            && ($0.percentageType == .empty || $0.percentageType == .regular)
        }
    }
    
    var shouldShowRemainderWithLowerBoundInLegend: Bool {
        currentMeterViewModels.contains {
            $0.goalLower != nil
            && ($0.percentageType == .empty || $0.percentageType == .regular)
        }
    }
    
    var componentsFromFood: [NutrientMeterComponent] {
        foodItem.food.componentsForLegend
    }
    
    var componentsWithTotal: [NutrientMeterComponent] {
        let viewModelsWithTotal = currentMeterViewModels.filter {
            $0.planned > 0
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
    
    var showingLegendBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                UserDefaults.standard.object(forKey: "showingLegend") as? Bool ?? false
            },
            set: { newValue in
                UserDefaults.standard.setValue(newValue, forKey: "showingLegend")
            }
        )
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

        @Binding var metersType: MetersType
        @Binding var componentsWithTotals: [NutrientMeterComponent]
        @Binding var componentsFromFood: [NutrientMeterComponent]
        @Binding var showCompletion: Bool
        @Binding var showExcess: Bool
        @Binding var showRemainder: Bool
        @Binding var showRemainderWithLowerBound: Bool
        
        @Binding var showingLegendBinding: Bool
        @State var showingLegend: Bool
        
        init(
            metersType: Binding<MetersType>,
            componentsWithTotals: Binding<[NutrientMeterComponent]>,
            componentsFromFood: Binding<[NutrientMeterComponent]>,
            showCompletion: Binding<Bool>,
            showExcess: Binding<Bool>,
            showRemainder: Binding<Bool>,
            showRemainderWithLowerBound: Binding<Bool>,
            showingLegend: Binding<Bool>
        ) {
            _metersType = metersType
            _componentsWithTotals = componentsWithTotals
            _componentsFromFood = componentsFromFood
            _showCompletion = showCompletion
            _showExcess = showExcess
            _showRemainder = showRemainder
            _showRemainderWithLowerBound = showRemainderWithLowerBound
            _showingLegendBinding = showingLegend
            
            _showingLegend = State(initialValue: showingLegend.wrappedValue)
        }
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
                showingLegendBinding = showingLegend
            }
        }
    }
    
    var totalText: Text {
        switch metersType {
        case .nutrients, .diet:
            return Text("Nutrient totals for **today**")
        case .meal:
            return Text("Nutrients totals for **this meal**")
        }
    }
    
    var foodText: Text {
        Text("Nutrient totals for **this food**")
    }
    
    var remainderText: some View {
        Group {
            switch metersType {
            case .nutrients:
                Text("Remainder to **maximum** RDA*")
            default:
                Text("Remainder to upper limit")
            }
        }
    }
    
    var remainderWithLowerBoundText: some View {
        var prefix: String {
            "\(colorScheme == .dark ? "Black" : "White") line marks your"
        }
        return Group {
            switch metersType {
            case .nutrients:
                Text("\(prefix) **minimum** RDA*")
            default:
                Text("\(prefix) **minimum** goal")
            }
        }
    }
    
    var completeGoalsText: Text {
        Text("**Completed** goals")
    }
    
    var excessGoalsText: Text {
        Text("Goals in **excess**")
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
                        if !componentsWithTotals.isEmpty {
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
            if !componentsWithTotals.isEmpty {
                GridRow {
                    totalColors
                    totalText
                }
            }
        }
        
        @ViewBuilder
        var foodRow: some View {
            if !componentsFromFood.isEmpty {
                GridRow {
                    foodColors
                    foodText
                }
            }
        }
        
        @ViewBuilder
        var remainderRow: some View {
            if showRemainder {
                GridRow {
                    NutrientMeter.ViewModel.Colors.Empty.fill
                        .frame(width: barWidth, height: barHeight)
                        .cornerRadius(barCornerRadius)
                    remainderText
                }
            }
        }
        
        @ViewBuilder
        var remainderWithLowerBound: some View {
            if showRemainderWithLowerBound {
                GridRow {
                    ZStack(alignment: .leading) {
                        NutrientMeter.ViewModel.Colors.Empty.fill
                            .frame(width: barWidth, height: barHeight)
                            .cornerRadius(barCornerRadius)
                        DottedLine()
                            .stroke(style: StrokeStyle(
                                lineWidth: 2,
                                dash: [100])
                            )
                            .frame(width: 1)
                            .foregroundColor(Color(.systemGroupedBackground))
                            .offset(x: barWidth / 2.0)
                    }
                    remainderWithLowerBoundText
                }
            }
        }
        
        @ViewBuilder
        var completionRow: some View {
            if showCompletion {
                goalCompletionBar(isExcess: false)
            }
        }
        
        @ViewBuilder
        var excessRow: some View {
            if showExcess {
                goalCompletionBar(isExcess: true)
            }
        }
        
        @ViewBuilder
        var rdaExplanation: some View {
            if metersType == .nutrients && (showRemainder || showRemainderWithLowerBound) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("*")
                        .font(.callout)
                        .offset(y: 3)
                    Text("**Recommended Dietary Allowance (RDA)**: Average daily level of intake sufficient to meet your nutrient requirements. [You can customise this in settings.](http://something.com)")
                }
            }
        }
        
        return VStack(alignment: .leading) {
            Grid(alignment: .leading) {
                totalRow
                foodRow
                completionRow
                excessRow
                remainderRow
                remainderWithLowerBound
            }
            rdaExplanation
        }
    }
    
    
    
    var maxColorCount: Int {
        var count = max(componentsWithTotals.count, componentsFromFood.count)
        if showExcess { count += 1 }
        if showCompletion { count += 1 }
        return count
    }
    var barWidth: CGFloat {
        let count = CGFloat(maxColorCount)
        return (count * colorSize) + ((count - 1) * spacing)
    }
    
    var totalColors: some View {
        HStack(spacing: spacing) {
            ForEach(componentsWithTotals, id: \.self) {
                colorBox($0.preppedColor)
            }
            if showCompletion {
                colorBox(NutrientMeter.ViewModel.Colors.Complete.placeholder)
            }
            if showExcess {
                colorBox(NutrientMeter.ViewModel.Colors.Excess.placeholder)
            }
        }
    }
    
    var foodColors: some View {
        HStack(spacing: spacing) {
            ForEach(componentsFromFood, id: \.self) {
                colorBox($0.eatenColor)
            }
            if showCompletion {
                colorBox(NutrientMeter.ViewModel.Colors.Complete.fill)
            }
            if showExcess {
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
//            goalSet: DietMock.cutting,
            goalSet: nil,
            bodyProfile: BodyProfileMock.calculated,
            meals: mockMeals,
            syncStatus: .notSynced,
            updatedAt: 0
        )
    }
    
    var metersSection: some View {
        MealItemMeters(
            foodItem: foodItemBinding,
//            meal: DayMeal(from: MealMock.preWorkoutWithItems),
            meal: mealBinding,
//            meal: .constant(nil),
            day: .constant(mockDay),
//            day: nil,
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
//                    goalSet: MealTypeMock.preWorkout
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
    @State var value: Double? = 300.4
    @State var valueString: String = "300.4"

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
