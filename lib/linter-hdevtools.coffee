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
         (?<message>(\\s+.*\\n)+)'

  # regexFlags: 'gms'
  # regex: '.+?:(?<line>\\d+):(?<col>\\d+):\\s+((?<warning>Warning:)|(?<error>))\\s*\
  #         (?<message>.*)'

  constructor: (editor) ->
    super(editor)

    @disposables = new CompositeDisposable

    @disposables.add atom.config.observe 'linter-hdevtools.hdevtoolsExecutablePath', @formatShellCmd

    filePath = editor?.buffer.file?.path

    @cmd = @cmd.concat ['-p', filePath]

  lintFile: (filePath, callback) ->
    super(filePath, callback)

  formatShellCmd: =>
    hdevtoolsExecutablePath = atom.config.get 'linter-hdevtools.hdevtoolsExecutablePath'
    @executablePath = "#{hdevtoolsExecutablePath}"

  formatMessage: (match) ->
    unless (match.message)
      warn "Regex does not match lint output", match

    "\n   " + "#{match.message}"

  destroy: ->
    super
    @disposables.dispose()

module.exports = LinterHdevtools
