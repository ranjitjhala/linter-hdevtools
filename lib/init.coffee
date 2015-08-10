{BufferedProcess, CompositeDisposable} = require 'atom'
{XRegExp}   = require 'xregexp'
{Process}   = require 'process'

hdRegex = '.+?:(?<line>\\d+):(?<col>\\d+):\\s+((?<warning>Warning:)|(?<error>))\\s*\
          (?<message>(\\s+.*\\n)+)'

hdRegexFlags = ''

matchError = (fp, match) ->
  line = Number(match.line) - 1
  col  = Number(match.col) - 1
  type: if match.warning then 'Warning' else 'Error',
  text: match.message,
  filePath: fp,
  range: [ [line, col], [line, col + 1] ]

infoErrors = (fp, info) ->
  # console.log ("begin:" + info + ':end')
  if (!info)
    return []
  errors = []
  regex = XRegExp hdRegex #, hdRegexFlags
  for msg in info.split(/\r?\n\r?\n/)
    XRegExp.forEach msg, regex, (match, i) ->
      e = matchError(fp, match)
      # console.log('error:', e)
      errors.push(e)
  return errors

getUserHome = () ->
  p = process.platform
  v = if p == 'win32' then 'USERPROFILE' else 'HOME'
  # console.log(p, v)
  process.env[v]

module.exports =
  config:
    hdevtoolsSocketPath:
      title: 'The hdevtools socket path.'
      type: 'string'
      default: getUserHome() + '/.hdevtools-socket-atom-lint'

    hdevtoolsExecutablePath:
      title: 'The hdevtools executable path.'
      type: 'string'
      default: 'hdevtools'

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-hdevtools.hdevtoolsSocketPath',
      (socketPath) =>
        @socketPath = socketPath
    @subscriptions.add atom.config.observe 'linter-hdevtools.hdevtoolsExecutablePath',
      (executablePath) =>
        @executablePath = executablePath

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      grammarScopes: ['source.haskell']
      scope: 'file' # or 'project'
      lintOnFly: true # must be false for scope: 'project'
      lint: (textEditor) =>
        return new Promise (resolve, reject) =>
          filePath = textEditor.getPath()
          message  = []
          # console.log ("exec: " + @executablePath)
          # console.log ("path: " + textEditor.getPath())
          # console.log ("zog : " + getUserHome())
          process = new BufferedProcess
            command: @executablePath
            args: [ 'check'
                  , '-s'
                  , @socketPath
                  , '-g'
                  , '-Wall'
                  , filePath]
            stderr: (data) ->
              message.push data
            stdout: (data) ->
              message.push data
            exit: (code) ->
              # return resolve [] unless code is 0
              info = message.join('\n').replace(/[\r]/g, '');
              return resolve [] unless info?
              resolve infoErrors(filePath, info)

          process.onWillThrowError ({error,handle}) ->
            atom.notifications.addError "Failed to run #{@executablePath}",
              detail: "#{error.message}"
              dismissable: true
            handle()
            resolve []
