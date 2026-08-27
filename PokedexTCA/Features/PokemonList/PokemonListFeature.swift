import ComposableArchitecture
import Foundation

@Reducer
struct PokemonListFeature {
    @ObservableState
    struct State: Equatable {
        var loadState: LoadState<[Pokemon]> = .idle
        var isLoadingMore = false
        var canLoadMore = true
        var query: String = ""
        var filters = FiltersFeature.State()
        @Presents var destination: Destination.State?
        @SharedReader(.favorites) var favorites
    }

    enum Action {
        case onAppear
        case retryTapped
        case listReceived([Pokemon])
        case listFailed(String)
        case reachedEnd
        case moreReceived([Pokemon])
        case moreFailed(String)
        case rowTapped(Pokemon)

        case queryChanged(String)
        case searchReceived([Pokemon])
        case searchFailed(String)

        case filters(FiltersFeature.Action)
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.pokemonClient) var pokemonClient
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case initial, more, search }
    private let pageSize = 20

    var body: some ReducerOf<Self> {
        Scope(state: \.filters, action: \.filters) {
            FiltersFeature()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                if case .loaded = state.loadState { return .none }
                return startInitialLoad(state: &state)

            case .retryTapped:
                return startInitialLoad(state: &state)

            case let .listReceived(list):
                state.loadState = .loaded(list)
                state.canLoadMore = list.count == pageSize
                return .none

            case let .listFailed(message):
                state.loadState = .failed(message)
                return .none

            case .reachedEnd:
                guard
                    case let .loaded(current) = state.loadState,
                    state.canLoadMore,
                    !state.isLoadingMore,
                    state.query.isEmpty
                else { return .none }
                state.isLoadingMore = true
                let offset = current.count
                let types = state.filters.selectedTypes
                return .run { [pokemonClient, pageSize] send in
                    let more = try await pokemonClient.fetchList(pageSize, offset, types)
                    await send(.moreReceived(more))
                } catch: { error, send in
                    await send(.moreFailed(error.localizedDescription))
                }
                .cancellable(id: CancelID.more, cancelInFlight: true)

            case let .moreReceived(more):
                guard case var .loaded(current) = state.loadState else { return .none }
                current.append(contentsOf: more)
                state.loadState = .loaded(current)
                state.isLoadingMore = false
                state.canLoadMore = more.count == pageSize
                return .none

            case .moreFailed:
                state.isLoadingMore = false
                return .none

            case let .rowTapped(pokemon):
                state.destination = .detail(PokemonDetailFeature.State(pokemon: pokemon))
                return .none

            case let .queryChanged(text):
                state.query = text
                guard !text.isEmpty else {
                    // Usuario borró la búsqueda: cancelamos la búsqueda en
                    // vuelo y volvemos al listado inicial.
                    state.loadState = .idle
                    return .merge(
                        .cancel(id: CancelID.search),
                        .send(.onAppear)
                    )
                }
                state.loadState = .loading
                return .run { [pokemonClient, clock] send in
                    try await clock.sleep(for: .milliseconds(300))
                    let results = try await pokemonClient.search(text)
                    await send(.searchReceived(results))
                } catch: { error, send in
                    if error is CancellationError { return }
                    await send(.searchFailed(error.localizedDescription))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case let .searchReceived(results):
                state.loadState = .loaded(results)
                state.canLoadMore = false
                return .none

            case let .searchFailed(message):
                state.loadState = .failed(message)
                return .none

            case .filters(.binding(\.selectedTypes)):
                // Cambio de filtros: recargamos aplicando los nuevos criterios.
                return startInitialLoad(state: &state)

            case .filters:
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func startInitialLoad(state: inout State) -> Effect<Action> {
        state.loadState = .loading
        state.canLoadMore = true
        let types = state.filters.selectedTypes
        return .run { [pokemonClient, pageSize] send in
            let list = try await pokemonClient.fetchList(pageSize, 0, types)
            await send(.listReceived(list))
        } catch: { error, send in
            await send(.listFailed(error.localizedDescription))
        }
        .cancellable(id: CancelID.initial, cancelInFlight: true)
    }
}
