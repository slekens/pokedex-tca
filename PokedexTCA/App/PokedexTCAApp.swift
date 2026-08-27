import ComposableArchitecture
import SwiftUI

@main
struct PokedexTCAApp: App {
    static let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PokemonListView(
                    store: PokedexTCAApp.store.scope(
                        state: \.pokemonList,
                        action: \.pokemonList
                    )
                )
            }
        }
    }
}
