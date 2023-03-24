/**
 
 So for the food unit picker (call it that)—we'll be having:
 [ ] A section at the top without a name that includes
    [x] g, if measurable by weight
    [x] mL, if measureable by volume
    [x] Serving if present
    [x] Any and all sizes
    [x] Volume-prefixed sizes in their default units
 [ ] This will be followed by two possible buttons, one for "Weights" and one for "Volumes"
    [x] "Weights" If measurable by weight
        [x] Contains all the possible weight units
        [x] Toggling this hides the section we have above (use a slide transition) and transforms the button into the new section
    [x] "Volumes" If measurable by volume and/or we have any volume-prefixed sizes
        [x] If measurable by volumes—we have a volumes section
            [x] Containing all the possible volumes
            [x] Toggling this hides the section we have above (use a slide transition) and transforms the button into the new section
        [x] If we have volume-prefixed sizes—one section for each of them
            [x] Using the name as the header
            [x] Containing all possible volumes with equivalent weights in each of them
            [x] These transition in/out with a move from trailing edge transition or from the bottom
 */
import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar

//MARK: - Logic
extension UnitPickerGridTiered {
    /**
     We're currently only showing the AddSize button if the the flag is true in addition to the sizes list being empty
     */
    var shouldShowAddSizeButton: Bool {
        allowAddSize && (standardSizes + volumePrefixedSizes).isEmpty
    }
    
    var shouldShowServing: Bool {
        includeServing && filteredType == nil
    }
    
    var typesWithOptions: [UnitType] {
        [UnitType.weight, UnitType.volume, UnitType.size]
    }

    var weightUnits: [WeightUnit] {
        [.g, .oz, .mg, .lb, .kg]
    }

    var volumeUnits: [VolumeUnit] {
        [.cup, .mL, .fluidOunce, .teaspoon, .tablespoon, .liter, .pint, .quart, .gallon]
    }
    
    //MARK: Actions
    func pickedUnit(unit: FormUnit) {
        didPickUnit(unit)
        Haptics.feedback(style: .heavy)
        dismiss()
    }
}

enum UnitGroup {
    case weights
    case volumes
    var description: String {
        switch self {
        case .weights:
            return "Weights"
        case .volumes:
            return "Volumes"
        }
    }
}


extension WeightUnit: Option {
    var optionId: String {
        "\(self.rawValue)"
    }
    
    var optionTitle: String {
        self.shortDescription
//        switch self {
//        case .g:
//            return "g"
//        default:
//            return description.lowercased()
//        }
    }
    
    var optionDetail: String {
        self.description.lowercased()
    }
    
    var optionType: UnitType {
        .weight
    }
}

extension VolumeUnit: Option {
    var optionId: String {
        "\(self.rawValue)"
    }
    
    var optionTitle: String {
        self.shortDescription
    }
    
    var optionDetail: String {
        description.lowercased()
    }
    
    var optionType: UnitType {
        .volume
    }
}

public struct UnitPickerGridTiered: View {
    
    @Environment(\.dismiss) var dismiss
    @Namespace var namespace
    
    @State var isGrid: Bool
    @State var type: UnitType
    @State var pickedUnit: FormUnit

    @State var pickedVolumePrefixUnit: FormUnit = .volume(.cup)
    
    @State var pickedGroup: UnitGroup? = nil
    
    let includeServing: Bool
    let includeVolumes: Bool
    let includeWeights: Bool
    let allowsCompactMode: Bool
    let allowAddSize: Bool
    let filteredType: UnitType?
    let servingDescription: String?
    
    let didPickUnit: (FormUnit) -> ()
    let didTapAddSize: (() -> ())?

    let standardSizes: [FormSize]
    let volumePrefixedSizes: [FormSize]
    
    @State var groups: [UnitGroup]
    
    public init(
        pickedUnit unit: FormUnit = .weight(.g),
        includeServing: Bool = true,
        includeWeights: Bool = true,
        includeVolumes: Bool = true,
        sizes: [FormSize],
        servingDescription: String? = nil,
        allowsCompactMode: Bool = false,
        allowAddSize: Bool = true,
        filteredType: UnitType? = nil,
        didTapAddSize: (() -> ())? = nil,
        didPickUnit: @escaping (FormUnit) -> ())
    {
        self.didPickUnit = didPickUnit
        self.didTapAddSize = didTapAddSize
        self.includeServing = includeServing
        self.allowsCompactMode = allowsCompactMode
        self.includeWeights = includeWeights
        self.includeVolumes = includeVolumes
        self.servingDescription = servingDescription
        self.allowAddSize = allowAddSize
        self.filteredType = filteredType
        
        self.standardSizes = sizes.standardSizes
        self.volumePrefixedSizes = sizes.volumePrefixedSizes
        
        _pickedUnit = State(initialValue: unit)
        _type = State(initialValue: unit.unitType)
        _isGrid = State(initialValue: !allowsCompactMode)
        
        var groups: [UnitGroup] = []
        if includeWeights {
            groups.append(.weights)
        }
        if includeVolumes || !volumePrefixedSizes.isEmpty {
            groups.append(.volumes)
        }
        _groups = State(initialValue: groups)
    }
    
