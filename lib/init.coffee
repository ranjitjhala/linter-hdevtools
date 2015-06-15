module.exports =
  config:
    hdevtoolsExecutablePath:
      type: 'string'
      default: 'hdevtools'
  activate: ->
    console.log 'activate linter-hdevtools'
