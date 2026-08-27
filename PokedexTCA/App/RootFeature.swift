import ComposableArchitecture

/// Reducer raíz. Contiene todas las features de nivel superior.
///
/// De momento solo la lista, pero está preparado para crecer sin
/// refactor (favoritos como pantalla, ajustes, etc.).
@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var pokemonList = PokemonListFeature.State()
    }

    enum Action {
        case pokemonList(PokemonListFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.pokemonList, action: \.pokemonList) {
            PokemonListFeature()
        }
    }
}
