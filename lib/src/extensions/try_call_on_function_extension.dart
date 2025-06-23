//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

/// Provides a safe, dynamic invocation method for any `Function`.
extension $TryCallOnFunctionExtension on Function {
  /// Invokes the function dynamically, returning `null` if it throws an exception.
  ///
  /// This method uses `Function.apply` to call the function with a given
  /// set of [positionalArguments] and [namedArguments].
  ///
  /// The generic type `<A>` can be specified if all arguments are of the same
  /// type, but it defaults to `dynamic` to support functions with mixed-type
  /// arguments (e.g., `(String, int)`).
  ///
  /// {@tool snippet}
  /// ```dart
  /// void main() {
  ///   // --- Example 1: Function with a single argument type ---
  ///   String repeat(String s, int times) => s * times;
  ///
  ///   // Here we could specify `<Object>` or the default `<dynamic>`.
  ///   final result1 = repeat.tryCall<String>(['Hello ', 2]);
  ///   print(result1); // Prints: Hello Hello
  ///
  ///
  ///   // --- Example 2: Function with named arguments ---
  ///   String greet({required String name, String title = 'Dr.'}) => '$title $name';
  ///
  ///   final result2 = greet.tryCall<String>([], {#name: 'Alice', #title: 'Ms.'});
  ///   print(result2); // Prints: Ms. Alice
  ///
  ///
  ///   // --- Example 3: Failure case ---
  ///   int parseInt(String s) => int.parse(s);
  ///
  ///   // Throws FormatException, which is caught and returns null.
  ///   final result3 = parseInt.tryCall<int>(['not a number']);
  ///   print(result3); // Prints: null
  /// }
  /// ```
  /// {@end-tool}
  T? tryCall<T, A extends Object?>(
    List<A>? positionalArguments, [
    Map<Symbol, A>? namedArguments,
  ]) {
    try {
      // Function.apply expects List<dynamic>, so we pass the args as-is.
      // The generic <A> provides compile-time checking for the caller.
      return Function.apply(
            this,
            positionalArguments ?? [],
            namedArguments ?? {},
          )
          as T?;
    } catch (_) {
      // Catches any exception during invocation (e.g., wrong argument types,
      // internal errors) and returns null.
      return null;
    }
  }
}
