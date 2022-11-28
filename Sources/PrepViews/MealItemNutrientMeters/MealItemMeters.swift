import SwiftUI
import SwiftUISugar
import PrepDataTypes
import PrepMocks
import SwiftUIPager

public struct MealItemMeters: View {
    
    @StateObject var viewModel: ViewModel

    @Binding var foodItem: MealFoodItem
    @Binding var meal: DayMeal?

    public init(
        foodItem: Binding<MealFoodItem>,
        meal: Binding<DayMeal?>,
        day: Day?,
        userUnits: UserUnits,
        bodyProfile: BodyProfile?,
        shouldCreateSubgoals: Bool = true
    ) {
        _foodItem = foodItem
        _meal = meal
        
        let viewModel = ViewModel(
            foodItem: foodItem.wrappedValue,
            meal: meal.wrappedValue,
            day: day,
            userUnits: userUnits,
            bodyProfile: bodyProfile,
            shouldCreateSubgoals: shouldCreateSubgoals
        )
        _viewModel = StateObject(wrappedValue: viewModel)
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
                viewModel.foodItem.amount = newFoodItem.amount
            }
        }
        .onChange(of: meal) { newValue in
            withAnimation {
                viewModel.meal = meal
            }
        }
    }
    
    var metersTypes: [MetersType] {
        var types = [MetersType.nutrients]
        if viewModel.day != nil {
            types.append(.diet)
        }
        if viewModel.meal != nil {
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
    
    var footer_legend: some View {
        Legend(
            prepped: [.energy, .fat, .protein, .carb],
            increments: [.energy, .fat, .protein, .carb],
            showCompletion: false,
            showExcess: false
        )
        .fixedSize(horizontal: false, vertical: true)
        .foregroundColor(Color(.secondaryLabel))
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
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
        picker()
    }
    
    var mealTypePicker: some View {
        picker()
    }
    
    func picker() -> some View {
        HStack(spacing: 2) {
            Text("🫃🏽")
                .font(.footnote)
            Text("Cutting")
                .font(.footnote)
                .foregroundColor(.accentColor)
//                .bold()
//                .foregroundColor(.accentColor)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundColor(.accentColor)
                .foregroundColor(Color(.tertiaryLabel))
                .font(.footnote)
                .imageScale(.small)
        }
        .padding(.trailing, 20)
//        .padding(.vertical, 5.5)
//        .padding(.horizontal, 10)
//        .background(
//            RoundedRectangle(cornerRadius: 7)
//                .foregroundColor(Color(.tertiarySystemFill))
//        )
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
