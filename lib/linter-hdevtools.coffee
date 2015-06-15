linterPath  = atom.packages.getLoadedPackage("linter").path
Linter      = require "#{linterPath}/lib/linter"
{log, warn} = require "#{linterPath}/lib/utils"
{CompositeDisposable} = require "atom"

class LinterHdevtools extends Linter
  @syntax: 'source.haskell' # fits all *.hs-files

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: ['hdevtools', 'check', '-g', '-Wall']

  linterName: 'hdevtools'

  regex: '.+?:(?<line>\\d+):(?<col>\\d+):\\s+((?<warning>Warning:)|(?<error>))\\s*\
          (?<message>.*)'

  # regex: '.+?:(?<line>\\d+):(?<col>\\d+):\\s+\
  #        ((?<error>)|(?<warning>Warning:))\\s*\
  #        (?<message>.*)'

  constructor: (editor) ->
    super(editor)

    @disposables = new CompositeDisposable

    @disposables.add atom.config.observe 'linter-hdevtools.hdevtoolsExecutablePath', @formatShellCmd

  lintFile: (filePath, callback) ->
    super(filePath, callback)

  formatShellCmd: =>
    hdevtoolsExecutablePath = atom.config.get 'linter-hdevtools.hdevtoolsExecutablePath'
    @executablePath = "#{hdevtoolsExecutablePath}"

  formatMessage: (match) ->
    unless match.type
      warn "Regex does not match lint output", match

    "#{match.message}"

####    "#{match.message} (#{match.type}#{match.code})"

  destroy: ->
    super
    @disposables.dispose()

module.exports = LinterHdevtools
