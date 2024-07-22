# Overloaded string literals

`OverloadedStrings`

:   Since:   GHC 6.8.1

    Enable overloaded string literals (e.g. string literals desugared
    via the `IsString` class).

GHC supports *overloaded string literals*. Normally a string literal has
type `String`, but with overloaded
string literals enabled (with `OverloadedStrings`) a
string literal has type `(IsString a) => a`.

This means that the usual string syntax can be used, e.g., for
`ByteString`, `Text`, and other variations of string like types. String
literals behave very much like integer literals, i.e., they can be used
in both expressions and patterns. If used in a pattern the literal will
be replaced by an equality test, in the same way as an integer literal
is.

The class `IsString` is defined as:

```haskell
class IsString a where
    fromString :: String -> a
```

The only predefined instance is the obvious one to make strings work as
usual:

```haskell
instance IsString [Char] where
    fromString cs = cs
```

The class `IsString` is not in scope by
default. If you want to mention it explicitly (for example, to give an
instance declaration for it), you can import it from module
`Data.String`.

Haskell's defaulting mechanism ([Haskell Report, Section 4.3.4](https://www.haskell.org/onlinereport/decls.html#sect4.3.4))
is extended to cover string literals, when
`OverloadedStrings` is
specified. Specifically:

-   Each type in a `default`
    declaration must be an instance of `Num`
    *or* of `IsString`.
-   If no `default` declaration is
    given, then it is just as if the module contained the declaration
    `default( Integer, Double, String)`.
-   The standard defaulting rule is extended thus: defaulting applies
    when all the unresolved constraints involve standard classes *or*
    `IsString`; and at least one is a
    numeric class *or* `IsString`.

So, for example, the expression `length "foo"`
will give rise to an ambiguous use of
`IsString a0` which, because of the
above rules, will default to `String`.

A small example:

```haskell
module Main where

import Data.String( IsString(..) )

newtype MyString = MyString String deriving (Eq, Show)
instance IsString MyString where
    fromString = MyString

greet :: MyString -> MyString
greet "hello" = "world"
greet other = other

main = do
    print $ greet "hello"
    print $ greet "fool"
```

Note that deriving `Eq` is necessary
for the pattern matching to work since it gets translated into an
equality comparison.

---
© Copyright 2023, GHC Team.

Adapted from
<https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/overloaded_strings.html>
(accessed 2024-06-21 14:45 BST).
