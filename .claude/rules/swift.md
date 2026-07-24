---
paths: "**/*.swift"
---

## Coding Rules

- Always insert a blank line before a return statement when there is preceding logic, between variable declarations inside a function, and before any processing whose meaning changes relative to the preceding lines.

  ```swift
  // Good
  let a = 1
  
  a + 1
  
  // Bad
  let a = 1
  a + 1
  
  // Good
  func test() {
      let a = 1
  
      return a
  }
  
  // Bad
  func test() {
      let a = 1
      return a
  }

  // Good
  var calendar: Calendar = .init(
      identifier: .gregorian
  )
  calendar.locale = .init(identifier: "ja_JP")

  let formatStyle: Date.FormatStyle = .init(
      locale: .init(identifier: "ja_JP"),
      calendar: calendar,
      timeZone: .autoupdatingCurrent
  )

  Date.now.formatted(formatStyle.year().month().day())

  // Bad
  var calendar: Calendar = .init(
      identifier: .gregorian
  )
  calendar.locale = .init(identifier: "ja_JP")
  let formatStyle: Date.FormatStyle = .init(
      locale: .init(identifier: "ja_JP"),
      calendar: calendar,
      timeZone: .autoupdatingCurrent
  )
  Date.now.formatted(formatStyle.year().month().day())
  ```
  
- Do not omit type annotations.

  ```swift
  // Good
  let a: Int = 1
  
  // Bad
  let a = 1
  ```
  
- Use .init only when the type is explicit on that line.

  ```swift
  // Good
  let a: User = .init()
  
  // Bad
  a = .init()
  ```
  
  - However, type annotations may be omitted for static func, static var / let, and enum cases.
    - Example:

      ```swift
      enum UserType {
          case admin
          case user
      }

      let userType: UserType = .admin

      self.userType = .user

      self.action = .hoge()
      

      struct User {
          let name: String
          let type: UserType
      }

      extension User {
          static let admin: User = .init(name: "admin", type: .admin)
          static let user: User = .init(name: "user", type: .user)
      }

      self.user = .admin
      ```

- Boolean variable names must use prefixes such as is, has, can, or should. Avoid imperative naming. Flags for sheet presentation should be named like is~Presented.

  ```swift
  // Good
  let isEnabled: Bool = true
  let hasPermission: Bool = false
  let canEdit: Bool = true
  let shouldShowAlert: Bool = false
  
  // Bad
  let enabled: Bool = true
  let permission: Bool = false
  let edit: Bool = true
  let showAlert: Bool = false
  ```

- Do not abbreviate variable names.

```swift
// Good
let lengthBytes
let index

// Bad
let lenBytes
let idx
```

- For naming rules other than the above, follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
- Also refer to the [Google Swift Style Guide](https://google.github.io/swift/).

## API Design Rules

Use Apple framework API design as the standard. When in doubt, decide based on "how Apple would write it." Android Kotlin-style patterns such as namespace objects, factory methods, and oversized type declaration bodies are prohibited.

- Do not gather constants of other types into an enum used only as a namespace.

  ```swift
  // Bad example (a Kotlin object-style constants container; this shape does not exist in Apple APIs)
  enum JapanIDPhotoSizes {
      static let w24h30: FaceOccupancyIDPhotoSizeSpecification = ...
      static let w30h40: FaceOccupancyIDPhotoSizeSpecification = ...
  }

  // Good example 1: Represent a fixed set as a String-backed enum and use rawValue as the persistent ID
  enum JapanIDPhotoSize: String {
      case w24xh30 = "jp.w24h30"
      case w30xh40 = "jp.w30h40"
  }

  // Good example 2: Add them as statics on their own type (like UTType.jpeg)
  extension UTType {
      static let jpeg: UTType = ...
  }

  // Good example 3: Add default protocol instances under where Self == ... (like SwiftUI's ButtonStyle.bordered)
  extension IDPhotoSizeSpecification where Self == OriginalSizeSpecification {
      static var original: OriginalSizeSpecification { .init() }
  }
  ```

- Write type conversions as init methods on the destination type, such as a convenience initializer. Do not create factory or conversion methods such as fromX(), parseToX(), or toX().

  ```swift
  // Good
  extension CIColor {
      convenience init?(idPhotoBackgroundColor: IDPhotoBackgroundColor)
  }

  // Bad
  extension IDPhotoBackgroundColor {
      var ciColor: CIColor? { ... }          // Conversion property
      static func fromStoredComponents(...)  // Factory method
  }
  ```

- Keep the main type declaration minimal, and separate protocol conformances, nested types, and helpers into extensions.

  - Exceptions: `View` and `Identifiable`. Declare conformance to these two directly on the main type declaration instead of in a separate extension.
    - `View`: splitting `body` out into an extension makes the type harder to read for no benefit.
    - `Identifiable`: if the `id` needs to be supplied by the caller (e.g. via an initializer parameter), it must be a stored property declared on the main type declaration, which an extension cannot provide.

  ```swift
  // Good
  struct User: View, Identifiable {
      let id: UUID

      var body: some View { ... }
  }

  extension User: Equatable {
      static func == (lhs: User, rhs: User) -> Bool { ... }
  }

  // Bad
  struct User {
      let id: UUID
  }

  extension User: View {
      var body: some View { ... }
  }

  extension User: Identifiable {}
  ```

- Do not put UI-convenience properties in the model layer, such as visibility flags, picker lists, or ordering for display. UI policy belongs to the View / ViewContainer side.
- Declare constants with static let and camelCase, not UPPER_SNAKE_CASE, following the Google Swift Style Guide.

  ```swift
  // Good
  static let defaultBackgroundColor: IDPhotoBackgroundColor = .blue

  // Bad
  static let DEFAULT_BACKGROUND_COLOR: IDPhotoBackgroundColor = .blue
  ```

- Do not write an init on a struct if it only initializes instance properties. Rely on the memberwise initializer. Only write an init when special conversion or validation is needed.

## Documentation Comments

Documentation comments using /// are abstract documentation intended for users of the API who do not know the internal implementation. They are not notes about the implementation itself.

- Write only about the caller's concerns, such as what is returned, when it throws, and contractual details like coordinate systems.
- Internal implementation details, such as "this is computed because protocol extensions cannot have stored properties" or "it is written this way because ...," are out of scope. If internal notes are needed, use regular comments with //.
- Internal notes for private members should also use //.
- Do not cram supplementary details into the summary using parentheses. Put them on a new line using Discussion-style formatting.

  ```swift
  // Good
  /// The rectangle of the face including hair
  ///
  /// The width is the width of the face boundingBox, the top edge is crownY, and the bottom edge is chinY
  let faceWithHairRect: CGRect

  // Bad
  /// The rectangle of the face including hair (The width is the width of the face boundingBox, the top edge is crownY, and the bottom edge is chinY)
  let faceWithHairRect: CGRect
  ```

- Do not use doc comments to arbitrarily prescribe what a property is "used for." How it is used is up to the caller. Only factual information should be written, such as how the value is defined or the conditions under which it becomes nil. Only when a usage should be avoided may you document that with warning-level notation such as - Important:.

## MARK Comments

- Use MARK comments only when you need to make the boundaries between meaningful implementation blocks explicit. Do not add them unnecessarily.
- Do not use them as explanatory notes for individual lines or properties. Unnecessary MARK comments create noise in the symbol list and make it harder to jump to the intended location. Use regular // comments for explanations instead.
