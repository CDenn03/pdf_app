# AI Rules for Flutter

You are an expert in Flutter and Dart development. Your goal is to build beautiful, performant, and maintainable applications following modern best practices.

## Interaction Guidelines

- Assume the user is familiar with programming concepts but may be new to Dart.
- When generating code, explain Dart-specific features like null safety, futures, and streams.
- If a request is ambiguous, ask for clarification on the intended functionality and target platform.
- When suggesting new dependencies from pub.dev, explain their benefits.
- Use `dart format` to ensure consistent code formatting.
- Use `dart fix` to automatically fix common errors and conform to analysis options.
- Use the Dart linter with recommended rules to catch common issues. Run `flutter analyze`.

## Project Structure

- Standard Flutter project structure with `lib/main.dart` as the primary entry point.
- Organize code into logical layers:
  - `presentation` (widgets, screens)
  - `domain` (business logic)
  - `data` (models, API clients, DAOs)
  - `core` (shared utilities, extensions)
- For larger projects, organize by feature, each with its own presentation/domain/data subfolders.

## Flutter Style Guide

- Apply SOLID principles throughout the codebase.
- Write concise, modern, technical Dart code. Prefer functional and declarative patterns.
- Favor composition over inheritance for building complex widgets and logic.
- Prefer immutable data structures. `StatelessWidget` should always be immutable.
- Separate ephemeral state and app state. Use a state management solution for app state.
- Widgets are for UI — compose complex UIs from smaller, reusable widgets.
- Use `go_router` for declarative navigation, deep linking, and web support.

## Package Management

- To add a regular dependency: `flutter pub add <package_name>`
- To add a dev dependency: `flutter pub add dev:<package_name>`
- To remove a dependency: `dart pub remove <package_name>`

## Code Quality

- Adhere to maintainable code structure and separation of concerns.
- Avoid abbreviations; use meaningful, consistent, descriptive names.
- Write code that is as short as it can be while remaining clear.
- Write straightforward code — clever or obscure code is hard to maintain.
- Anticipate and handle potential errors. Don't let code fail silently.
- Lines should be 80 characters or fewer.
- Use `PascalCase` for classes, `camelCase` for members/variables/functions/enums, `snake_case` for files.
- Keep functions short and single-purpose. Strive for fewer than 20 lines.
- Write code with testing in mind.
- Use `dart:developer` log instead of `print`.

## Dart Best Practices

- Follow the official Effective Dart guidelines: https://dart.dev/effective-dart
- Add documentation comments to all public APIs.
- Write clear comments for complex or non-obvious code. Avoid over-commenting.
- Don't add trailing comments.
- Use `async`/`await` for asynchronous operations with robust error handling.
- Use `Future`s for single async operations; `Stream`s for sequences of async events.
- Write soundly null-safe code. Avoid `!` unless the value is guaranteed non-null.
- Use pattern matching, records, and exhaustive `switch` expressions where they simplify code.
- Use `try-catch` blocks for exception handling. Use custom exceptions for domain-specific errors.
- Use arrow syntax for simple one-line functions.

## Flutter Best Practices

- Widgets (especially `StatelessWidget`) are immutable.
- Prefer composing smaller widgets over extending existing ones.
- Use small, private `Widget` classes instead of private helper methods returning `Widget`.
- Break down large `build()` methods into smaller, reusable private Widget classes.
- Use `ListView.builder` or `SliverList` for long lists (lazy loading).
- Use `compute()` for expensive calculations to avoid blocking the UI thread.
- Use `const` constructors wherever possible to reduce rebuilds.
- Avoid expensive operations (network calls, complex computations) inside `build()`.

## State Management

- Prefer Flutter's built-in state management solutions unless a third-party package is explicitly requested.
- Use `Streams` and `StreamBuilder` for sequences of async events.
- Use `Futures` and `FutureBuilder` for single async operations.
- Use `ValueNotifier` with `ValueListenableBuilder` for simple local single-value state.
- Use `ChangeNotifier` for more complex or shared state.
- Use `ListenableBuilder` to listen to `ChangeNotifier` or other `Listenable`.
- Structure the app using MVVM when a more robust solution is needed.
- Use manual constructor dependency injection to make dependencies explicit.

## Routing (GoRouter)

```dart
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

MaterialApp.router(routerConfig: _router);
```

## Data Handling & Serialization

- Use `json_serializable` and `json_annotation` for JSON parsing/encoding.
- Use `fieldRename: FieldRename.snake` to convert camelCase fields to snake_case JSON keys.

## Logging

Use `dart:developer` for structured logging:

```dart
import 'dart:developer' as developer;

developer.log('Message here.');

try {
  // ...
} catch (e, s) {
  developer.log('Failed', name: 'myapp.network', level: 1000, error: e, stackTrace: s);
}
```

