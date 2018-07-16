## 0.10.8

* Set SDK version constraint to `>=2.0.0-dev.65 <3.0.0`.

## 0.10.7

* Bug fix: Make bit shifts work at bitwidth boundaries. Previously,
  `new Int64(3) << 64 == Int64(3)`. This ensures that the result is 0 in such
  cases.
* Updated maximum SDK constraint from 2.0.0-dev.infinity to 2.0.0.

## 0.10.6

* Fix `Int64([int value])` constructor to avoid rounding error on intermediate
  results for large negative inputs when compiled to JavaScript. `new
  Int64(-1000000000000000000)` used to produce the same value as
  `Int64.parseInt("-1000000000000000001")`

## 0.10.5

* Fix strong mode warning in overridden `compareTo()` methods.

*No changelog entries for previous versions...*
