'use strict'

app = angular.module 'Scrumble', [
  'ng'
  'ngResource'
  'ngAnimate'
  'ngSanitize'
  'ngMaterial'
  'md.data.table' # soon included in ngMaterial
  'ui.router'
  # 'ui.bootstrap'
  'app.templates'
  'Parse'
  'LocalStorageModule'
  'satellizer'
  'permission'
  'trello-api-client'

  'Scrumble.sprint'
  'Scrumble.common'
  'Scrumble.daily-report'
  'Scrumble.gmail-client'
  'Scrumble.feedback'
  'Scrumble.login'
  'Scrumble.settings'
  'Scrumble.storage'
  'Scrumble.board'
]

app.config (
  $locationProvider
  $urlRouterProvider
  ParseProvider
) ->

  $locationProvider.hashPrefix '!'

  $urlRouterProvider.otherwise '/'

  ParseProvider.initialize(
    "UTkdR7MH2Wok5lyPEm1VHoxyFKWVcdOKAu6A4BWG", # Application ID
    "DGp8edP1LHPJ15GpDE3cp94bBaDq2hiMSqLEzfZB"  # REST API Key
  )
app.config (localStorageServiceProvider) ->
  localStorageServiceProvider.setPrefix ''

app.config (TrelloClientProvider) ->
  TrelloClientProvider.init {
    key: '2dcb2ba290c521d2b5c2fd69cc06830e'
    appName: 'Scrumble'
    tokenExpiration: 'never'
    scope: ['read', 'account'] #, 'write']
  }

app.config ($mdIconProvider) ->
  $mdIconProvider
    .defaultIconSet 'icons/mdi.light.svg'

app.run ($rootScope, $state) ->
  $rootScope.$state = $state

app.config ($stateProvider) ->
  $stateProvider
  .state 'tab',
    abstract: true
    templateUrl: 'common/states/base.html'
    controller: 'BaseCtrl'
    resolve:
      project: (ScrumbleUser, Project) ->
        ScrumbleUser.getCurrentUser()
        .then (user) ->
          new Project user.project
        .catch (err) ->
          console.log err
          return null
      sprint: (ScrumbleUser, Sprint, $state) ->
        ScrumbleUser.getCurrentUser()
        .then (user) ->
          return $state.go 'trello-login' unless user?
          return $state.go 'tab.project' unless user.project?
          Sprint.getActiveSprint user.project
        .then (sprint) ->
          $state.go 'tab.new-sprint' unless sprint?
          sprint
