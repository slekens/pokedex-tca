import ComposableArchitecture
import SwiftUI

struct PokemonListView: View {
    @Bindable var store: StoreOf<PokemonListFeature>

    var body: some View {
        contentView
            .navigationTitle("Pokédex")
            .searchable(text: $store.query.sending(\.queryChanged))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        FiltersView(store: store.scope(state: \.filters, action: \.filters))
                    } label: {
                        Image(systemName: store.filters.selectedTypes.isEmpty
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.detail, action: \.destination.detail)
            ) { detailStore in
                PokemonDetailView(store: detailStore)
            }
            .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var contentView: some View {
        switch store.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .loaded(pokemons) where pokemons.isEmpty:
            ContentUnavailableView.search

        case let .loaded(pokemons):
            loadedList(pokemons)

        case let .failed(message):
            errorView(message)
        }
    }

    private func loadedList(_ pokemons: [Pokemon]) -> some View {
        List {
            ForEach(pokemons) { pokemon in
                Button {
                    store.send(.rowTapped(pokemon))
                } label: {
                    PokemonRow(
                        pokemon: pokemon,
                        isFavorite: store.favorites.contains(pokemon.id)
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    if pokemon.id == pokemons.last?.id {
                        store.send(.reachedEnd)
                    }
                }
            }
            if store.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Algo salió mal").font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Reintentar") { store.send(.retryTapped) }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
