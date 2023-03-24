import SwiftUI
import PrepDataTypes
import SwiftHaptics
import SwiftUISugar

public struct NutrientsPicker: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    let didAddNutrients: (Bool, [Macro], [NutrientType]) -> ()
    
    /// Returns true if there are unused micronutrients in the specified group matching the search string provided
    //TODO: Do the search on our end
    let hasUnusedMicros: ((NutrientTypeGroup, String) -> Bool)?
    
    /// Returns true if the specified micronutrient has been added and shouldn't be shown
    let hasMicronutrient: ((NutrientType) -> Bool)?
    
    let supportsEnergyAndMacros: Bool
    let shouldShowMacro: ((Macro) -> Bool)?
    let shouldShowEnergy: Bool?

    let shouldDisableLastMacroOrEnergy: Bool
    
    let supportsMultipleSelections: Bool
    
    @State var energyIsPicked: Bool = false
    @State var pickedMacros: [Macro] = []
    @State var pickedNutrientTypes: [NutrientType] = []

    @State var searchText = ""
    @State var searchIsFocused: Bool = false
    
    public init(
        supportsEnergyAndMacros: Bool = false,
        supportsMultipleSelections: Bool = true,
        shouldShowEnergy: Bool? = nil,
        shouldShowMacro: ((Macro) -> Bool)? = nil,
        shouldDisableLastMacroOrEnergy: Bool = false,
        hasUnusedMicros: ((NutrientTypeGroup, String) -> Bool)? = nil,
        hasMicronutrient: ((NutrientType) -> Bool)? = nil,
        didAddNutrients: @escaping (Bool, [Macro], [NutrientType]) -> Void
    ) {
        self.shouldShowMacro = shouldShowMacro
        self.shouldShowEnergy = shouldShowEnergy
        self.supportsEnergyAndMacros = supportsEnergyAndMacros
        self.supportsMultipleSelections = supportsMultipleSelections
        self.shouldDisableLastMacroOrEnergy = shouldDisableLastMacroOrEnergy
        self.didAddNutrients = didAddNutrients
        self.hasUnusedMicros = hasUnusedMicros
        self.hasMicronutrient = hasMicronutrient
    }
    
    var title: String {
        var subject = supportsEnergyAndMacros ? "Nutrient" : "Micronutrient"
        let prefix: String
        if supportsMultipleSelections {
            prefix = "Add"
            subject += "s"
        } else {
            prefix = "Pick a"
        }
        return "\(prefix) \(subject)"
    }
    
    public var body: some View {
        NavigationView {
            SearchableView(
                searchText: $searchText,
                promptSuffix: title,
                focused: $searchIsFocused,
                content: {
                    form
                }
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { navigationLeadingContent }
            .toolbar { navigationTrailingContent }
        }
    }

    var form: some View {
        Form {
            energySection
            macroSection
            microSections
        }
    }
    
    var energySection: some View {
        var shouldDisableEnergy: Bool {
            guard shouldDisableLastMacroOrEnergy else { return false }
            return pickedMacros.count == 3
        }
        
        var textColor: Color {
            shouldDisableEnergy ? Color(.secondaryLabel) : .primary
        }
        
        var checkmarkOpacity: CGFloat {
            guard !shouldDisableEnergy else {
                return 1
            }
            return energyIsPicked ? 1 : 0
        }
        
        var shouldShow: Bool {
            guard let shouldShowEnergy else {
                return supportsEnergyAndMacros
            }
            return shouldShowEnergy
        }
        
        return Group {
            if shouldShow {
                Section {
                    Button {
                        if supportsMultipleSelections {
                            Haptics.feedback(style: .soft)
                            energyIsPicked.toggle()
                        } else {
                            energyIsPicked = true
                            dismissWithSelections()
                        }
                    } label: {
                        HStack {
                            if supportsMultipleSelections {
                                Image(systemName: "checkmark")
                                    .opacity(checkmarkOpacity)
                                    .animation(.default, value: energyIsPicked)
                            }
                            Text("Energy")
                                .foregroundColor(textColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                    }
                    .disabled(shouldDisableEnergy)
                }
            }
        }
    }
    
    var macrosToShow: [Macro] {
        Macro.allCases.filter { macro in
            guard let shouldShowMacro else {
                return supportsEnergyAndMacros
            }
            
            guard shouldShowMacro(macro) else {
                return false
            }
            
            if !searchText.isEmpty {
                return macro.description.lowercased().contains(searchText)
            } else {
                return true
            }
        }
    }
    
    @ViewBuilder
    var macroSection: some View {
        if !macrosToShow.isEmpty {
            Section("Macros") {
                ForEach(macrosToShow, id: \.self) { macro in
                    button(for: macro)
                }
            }
        }
    }

    func button(for macro: Macro) -> some View {
        var shouldDisable: Bool {
            guard shouldDisableLastMacroOrEnergy,
                  (pickedMacros.count == 2 && energyIsPicked)
            else {
                return false
                
            }
            return !pickedMacros.contains(macro)
        }
        
        var textColor: Color {
            shouldDisable ? Color(.secondaryLabel) : .primary
        }
        
        var checkmarkOpacity: CGFloat {
            guard !shouldDisable else {
                return 1
            }
            return pickedMacros.contains(macro) ? 1 : 0
        }
        
        return Button {
            if supportsMultipleSelections {
                Haptics.feedback(style: .soft)
                if pickedMacros.contains(macro) {
                    pickedMacros.removeAll(where: { $0 == macro })
                } else {
                    pickedMacros.append(macro)
                }
            } else {
                pickedMacros.append(macro)
                dismissWithSelections()
            }
        } label: {
            HStack {
                if supportsMultipleSelections {
                    Image(systemName: "checkmark")
                        .opacity(checkmarkOpacity)
                        .animation(.default, value: pickedMacros)
                }
                Text(macro.description)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
        .disabled(shouldDisable)
    }
    
    var microSections: some View {
        func shouldShowGroup(_ group: NutrientTypeGroup) -> Bool {
            guard let hasUnusedMicros else { return true }
            return hasUnusedMicros(group, searchText)
        }

        return ForEach(NutrientTypeGroup.allCases) {
            if shouldShowGroup($0) {
                sectionForGroup($0)
            }
        }
    }
    
    func sectionForGroup(_ group: NutrientTypeGroup) -> some View {
        func shouldShowNutrient(_ nutrientType: NutrientType) -> Bool {
            guard let hasMicronutrient else { return true }
            return !hasMicronutrient(nutrientType)
        }

        return Section(group.description) {
            ForEach(group.nutrients) {
                if shouldShowNutrient($0) {
                    cell(for: $0)
                }
            }
        }
    }
    
    func cell(for nutrientType: NutrientType) -> some View {
        var shouldInclude: Bool
        if !searchText.isEmpty {
            shouldInclude = nutrientType.matchesSearchString(searchText)
        } else {
            shouldInclude = true
        }
        return Group {
            if shouldInclude {
                button(for: nutrientType)
            }
        }
    }
    
    func button(for nutrientType: NutrientType) -> some View {
        Button {
            if supportsMultipleSelections {
                Haptics.feedback(style: .soft)
                if pickedNutrientTypes.contains(nutrientType) {
                    pickedNutrientTypes.removeAll(where: { $0 == nutrientType })
                } else {
                    pickedNutrientTypes.append(nutrientType)
                }
            } else {
                pickedNutrientTypes.append(nutrientType)
                dismissWithSelections()
            }
        } label: {
            HStack {
                if supportsMultipleSelections {
                    Image(systemName: "checkmark")
                        .opacity(pickedNutrientTypes.contains(nutrientType) ? 1 : 0)
                        .animation(.default, value: pickedNutrientTypes)
                }
                Text(nutrientType.description)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
    }
    
    func didSubmit() { }
    
    var pickedNutrientsCount: Int {
        var count = 0
        if energyIsPicked {
            count += 1
        }
        count += pickedMacros.count + pickedNutrientTypes.count
        return count
    }
    
    func dismissWithSelections() {
        didAddNutrients(energyIsPicked, pickedMacros, pickedNutrientTypes)
        Haptics.successFeedback()
        dismiss()
    }
    
    var navigationLeadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if pickedNutrientsCount > 0, supportsMultipleSelections {
                Button {
                    dismissWithSelections()
                } label: {
                    Text("Add \(pickedNutrientsCount)")
                        .fontWeight(.bold)
//                        .font(.footnote)
                        .foregroundColor(.white)
                        .frame(height: 32)
                        .padding(.horizontal, 8)
//                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.accentColor.gradient)
        //                        .fill(Color.accentColor.opacity(
        //                            colorScheme == .dark ? 0.1 : 0.15
        //                        ))
                        )
                }
            }
        }
    }
    var navigationTrailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                CloseButtonLabel()
            }
        }
    }
}

struct NutrientsPickerPreview: View {
    var body: some View {
        NutrientsPicker(
            supportsEnergyAndMacros: true,
            shouldShowEnergy: true,
            shouldShowMacro: { macro in
                true
            },
            shouldDisableLastMacroOrEnergy: true,
            hasUnusedMicros: { _, _ in
                return true
            },
            hasMicronutrient: { _ in
                false
            },
            didAddNutrients: { _, _, _ in
                
            }
        )
    }
}

struct NutrientsPicker_Previews: PreviewProvider {
    static var previews: some View {
        NutrientsPickerPreview()
    }
}
