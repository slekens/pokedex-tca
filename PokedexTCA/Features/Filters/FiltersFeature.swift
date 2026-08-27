import ComposableArchitecture

/// Sub-feature de filtros por tipo.
///
/// Vive aparte porque tiene su propio estado y podría usarse desde
/// otra pantalla mañana (por ejemplo, favoritos filtrados). El padre
/// escucha `.binding(\.selectedTypes)` para saber cuándo recargar.
@Reducer
struct FiltersFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTypes: Set<PokemonType> = []
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case clearTapped
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .clearTapped:
                state.selectedTypes = []
                return .none
            case .binding:
                return .none
            }
        }
    }
}
