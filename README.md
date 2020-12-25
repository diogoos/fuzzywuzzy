# fuzzywuzzy

This is an in-progress port of [seatgeek's fuzzywuzzy](https://github.com/seatgeek/fuzzywuzzy/) Python library to Swift.
There are no behavior changes, however, there are many interface changes. For instance, instead of having the `fuzz` class,
the code has been ported into String extensions.

## Sources
The heavy lifting is done mainly by an underlying C-library [python-Levenshtein](https://github.com/miohtama/python-Levenshtein),
which has been stripped of its Python interfacing [in this port](https://github.com/Tmplt/python-Levenshtein/blob/master/Levenshtein.c),
and has been wrapped into Swift code (in this library!).

| files in `Source/` | Python equivalent |
| ----- | ----------------------- |
|`Fuzzywuzzy/Fuzzywuzzy.swift` | String extensions that match the `fuzz.py` class |
| `Fuzzywuzzy/StringMatcher.swift` | Python-to-Swift translations of the Python library and python-Levenshtein's `StringMatcher.py`. Also a wrapper of  `ratio_py`, `get_opcodes_py`, `get_matching_blocks_py`, etc. from python-Levenshtein |
| `Fuzzywuzzy/TokenFunctions.swift` | Token functions that do not fit in an extension, originally in `fuzz.pu` |
| `Fuzzywuzzy/utils.swift` | Utility functions, translated from the Python library's `utils.py`. |
| `Levenshtein/levenshtein.{c,h}` | The underlaying C functions, copied verbatim. |

Tests for all the token functions and the String extensions can also be found in the `Tests/` folder.

## Usage
```swift
import Fuzzywuzzy
```

### Simple Ratio
```swift
"this is a test".ratio(to: "did you know this is a test") // returns 68
```

### Partial Ratio
```swift
"this is a test".partialRatio(to: "did you know this is a test") // returns 100
```

### Weighted Ratio
```swift
"this is an interesting test".weightedRatio(to: "this is a test!") // returns 86
```

### Direct usage of the StringMatcher class
```swift
let matcher = StringMatcher(compare: "this is interesting", to: "this is cool")

let ratio = matcher.ratio() // ratio of one string to another
let opcodes = matcher.opcodes() // levshtein operation codes
let matchingBlcoks = matcher.matchingBlocks() // blocks that match in each string
```

### Direct usage of TokenFunctions
Find ratios by sorting tokens or creating sets based on them.
Internally used for weighted ratios, can also be used publically for other reasons.
```swift
// Sorted ratio
let regularRatio = "fuzzy wuzzy was a bear".ratio(to: "wuzzy fuzzy was a bear") // returns 91
let sortedRatio = TokenFunctions.tokenSortRatio("fuzzy wuzzy was a bear", "wuzzy fuzzy was a bear") // returns 100

// Set-based ratio
let dupRatio = TokenFunctions.tokenSortRatio("fuzzy was a bear", "fuzzy fuzzy was a bear") // returns 84
let setRatio = TokenFunctions.tokenSetRatio("fuzzy was a bear", "fuzzy fuzzy was a bear") // returns 100
```

## License
Fuzzywuzzy (Swift) can be copied and/or modified under the terms of GNU General Public License.
See the file COPYING for full license text.

This package is a port of Python-Levenshtein and Fuzzywuzzy (python), both of which are also licensed
under the terms of the GNU General Public License.