## Code Generation

- Ensure `build_runner` is a dev dependency when using code generation.
- After modifying files requiring code generation, run:

```shell
dart run build_runner build --delete-conflicting-outputs
```

## Testing

- Use `package:test` for unit tests.
- Use `package:flutter_test` for widget tests.
- Use `package:integration_test` for integration tests.
- Use `package:checks` for expressive assertions.
- Follow Arrange-Act-Assert (Given-When-Then) pattern.
- Prefer fakes/stubs over mocks. Use `mocktail` if mocks are necessary.
- Aim for high test coverage.

## Visual Design & Theming

- Build responsive UIs that adapt to different screen sizes.
- Use `LayoutBuilder` or `MediaQuery` for responsive layouts.
- Define a centralized `ThemeData` with both light and dark themes.
- Generate color palettes with `ColorScheme.fromSeed`.
- Use `ThemeExtension` for custom design tokens not in standard `ThemeData`.
- Use `google_fonts` for custom fonts; define a `TextTheme` for consistency.
- Use `Theme.of(context).textTheme` for text styles in widgets.

### Example Theme Setup

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  ),
  home: const MyHomePage(),
);
```

## Lint Rules

`analysis_options.yaml` starting point:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
```

## Accessibility

- Ensure text has a contrast ratio of at least 4.5:1 against its background.
- Test UI with increased system font sizes.
- Use the `Semantics` widget for clear, descriptive labels on UI elements.
- Regularly test with TalkBack (Android) and VoiceOver (iOS).

## Documentation

- Use `///` for doc comments on all public APIs.
- Start with a single-sentence summary ending with a period.
- Add a blank line after the summary sentence.
- Explain why code is written a certain way, not what it does.
- Include code samples where appropriate.
- Place doc comments before any metadata annotations.

## SOLID Principles

### Single Responsibility (SRP)
- Each class has one reason to change.
- Notifiers manage state only — persistence, debounce, and filtering belong in separate layers.
- Widgets coordinate UI only — notifier orchestration across multiple providers belongs in a service or dedicated notifier.
- DAOs handle data access only — mapping, querying, and persistence are their sole concern.

### Open/Closed (OCP)
- Design for extension without modification. Prefer sealed classes or abstract interfaces over stringly-typed dispatch (e.g. `byName` on enums) when adding new variants would require touching existing parsing code.
- Adding a new annotation type, route, or feature should not require modifying existing classes.

### Liskov Substitution (LSP)
- Subtypes must be substitutable for their base types without altering correctness.
- Prefer composition over inheritance to avoid LSP violations.

### Interface Segregation (ISP)
- Don't expose methods a caller doesn't need. Test-only concerns (e.g. `close()` on a singleton) should not appear on production APIs.
- Remove dead public API — if a method is never called externally, make it private or delete it.

### Dependency Inversion (DIP)
- Depend on abstractions, not concretions.
- Define abstract interfaces (e.g. `FileChecker`, `DatabaseProvider`) so implementations can be swapped in tests without hitting real I/O.
- Constructor parameters must be required and typed to the abstraction — never nullable with internal defaults:

```dart
// Bad — hides the dependency and makes testing harder
MyClass({SomeDep? dep}) : _dep = dep ?? SomeDep();

// Good — explicit, injectable, testable
MyClass({required SomeDep dep}) : _dep = dep;
```

---

## DRY — Don't Repeat Yourself

- Extract repeated literals into named constants (e.g. asset paths, durations).
- Share a single instance of utility objects like `Uuid` — declare once in `core/constants.dart`.
- Extract repeated patterns into private helpers:
  - Repeated object construction → factory method
  - Repeated state mutation + side effect → single private method
- Repeated timestamp formatting → single getter or helper function.
- When the same string, value, or logic appears in more than one file, it needs a single home.

---

## KISS — Keep It Simple, Stupid

- Prefer the simplest solution that correctly solves the problem.
- Avoid dual constructors with nullable field branching to support two code paths — use an abstract interface instead.
- Use the raw value as an identifier when it is already unique and stable (e.g. a file path as a record key) rather than transforming it with fragile regex.
- Avoid mixing async styles — use `await` consistently, never `.then()` alongside `async`/`await`.
- Extract business logic out of `build()` methods into named methods or computed properties.

---

## YAGNI — You Aren't Gonna Need It

- Don't add methods, fields, or parameters until they are actually needed.
- Delete dead code immediately — unused methods, unreachable branches, and unread state fields all add cognitive overhead.
- Don't store state that is never read from state (e.g. fields on a `freezed` class that are only written, never consumed).
- Don't write placeholder implementations for future milestones — a comment describing future work is sufficient.
- Test-only concerns (e.g. a `close()` method on a singleton) should not exist on production classes; use test-specific constructors or fakes instead.
