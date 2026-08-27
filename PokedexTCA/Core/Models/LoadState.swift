import Foundation

/// Estado remoto genérico para cualquier feature que cargue datos.
///
/// Modela los cuatro estados posibles de una carga y evita el clásico
/// booleano `isLoading` que no distingue "aún no he cargado" de
/// "cargué y está vacío".
enum LoadState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}
