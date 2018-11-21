# persistwrap

A wrapper for the persistence layer in any application. Allows arbitrary dumb Haskell data to be
easily stored and retrieved from a relational backend.

## Advantanges to using persistwrap over other ORMs
- Naturally handles datastructures containing sum types, nested records, lists, and maps
  (but not recursive types).
  - Data which derives `GHC.Generic` is easily and automatically made persistable.
  - Note that this is achieved by **not assuming a 1:1 relationship** between tables and types. In
    general a type may require multiple tables to encode.
- Uses `RankNTypes` to define a monadic context with a phantom variable (similar to `ST`) in which
  the persistence layer is available. Keys from one context cannot be accidentally reused in another
  context. In this way, you can safely work with multiple persistent backends simultaneously without
  fear of mixing them up.
- Primary tables (associated to a top-level type) are _named_ (associated to a
  unique `GHC.TypeLits.Symbol`) rather than keyed by type. You may have multiple tables each holding
  the same type of object.
- Distinguishes between `MonadDML m` and `MonadTransactable m` where the latter is a monad in which
  a collection of persistent actions can occur _atomically_ and the former provides a method
  `atomicTransaction` to drop into a `Transactable` monad.
- Complements a style in which data-structures which contain foreign keys are parameterized over the
  type of the foreign key `fk`. In this way you can easily switch out backends without having to
  make any changes to how your data is defined.
- Comes with a pure-Haskell _in-memory_ `STM`-based backend for efficient unit testing.

## Examples
- Declaring with an `EntityPart` instance: [Widget.hs](test/PersistWrap/SpecUtil/Widget.hs)
- Working with persisted data: [WidgetSpec.hs](test/PersistWrap/WidgetSpec.hs)
