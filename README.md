# linter-hdevtools

This package will lint your opened Haskell in Atom, using [hdevtools](https://hackage.haskell.org/package/hdevtools).

![linter-hdevtools in action](https://raw.githubusercontent.com/ranjitjhala/linter-hdevtools/master/screenshot.png)


## Installation

* Install [hdevtools](https://hackage.haskell.org/package/hdevtools)
* `$ apm install linter` (if you don't have [AtomLinter/Linter](https://github.com/AtomLinter/Linter) installed)
* `$ apm install language-haskell` (for [Haskell syntax highlighting](https://github.com/jroesch/language-haskell) installed)
* `$ apm install linter-hdevtools`
* Specify the path to `hdevtools` in the settings.  You can find the path by using `which hdevtools` in the terminal

## TODO

* Somehow get either `warnings` or `error` but not both. Is this `hdevtools` at work? Or some issue with the regexp?
