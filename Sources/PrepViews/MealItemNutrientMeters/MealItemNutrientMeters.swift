import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepMocks
import SwiftUIPager

struct MealItemNutrientMeters: View {
    
    @StateObject var viewModel: ViewModel

    init(
        foodItem: MealFoodItem,
        meal: DayMeal,
        day: Day,
        shouldCreateSubgoals: Bool = true
    ) {
        let viewModel = ViewModel(
            foodItem: foodItem,
            meal: meal,
            day: day,
            shouldCreateSubgoals: shouldCreateSubgoals
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var header: some View {
        HStack(alignment: .center) {
            dailyOrMealPicker
                .textCase(.none)
            Spacer()
            goalSetPicker
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
    
    var footer: some View {
        Text(viewModel.metersType.footerString)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(Color(.secondaryLabel))
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .padding(.horizontal, 20)
    }
    
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
        picker()
    }
    
    var mealTypePicker: some View {
        picker()
    }
    
    func picker() -> some View {
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

    var dailyOrMealPicker: some View {
        Picker("", selection: viewModel.metersTypeBinding) {
            ForEach(MetersType.allCases, id: \.self) {
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
    
    var pager: some View {
        Pager(
            page: viewModel.page,
            data: MetersType.allCases,
            id: \.self,
            content: { metersType in
                Meters(metersType)
                    .environmentObject(viewModel)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 17)
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
    
    var body: some View {
        Group {
            arrow
            VStack(spacing: 7) {
                header
                pager
                footer
            }
            .padding(.top, 10)
        }
    }
}

//MARK: MetersType
enum MetersType: Int, CaseIterable {
    case nutrients = 1
    case diet
    case meal
    
    var description: String {
        switch self {
        case .nutrients:
            return "Nutrients"
        case .diet:
            return "Diet"
        case .meal:
            return "Meal"
        }
    }
    
    var footerString: String {
        var prefix: String {
            switch self {
            case .nutrients:
                return "These are all the nutrients listed for this food."
            case .diet:
                return "These are the goals for the diet you have chosen for today."
            case .meal:
                return "These are the goals for the meal you are adding this to."
            }
        }
        
        var suffix: String {
            let string: String
            switch self {
            case .nutrients:
                string = " today."
            case .diet, .meal:
                string = ", against the total goal."
            }
            return "Each meter represents the relative increase from what you've added so far\(string)"
        }

        return "\(prefix) \(suffix)"
    }
}

//MARK: - View Model

extension MealItemNutrientMeters {
    class ViewModel: ObservableObject {
        
        let foodItem: MealFoodItem
        let meal: DayMeal
        let day: Day
        let shouldCreateSubgoals: Bool
        
        @Published var metersType: MetersType
        @Published var pagerHeight: CGFloat
        
        @Published var page: Page

        init(foodItem: MealFoodItem, meal: DayMeal, day: Day, shouldCreateSubgoals: Bool) {
            self.foodItem = foodItem
            self.day = day
            self.meal = meal
            self.shouldCreateSubgoals = shouldCreateSubgoals
            
            let numberOfRows: Int
            if let diet = day.goalSet {
                self.metersType = .meal
                //TODO: If we have a meal.goalSet, add any rows from there that aren't in the day.goalSet
                numberOfRows = diet.goals.count
                self.page = Page.withIndex(3)
            } else {
                self.metersType = .nutrients
                numberOfRows = foodItem.food.numberOfNutrients
                self.page = Page.first()
            }
            self.pagerHeight = calculateHeight(numberOfRows: numberOfRows)
        }
    }
}

extension MealItemNutrientMeters.ViewModel {
    var diet: GoalSet? {
        day.goalSet
    }
    
    var hasDiet: Bool {
        diet != nil
    }
    
    var metersTypeBinding: Binding<MetersType> {
        Binding<MetersType>(
            get: { self.metersType },
            set: { newType in
                withAnimation {
                    self.metersType = newType
                    self.page.update(.new(index: newType.rawValue - 1))
                    self.pagerHeight = calculateHeight(numberOfRows: self.numberOfRows(for: newType))
                }
            }
        )
    }
    
    func numberOfRows(for metersType: MetersType) -> Int {
        switch metersType {
        case .nutrients:
            return foodItem.food.numberOfNutrients
        case .diet:
            return day.goalSet?.goals.count ?? 0
        case .meal:
            //TODO: Add MealType goals we may not have in Diet
            return day.goalSet?.goals.count ?? 0
        }
    }
    
    func pageWillTransition(_ result: Result<PageTransition, PageTransitionError>) {
        switch result {
        case .success(let transition):
            withAnimation {
                self.metersType = MetersType(rawValue: transition.nextPage + 1) ?? .nutrients
                self.pagerHeight = calculateHeight(numberOfRows: self.numberOfRows(for: self.metersType))
            }
        case .failure:
            break
        }
    }
}

//MARK: Food + Convenience

extension Food {
    var numberOfMicronutrients: Int {
        info.nutrients.micros.count
    }
    var numberOfNutrients: Int {
        /// All foods have energy + 3 macros
        return 4 + numberOfMicronutrients
    }
}

//MARK: - Example Meters (Remove)

let MeterSpacing = 5.0
let MeterHeight = 20.0
let MeterLabelFontStyle: Font.TextStyle = .body
let MeterLabelFont: Font = Font.system(MeterLabelFontStyle)

func calculateHeight(numberOfRows: Int) -> CGFloat {
    let rows = CGFloat(integerLiteral: numberOfRows)
    let meters = rows * MeterHeight
    let spacing = (rows - 1.0) * MeterSpacing
    let padding = (15.0 * 2.0)
    let extraPadding = (5.0 * 2.0)
    return meters + spacing + padding + extraPadding
}

extension MealItemNutrientMeters.ViewModel {
    
    var nutrients: FoodNutrients {
        foodItem.food.info.nutrients
    }
    
    func plannedValue(for component: NutrientMeterComponent, type: MetersType) -> Double {
        switch type {
        case .nutrients, .diet:
            return day.plannedValue(for: component, ignoring: meal.id) + meal.plannedValue(for: component)
        case .meal:
            return meal.plannedValue(for: component)
        }
    }
    
    var nutrientViewModels: [NutrientMeter.ViewModel] {
        func p(_ component: NutrientMeterComponent) -> Double {
            plannedValue(for: component, type: .nutrients)
        }
        
        var viewModels: [NutrientMeter.ViewModel] = []
        viewModels.append(NutrientMeter.ViewModel(component: .energy, planned: p(.energy), increment: nutrients.energyInKcal))

        viewModels.append(NutrientMeter.ViewModel(component: .carb, planned: p(.carb), increment: nutrients.carb))
        viewModels.append(NutrientMeter.ViewModel(component: .fat, planned: p(.fat), increment: nutrients.fat))
        viewModels.append(NutrientMeter.ViewModel(component: .protein, planned: p(.protein), increment: nutrients.protein))

        for micro in nutrients.micros {
            guard let nutrientType = micro.nutrientType, micro.value > 0 else { continue }
            //TODO: Handle unit conversions and displaying the correct one here
            let component: NutrientMeterComponent = .micro(
                nutrientType: nutrientType,
                nutrientUnit: micro.nutrientUnit
            )
            viewModels.append(NutrientMeter.ViewModel(
                component: component,
                planned: p(component),
                increment: micro.value
            ))
        }
        return viewModels
    }
    
    func meterViewModels(for type: MetersType) -> [NutrientMeter.ViewModel] {
        switch type {
        case .nutrients:
            return nutrientViewModels
        case .diet:
            return []
        case .meal:
            return []
        }
    }
}

extension Day {
    func plannedValue(for component: NutrientMeterComponent, ignoring mealID: UUID) -> Double {
        meals.reduce(0) { partialResult, dayMeal in
            partialResult + (dayMeal.id != mealID ? dayMeal.plannedValue(for: component) : 0)
        }
    }
}
extension DayMeal {
    func plannedValue(for component: NutrientMeterComponent) -> Double {
        foodItems.reduce(0) { partialResult, mealFoodItem in
            partialResult + mealFoodItem.value(for: component)
        }
    }
}

extension Food {
    func quantity(for amount: FoodValue) -> FoodQuantity? {
        guard let unit = FoodQuantity.Unit(foodValue: amount, in: self) else { return nil }
        return FoodQuantity(value: amount.value, unit: unit, food: self)
    }
}

extension MealFoodItem {
    
    var nutrientScaleFactor: Double {
        guard let foodQuantity = food.quantity(for: amount) else { return 0 }
        return food.nutrientScaleFactor(for: foodQuantity) ?? 0
    }
    
    func value(for component: NutrientMeterComponent) -> Double {
        guard let value = food.info.nutrients.value(for: component) else { return 0 }
        return value * nutrientScaleFactor
    }
}

extension FoodNutrients {
    func value(for component: NutrientMeterComponent) -> Double? {
        //TODO: Complete this by doing the following
        /// [x] Account for `FoodValue` and multiply the values accordingly
        /// [x] Modify micro to include actual `NutrientType` and not just the `String` of the description
        switch component {
        case .energy:
            return energyInKcal
        case .carb:
            return carb
        case .fat:
            return fat
        case .protein:
            return protein
        case .micro(let nutrientType, _):
            return micros.first(where: { $0.nutrientType == nutrientType })?.value
        }
    }
}

extension MealItemNutrientMeters {
    
    struct Meters: View {
        
        @EnvironmentObject var viewModel: MealItemNutrientMeters.ViewModel
        
        let type: MetersType
        
        init(_ type: MetersType) {
            self.type = type
        }
        
        var body: some View {
            VStack {
                Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
                    ForEach(viewModel.meterViewModels(for: type), id: \.self) { meterViewModel in
                        meterRow(for: meterViewModel)
                    }
                }
            }
        }
    }
}

extension MealItemNutrientMeters.Meters {
    func meterRow(for meterViewModel: NutrientMeter.ViewModel) -> some View {
        GridRow {
            Text(meterViewModel.component.description)
                .foregroundColor(meterViewModel.component.textColor)
                .font(MeterLabelFont)
            NutrientMeter(viewModel: meterViewModel)
                .frame(height: MeterHeight)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(meterViewModel.increment?.cleanAmount ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(meterViewModel.component.unit)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
    }
}
