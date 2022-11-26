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
        switch self {
        case .nutrients:
            return "These are all the nutrients listed for the food. Each meter shows how much of an increase this food will contribute to what you've already added today."
        case .diet:
            return "These are the goals for the diet you have chosen for today. Each meter shows how much of an increase this food will contribute to what you've already added  today."
        case .meal:
            return "These are the goals for the meal type you have chosen. Each bar shows how much of an increase this food will contribute to what you've already added to this meal."
        }
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
    
    var nutrientViewModels: [NutrientMeter.ViewModel] {
        var viewModels: [NutrientMeter.ViewModel] = []
        viewModels.append(NutrientMeter.ViewModel(component: .energy, planned: 1, increment: nutrients.energyInKcal))

        viewModels.append(NutrientMeter.ViewModel(component: .carb, planned: 1, increment: nutrients.carb))
        viewModels.append(NutrientMeter.ViewModel(component: .fat, planned: 1, increment: nutrients.fat))
        viewModels.append(NutrientMeter.ViewModel(component: .protein, planned: 1, increment: nutrients.protein))

        for micro in nutrients.micros {
            //TODO: Handle unit conversions and displaying the correct one here
            viewModels.append(NutrientMeter.ViewModel(
                component: .micro(name: micro.nutrientType?.description ?? "", unit: micro.nutrientUnit.shortDescription),
                planned: 1,
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

extension MealItemNutrientMeters.Meters {
    
    var exampleMeters: some View {
        VStack {
            Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
                GridRow {
                    Text("Energy")
                        .foregroundColor(NutrientMeterComponent.energy.textColor)
                        .font(MeterLabelFont)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .energy, burned: 0, planned: 170, increment: 180))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("170")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("kcal")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Carb")
                        .foregroundColor(NutrientMeterComponent.carb.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .carb, burned: 0, planned: 170, increment: 20))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("12")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Fat")
                        .foregroundColor(NutrientMeterComponent.fat.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .fat, burned: 0, planned: 70, increment: 60))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("28.5")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Protein")
                        .foregroundColor(NutrientMeterComponent.protein.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .protein, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
    }

    var exampleMeters2: some View {
        VStack {
            Grid(alignment: .leading, verticalSpacing: MeterSpacing) {
                GridRow {
                    Text("Energy")
                        .foregroundColor(NutrientMeterComponent.energy.textColor)
                        .font(MeterLabelFont)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .energy, goal: 400, burned: 0, planned: 170, increment: 180))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("170")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("kcal")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Carb")
                        .foregroundColor(NutrientMeterComponent.carb.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .carb, goal: 400, burned: 0, planned: 170, increment: 20))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("12")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Fat")
                        .foregroundColor(NutrientMeterComponent.fat.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .fat, goal: 300, burned: 0, planned: 70, increment: 60))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("28.5")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Protein")
                        .foregroundColor(NutrientMeterComponent.protein.textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .protein, goal: 300, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Magnesium")
                        .foregroundColor(NutrientMeterComponent.micro(name: "").textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .micro(name: "Magnesium"), goal: 440, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                GridRow {
                    Text("Sodium")
                        .foregroundColor(NutrientMeterComponent.micro(name: "").textColor)
                        .font(MeterLabelFont)
    //                    .fontWeight(.bold)
    //                    .font(.title3)
                    NutrientMeter(viewModel: .init(
                        component: .micro(name: "Sodium"), goal: 600, burned: 0, planned: 170, increment: 70))
                    .frame(height: MeterHeight)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("6")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("g")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
            }
        }
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
            .navigationTitle("Quantity")
        }
    }

    var metersSection: some View {
        MealItemNutrientMeters(
            foodItem: MealFoodItem(
                food: FoodMock.peanutButter,
                amount: FoodValue(value: 20, unitType: .weight, weightUnit: .g)
            ),
            meal: DayMeal(from: MealMock.preWorkoutWithItems),
            day: DayMock.cutting
        )
    }
    
    var textFieldSection: some View {
        FormStyledSection(header: Text("Weight")) {
            HStack {
                TextField("Required", text: .constant(""))
                Button {
                } label: {
                    HStack(spacing: 5) {
                        Text("g")
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }

}

struct MealItemNutrientMeters_Previews: PreviewProvider {
    static var previews: some View {
//        Color.blue
        MealItemNutrientMetersPreview()
    }
}