    @State var presentationDetent: PresentationDetent = .height(450)
    
    public var body: some View {
        NavigationView {
            content
            .navigationTitle(navigationTitleString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { trailingContent }
            .toolbar { leadingContent }
        }
        .onChange(of: type) { newValue in
            if type == .serving {
                pickedUnit(unit: .serving)
            }
        }
//        .presentationDetents([.height(350), .large], selection: $presentationDetent)
        .presentationDetents([.height(450), .large], selection: $presentationDetent)
        .presentationDragIndicator(.hidden)
    }

    var leadingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if pickedGroup != nil {
                Button {
                    Haptics.feedback(style: .soft)
                    withAnimation {
                        pickedGroup = nil
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .padding(.all.subtracting(.leading))
                        .contentShape(Rectangle())
                }
            }
        }
    }

    var trailingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                CloseButtonLabel()
            }
        }
    }
    
    var content: some View {
        FormStyledScrollView {
            if let filteredGroup {
                sections(for: filteredGroup)
            } else {
                if pickedGroup == nil {
                    primaryUnitsSection
                        .transition(.move(edge: .leading))
                }
                if let pickedGroup {
                    sections(for: pickedGroup)
                } else {
                    groupButtons
                }
            }
        }
    }
    
    var filteredGroup: UnitGroup? {
        guard standardSizes.count == 0,
              volumePrefixedSizes.count == 0,
              !includeServing else {
            return nil
        }
        if includeWeights && !includeVolumes {
            return .weights
        }
        if includeVolumes && !includeWeights {
            return .volumes
        }
        return nil
    }
    
    //MARK: - Primary Units Section
    
    @ViewBuilder
    var primaryUnitsSection: some View {
//        if !standardSizes.isEmpty {
            OptionsSection(
//                header: "Sizes",
                options: primaryUnitOptions,
                isGrid: $isGrid
            ) { option in
                if let size = option as? FormSize {
                    pickedUnit(unit: .size(size, nil))
                }
                else if let volumePrefixedSize = option as? VolumePrefixedSizeOption {
                    pickedUnit(unit: .size(volumePrefixedSize.size, volumePrefixedSize.volumeUnit))
                }
                else if let weightUnit = option as? WeightUnit {
                    pickedUnit(unit: .weight(weightUnit))
                }
                else if let volumeUnit = option as? VolumeUnit {
                    pickedUnit(unit: .volume(volumeUnit))
                }
                else if let _ = option as? ServingOption {
                    pickedUnit(unit: .serving)
                }
            }
//        }
    }

    var primaryUnitOptions: [Option] {
        var options: [Option] = []
        if includeWeights {
            options.append(WeightUnit.g)
        }
        if includeVolumes {
            options.append(VolumeUnit.mL)
        }
        if includeServing {
            options.append(ServingOption(description: servingDescription ?? ""))
        }
        options.append(contentsOf: standardSizes.map{ $0 as Option})
        
        let volumePrefixedSizeOptions: [VolumePrefixedSizeOption] = volumePrefixedSizes.compactMap { size in
            guard let volumePrefixUnit = size.volumePrefixUnit?.volumeUnit else {
                return nil
            }
            return VolumePrefixedSizeOption(
                size: size,
                volumeUnit: volumePrefixUnit,
                includeSize: true
            )
        }
        options.append(contentsOf: volumePrefixedSizeOptions)
        
        return options
    }
    
    //MARK: - Group Buttons

    var groupButtons: some View {
        HStack(spacing: 20) {
            ForEach(groups, id: \.self) { group in
                Button {
                    Haptics.feedback(style: .rigid)
                    withAnimation {
                        self.pickedGroup = group
                    }
                } label: {
                    Text(group.description)
                        .fixedSize()
                        .matchedGeometryEffect(id: "groupHeader_\(group.description)", in: namespace)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color(.secondarySystemGroupedBackground))
                                .matchedGeometryEffect(id: "groupBackground_\(group.description)", in: namespace)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
    
    //MARK: - Measurement Section(s)
    
    let DefaultHorizontalPadding: CGFloat = 17
    let DefaultVerticalPadding: CGFloat = 15

    func options(for group: UnitGroup) -> [Option] {
        switch group {
        case .weights:
            return weightUnits.map { $0 as Option }
        case .volumes:
            return volumeUnits.map { $0 as Option }
        }
    }
    
    @ViewBuilder
    func sections(for group: UnitGroup) -> some View {
        switch group {
        case .weights:
            section(for: .weights)
        case .volumes:
            Group {
                if includeVolumes {
                    section(for: .volumes)
                }
                ForEach(volumePrefixedSizes, id: \.self) {
                    volumePrefixedSizeSection(for: $0)
                        .transition(.move(edge: .trailing))
                }
            }
        }
    }
    
    func section(for group: UnitGroup) -> some View {
        let options = options(for: group)
        return VStack(spacing: 7) {
            Text(group.description)
                .matchedGeometryEffect(id: "groupHeader_\(group.description)", in: namespace)
                .foregroundColor(Color(.secondaryLabel))
                .font(.footnote)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            FlowLayout(
                mode: .scrollable,
                items: options,
                itemSpacing: 4,
                shouldAnimateHeight: .constant(true)
            ) {
                button(for: $0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DefaultHorizontalPadding)
            .padding(.vertical, DefaultVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color(.secondarySystemGroupedBackground))
                    .matchedGeometryEffect(id: "groupBackground_\(group.description)", in: namespace)
            )
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    func button(for option: Option, swapColors: Bool = false) -> some View {
        PillButton(
            primaryString: option.optionTitle,
            secondaryString: option.optionDetail,
            swapColors: swapColors,
            didTap: {
                guard let intValue = Int16(option.optionId) else { return }
                switch option.optionType {
                case .weight:
                    guard let weightUnit = WeightUnit(rawValue: intValue) else { return }
                    pickedUnit(unit: .weight(weightUnit))
                case .volume:
                    guard let volumeUnit = VolumeUnit(rawValue: intValue) else { return }
                    pickedUnit(unit: .volume(volumeUnit))
                default:
                    return
                }
            }
        )
    }
    
    @ViewBuilder
    var volumePrefixedSizesSection: some View {
        ForEach(volumePrefixedSizes, id: \.self) {
            volumePrefixedSizeSection(for: $0)
        }
    }
    
    func volumePrefixedSizeSection(for size: FormSize) -> some View {
        OptionsSection(
            header: size.name,
            options: size.volumePrefixedSizeOptions,
            isGrid: $isGrid
        ) { option in
            guard let option = option as? VolumePrefixedSizeOption else { return }
            pickedUnit(unit: .size(option.size, option.volumeUnit))
        }
    }

    @ViewBuilder
    var weightUnitsSection: some View {
        if includeWeights {
            OptionsSection(
                header: "Weights",
                options: weightUnits,
                isGrid: $isGrid,
                swapColors: true
            ) { option in
                guard let weightUnit = option as? WeightUnit else { return }
                pickedUnit(unit: .weight(weightUnit))
            }
        }
    }

    @ViewBuilder
    var volumeUnitsSection: some View {
        if includeVolumes {
            OptionsSection(
                header: "Volumes",
                options: volumeUnits,
                isGrid: $isGrid,
                swapColors: true
            ) { option in
                guard let volumeUnit = option as? VolumeUnit else { return }
                pickedUnit(unit: .volume(volumeUnit))
            }
        }
    }


    //MARK: - Legacy
    
    var longList: some View {
        List {
            if let filteredType = filteredType {
                Section {
                    filteredList(for: filteredType)
                }
            } else {
                if !standardSizes.isEmpty {
                    Section("Sizes") {
                        standardSizeContents
                    }
                }
                if !volumePrefixedSizes.isEmpty {
                    Section("Volume-named Sizes") {
                        volumePrefixedSizeContents
                    }
                }
                if shouldShowAddSizeButton {
                    Section {
                        addSizeButton
                    }
                }
                if shouldShowServing {
                    Section {
                        servingButton
                    }
                }
                Section {
                    weightUnitButton(for: .g)
                    volumeUnitButton(for: .mL)
                }
                Section("Other Units") {
                    DisclosureGroup("Weights") {
                        weightsGroupContents
                    }
                    DisclosureGroup("Volumes") {
                        volumesGroupContents
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func filteredList(for type: UnitType) -> some View {
        switch type {
        case .weight:
            weightsGroupContents
        case .volume:
            volumesGroupContents
        case .size:
            sizesGroupContents
        default:
            EmptyView()
        }
    }
    
    //MARK: - Components
    
    var typePicker: some View {
        Picker("", selection: $type) {
            ForEach(typesWithOptions, id: \.self) {
                Text($0.description).tag($0)
            }
        }
    }
    
    var navigationTitleString: String {
        let name: String
        if let filteredType = filteredType {
            name = filteredType.description.lowercased() + " unit"
        } else {
            name = "unit"
        }
        return "Choose a \(name)"
    }
    
    func weightUnitButton(for weightUnit: WeightUnit) -> some View {
        Button {
            pickedUnit(unit: .weight(weightUnit))
        } label: {
            HStack {
                Text(weightUnit.description)
                    .textCase(.lowercase)
                    .foregroundColor(.primary)
                Spacer()
                Text(weightUnit.shortDescription)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }
    
    func volumeUnitButton(for volumeUnit: VolumeUnit) -> some View {
        Button {
            pickedUnit(unit: .volume(volumeUnit))
        } label: {
            HStack {
                Text(volumeUnit.description)
                    .textCase(.lowercase)
                    .foregroundColor(.primary)
                Spacer()
                Text(volumeUnit.shortDescription)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }
    
    //MARK: - Group Contents
    var weightsGroupContents: some View {
        ForEach(weightUnits, id: \.self) { weightUnit in
            weightUnitButton(for: weightUnit)
        }
    }
    
    var volumesGroupContents: some View {
        ForEach(volumeUnits, id: \.self) { volumeUnit in
            volumeUnitButton(for: volumeUnit)
        }
    }
    
    func volumePrefixes(for size: FormSize) -> some View {
        ForEach(volumeUnits, id: \.self) { volumeUnit in
            Button {
                pickedUnit(unit: .size(size, volumeUnit))
            } label: {
                HStack {
                    HStack(spacing: 0) {
                        Text(volumeUnit.description)
                            .textCase(.lowercase)
                            .foregroundColor(.primary)
                        Text(", ")
                            .foregroundColor(Color(.tertiaryLabel))
                        Text(size.name)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                    Text(volumeUnit.shortDescription)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.borderless)
        }
    }

    var standardSizeContents: some View {
        ForEach(standardSizes, id: \.self) { sizeField in
            sizeButton(for: sizeField)
        }
    }
    
    @ViewBuilder
    func sizeButton(for size: FormSize) -> some View {
        Button {
            pickedUnit(unit: .size(size, nil))
        } label: {
            HStack {
                Text(size.name)
                    .foregroundColor(.primary)
                Spacer()
                HStack {
                    Text(size.scaledAmountString)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .buttonStyle(.borderless)
    }
    
    var volumePrefixedSizeContents: some View {
        ForEach(volumePrefixedSizes, id: \.self) { size in
            volumePrefixedSizeGroup(for: size)
        }
    }
    
    @ViewBuilder
    func volumePrefixedSizeGroup(for size: FormSize) -> some View {
        DisclosureGroup(size.name) {
            volumePrefixes(for: size)
        }
    }
    
    var sizesGroupContents: some View {
        Group {
            if !standardSizes.isEmpty {
                Section {
                    standardSizeContents
                }
            }
            if !volumePrefixedSizes.isEmpty {
                Section("Volume-prefixed") {
                    volumePrefixedSizeContents
                }
            }
            if allowAddSize {
                Section {
                    addSizeButton
                }
            }
        }
    }

    //MARK: - Buttons
    
    var addSizeButton: some View {
        Button {
            didTapAddSize?()
        } label: {
            HStack {
                Text("Add a size")
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .contentShape(Rectangle())
    }
    
    var servingButton: some View {
        Button {
            pickedUnit(unit: .serving)
        } label: {
            HStack {
                Text("Serving")
                    .textCase(.lowercase)
                    .foregroundColor(.primary)
                Spacer()
                if let servingDescription = servingDescription {
                    Text(servingDescription)
                        .foregroundColor(Color(.secondaryLabel))
                }
//                if case .serving = pickedUnit {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(.accentColor)
//                }
            }
        }
        .buttonStyle(.borderless)
    }
}


struct UnitPickerGridTiered_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    UnitPickerGridTiered(
                        pickedUnit: .weight(.g),
                        includeServing: true,
                        sizes: mockSizes,
                        servingDescription: mockServingDescription,
                        allowAddSize: true,
                        filteredType: nil,
                        didTapAddSize: {
                            
                        },
                        didPickUnit: { _ in
                            
                        }
                    )
                }
        }
    }
}

let mockSizes: [FormSize] = [
    FormSize(quantity: 1, volumePrefixUnit: .volume(.cup), name: "chopped", amount: 240, unit: .weight(.g)),
    FormSize(quantity: 1, volumePrefixUnit: .volume(.cup), name: "sliced", amount: 100, unit: .weight(.g)),
    FormSize(quantity: 1, name: "large", amount: 70, unit: .weight(.g)),
    FormSize(quantity: 1, name: "medium", amount: 40, unit: .weight(.g)),
    FormSize(quantity: 1, name: "small", amount: 35, unit: .weight(.g)),
    FormSize(quantity: 1, name: "slice", amount: 10, unit: .weight(.g)),
    FormSize(quantity: 1, name: "extra large", amount: 110, unit: .weight(.g)),
]

let mockServingDescription = "1 cup chopped (240 mL)"
