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
    let hasUnusedMicros: (NutrientTypeGroup, String) -> Bool
    
    /// Returns true if the specified micronutrient has been added and shouldn't be shown
    let hasMicronutrient: (NutrientType) -> Bool
    
    let supportsEnergyAndMacros: Bool
    let shouldShowMacro: ((Macro) -> Bool)?
    let shouldShowEnergy: Bool

    @State var energyIsPicked: Bool = false
    @State var pickedMacros: [Macro] = []
    @State var pickedNutrientTypes: [NutrientType] = []

    @State var searchText = ""
    @State var searchIsFocused: Bool = false
    
    public init(
        supportsEnergyAndMacros: Bool = false,
        shouldShowEnergy: Bool = false,
        shouldShowMacro: ((Macro) -> Bool)? = nil,
        hasUnusedMicros: @escaping (NutrientTypeGroup, String) -> Bool,
        hasMicronutrient: @escaping (NutrientType) -> Bool,
        didAddNutrients: @escaping (Bool, [Macro], [NutrientType]) -> Void
    ) {
        self.shouldShowMacro = shouldShowMacro
        self.shouldShowEnergy = shouldShowEnergy
        self.supportsEnergyAndMacros = supportsEnergyAndMacros
        self.didAddNutrients = didAddNutrients
        self.hasUnusedMicros = hasUnusedMicros
        self.hasMicronutrient = hasMicronutrient
    }
    
    var title: String {
        supportsEnergyAndMacros ? "Nutrients" : "Micronutrients"
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
            .navigationTitle("Add \(title)")
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
    
    @ViewBuilder
    var energySection: some View {
        if shouldShowEnergy {
            Section {
                Button {
                    Haptics.feedback(style: .soft)
                    energyIsPicked.toggle()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .opacity(energyIsPicked ? 1 : 0)
                            .animation(.default, value: energyIsPicked)
                        Text("Energy")
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }
    
    var macrosToShow: [Macro] {
        Macro.allCases.filter { macro in
            guard let shouldShowMacro, shouldShowMacro(macro) else {
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
        Button {
            Haptics.feedback(style: .soft)
            if pickedMacros.contains(macro) {
                pickedMacros.removeAll(where: { $0 == macro })
            } else {
                pickedMacros.append(macro)
            }
        } label: {
            HStack {
                Image(systemName: "checkmark")
                    .opacity(pickedMacros.contains(macro) ? 1 : 0)
                    .animation(.default, value: pickedMacros)
                Text(macro.description)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
    }
    var microSections: some View {
        ForEach(NutrientTypeGroup.allCases) {
            if hasUnusedMicros($0, searchText) {
                sectionForGroup($0)
            }
        }
    }
    
    func sectionForGroup(_ group: NutrientTypeGroup) -> some View {
        Section(group.description) {
            ForEach(group.nutrients) {
                if !hasMicronutrient($0) {
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
            Haptics.feedback(style: .soft)
            if pickedNutrientTypes.contains(nutrientType) {
                pickedNutrientTypes.removeAll(where: { $0 == nutrientType })
            } else {
                pickedNutrientTypes.append(nutrientType)
            }
        } label: {
            HStack {
                Image(systemName: "checkmark")
                    .opacity(pickedNutrientTypes.contains(nutrientType) ? 1 : 0)
                    .animation(.default, value: pickedNutrientTypes)
                Text(nutrientType.description)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
    }
    
    func didSubmit() { }
    
    var navigationTrailingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !pickedNutrientTypes.isEmpty {
                Button("Add \(pickedNutrientTypes.count)") {
                    didAddNutrients(energyIsPicked, pickedMacros, pickedNutrientTypes)
                    Haptics.successFeedback()
                    dismiss()
                }
            }
        }
    }
    var navigationLeadingContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button {
                Haptics.feedback(style: .soft)
                dismiss()
            } label: {
                closeButtonLabel
            }
        }
    }
}
