import ComposableArchitecture
import SwiftUI

struct PokemonDetailView: View {
    @Bindable var store: StoreOf<PokemonDetailFeature>

    private var isFavorite: Bool {
        store.favorites.contains(store.pokemon.id)
    }

    var body: some View {
        List {
            Section {
                AsyncImage(url: store.pokemon.spriteURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
            }

            Section("Tipos") {
                Text(store.pokemon.types.map(\.capitalized).joined(separator: ", "))
            }

            Section("Información") {
                switch store.extra {
                case .idle, .loading:
                    HStack {
                        ProgressView()
                        Text("Cargando detalle…")
                            .foregroundStyle(.secondary)
                    }
                case let .loaded(detail):
                    LabeledContent("Altura", value: "\(detail.height) dm")
                    LabeledContent("Peso", value: "\(detail.weight) hg")
                    LabeledContent("Habilidades",
                                   value: detail.abilities.map(\.capitalized).joined(separator: ", "))
                case let .failed(message):
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(store.pokemon.name.capitalized)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.favoriteTapped)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .primary)
                }
                .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Marcar como favorito")
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
