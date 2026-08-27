import ComposableArchitecture
import SwiftUI

struct FiltersView: View {
    @Bindable var store: StoreOf<FiltersFeature>

    var body: some View {
        Form {
            Section("Tipos") {
                ForEach(PokemonType.allCases) { type in
                    Toggle(type.displayName, isOn: Binding(
                        get: { store.selectedTypes.contains(type) },
                        set: { on in
                            var next = store.selectedTypes
                            if on {
                                next.insert(type)
                            } else {
                                next.remove(type)
                            }
                            store.selectedTypes = next
                        }
                    ))
                }
            }

            if !store.selectedTypes.isEmpty {
                Section {
                    Button("Limpiar", role: .destructive) {
                        store.send(.clearTapped)
                    }
                }
            }
        }
        .navigationTitle("Filtros")
    }
}
