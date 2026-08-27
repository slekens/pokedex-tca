import ComposableArchitecture
import Foundation

@Reducer
struct PokemonDetailFeature {
    @ObservableState
    struct State: Equatable {
        let pokemon: Pokemon
        var extra: LoadState<PokemonDetail> = .idle
        @Shared(.favorites) var favorites
    }

    enum Action {
        case onAppear
        case detailReceived(PokemonDetail)
        case detailFailed(String)
        case favoriteTapped
        case closeTapped
    }

    @Dependency(\.pokemonClient) var pokemonClient
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if case .loaded = state.extra { return .none }
                state.extra = .loading
                let id = state.pokemon.id
                return .run { [pokemonClient] send in
                    let detail = try await pokemonClient.fetchDetail(id)
                    await send(.detailReceived(detail))
                } catch: { error, send in
                    await send(.detailFailed(error.localizedDescription))
                }

            case let .detailReceived(detail):
                state.extra = .loaded(detail)
                return .none

            case let .detailFailed(message):
                state.extra = .failed(message)
                return .none

            case .favoriteTapped:
                let id = state.pokemon.id
                state.$favorites.withLock { favorites in
                    if favorites.contains(id) {
                        favorites.remove(id)
                    } else {
                        favorites.insert(id)
                    }
                }
                return .none

            case .closeTapped:
                return .run { _ in await self.dismiss() }
            }
        }
    }
}
