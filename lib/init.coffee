{BufferedProcess, CompositeDisposable} = require "atom"
{XRegExp}   = require "xregexp"
{Process}   = require "process"

hdRegex = ".+?:(?<line>\\d+):(?<col>\\d+):\\s+((?<warning>Warning:)|(?<error>))\\s*\
          (?<message>(\\s+.*\\n)+)"

hdRegexFlags = ""

trimMessage = (str) ->
  lines  = str.split("\n")
  tlines = lines.map (l) -> l.trim()
  return tlines.join("\n")

matchError = (fp, match) ->
  line = Number(match.line) - 1
  col  = Number(match.col) - 1
  tmsg = trimMessage(match.message)
  # console.log("trim message:" + tmsg)
  type: if match.warning then "Warning" else "Error",
  text: tmsg, #match.message,
  filePath: fp,
  multiline: true,
  range: [ [line, col], [line, col + 1] ]

infoErrors = (fp, info) ->
  # console.log ("begin:" + info + ":end")
  if (!info)
    return []
  errors = []
  regex = XRegExp hdRegex #, hdRegexFlags
  for msg in info.split(/\r?\n\r?\n/)
    XRegExp.forEach msg, regex, (match, i) ->
      e = matchError(fp, match)
      # console.log("error:", e)
      errors.push(e)
  return errors

getUserHome = () ->
  p = process.platform
  v = if p == "win32" then "USERPROFILE" else "HOME"
  # console.log(p, v)
  process.env[v]

module.exports =
  config:
    hdevtoolsSocketPath:
      title: "The hdevtools socket path."
      type: "string"
      default: getUserHome() + "/.hdevtools-socket-atom-lint"

    hdevtoolsUseStack:
      title: "Use stack to start hdevtools (recommended if hdevtools was installed using stack)."
      type: "boolean"
      default: false

    hdevtoolsExecutablePath:
      title: "The hdevtools executable path."
      type: "string"
      default: "hdevtools"

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe "linter-hdevtools.hdevtoolsSocketPath",
      (socketPath) =>
        @socketPath = socketPath
    @subscriptions.add atom.config.observe "linter-hdevtools.hdevtoolsUseStack",
      (useStack) =>
        @useStack = useStack
    @subscriptions.add atom.config.observe "linter-hdevtools.hdevtoolsExecutablePath",
      (executablePath) =>
        @executablePath = executablePath

  deactivate: ->
    @subscriptions.dispose()
    # TODO(SN): delete socket file?

  provideLinter: ->
    provider =
      grammarScopes: ["source.haskell"]
      scope: "file" # or "project"
      lintOnFly: true # must be false for scope: "project"
      lint: (textEditor) =>
        return new Promise (resolve, reject) =>
          filePath = textEditor.getPath()
          message  = []
          # console.log ("exec: " + @executablePath)
          # console.log ("path: " + textEditor.getPath())
          # console.log ("zog : " + getUserHome())
          command = @executablePath
          args = [ "check", "-s" , @socketPath , "-g" , "-Wall" , filePath ]
          if @useStack
            command = "stack"
            args = [ "exec", "--no-ghc-package-path", "hdevtools", "--" ].concat(args)
          # console.warn(command, args)
          process = new BufferedProcess
            command: command
            args: args
            stderr: (data) ->
              message.push data
            stdout: (data) ->
              message.push data
            exit: (code) ->
              info = message.join("\n").replace(/[\r]/g, "");
              resolve infoErrors(filePath, info)
              # if info? then resolve infoErrors(filePath, info) else resolve []

          process.onWillThrowError ({error,handle}) ->
            console.error("Failed to run", command, args, ":", message)
            reject "Failed to run #{command} with args #{args}: #{error.message}"
            handle()
