angular.module 'NotSoShitty.bdc'
.controller 'CurrentSprintCtrl', (
  $scope
  $state
  $timeout
  $mdDialog
  $mdMedia
  sprintUtils
  TrelloClient
  trelloUtils
  dynamicFields
  svgToPng
  sprint
  project
  Sprint
) ->
  $scope.sprint = sprint
  $scope.project = project

  dynamicFields.project project
  dynamicFields.sprint sprint

  if sprint.bdcData?
    # the date is saved as a string so we've to convert it
    for day in sprint.bdcData
      day.date = moment(day.date).toDate()
  sprint.bdcData = sprintUtils.generateBDC sprint.dates.days, sprint.resources, sprint.bdcData
  dynamicFields.render project.settings?.bdcTitle
  .then (title) ->
    $scope.bdcTitle = title
  $scope.bdcData = sprint.bdcData

  $scope.showConfirmNewSprint = (ev) ->
    confirm = $mdDialog.confirm()
      .title 'Start a new sprint'
      .textContent 'Starting a new sprint will end this one'
      .targetEvent ev
      .ok 'OK'
      .cancel 'Cancel'
    $mdDialog.show(confirm).then ->
      Sprint.close(sprint).then ->
        $state.go 'tab.new-sprint'

  $scope.openMenu = ($mdOpenMenu, ev) ->
    originatorEv = ev
    $mdOpenMenu ev

  $scope.openEditTitle = (ev) ->
    useFullScreen = ($mdMedia 'sm' or $mdMedia 'xs')
    $mdDialog.show(
      controller: DialogController
      templateUrl: 'sprint/states/current-sprint/editBDCTitle.html'
      parent: angular.element(document.body)
      targetEvent: ev
      clickOutsideToClose: true
      fullscreen: useFullScreen
      resolve:
        title: -> project.settings?.bdcTitle
        availableFields: -> dynamicFields.getAvailableFields()
    ).then (title) ->
      project.settings ?= {}
      project.settings.bdcTitle = title
      project.save().then (project) ->
        dynamicFields.render project.settings?.bdcTitle
      .then (title) ->
        $scope.bdcTitle = title

  $scope.openEditBDC = (ev) ->
    useFullScreen = ($mdMedia 'sm' or $mdMedia 'xs')
    $mdDialog.show(
      controller: 'EditBDCCtrl'
      templateUrl: 'sprint/states/current-sprint/editBDC.html'
      parent: angular.element(document.body)
      targetEvent: ev
      clickOutsideToClose: true
      fullscreen: useFullScreen
      resolve:
        data: -> angular.copy sprint.bdcData
        doneColumn: -> sprint.doneColumn
    ).then (data) ->
      $scope.bdcData = data
      sprint.bdcData = data
      $timeout -> # bdc needs to be rendered before getting the png
        svg = d3.select('#bdcgraph')[0][0].firstChild
        sprint.bdcBase64 = svgToPng.getPngBase64 svg
        sprint.save()

  DialogController = ($scope, $mdDialog, title, availableFields) ->
    $scope.title = title
    $scope.availableFields = availableFields
    $scope.hide = ->
      $mdDialog.hide()
    $scope.cancel = ->
      $mdDialog.cancel()
    $scope.save = ->
      $mdDialog.hide $scope.title

  #To manage Speed dial button

  $scope.dailyReport = ->
    $state.go 'tab.daily-report'

  self = this
  self.hidden = false
  self.isOpen = false
  self.hover = false
  self.icon = 'menu'
  # On opening, add a delayed property which shows tooltips after the speed dial has opened
  # so that they have the proper position; if closing, immediately hide the tooltips
  $scope.$watch 'menu.isOpen', (isOpen) ->
    if isOpen
      $timeout (->
        $scope.tooltipVisible = self.isOpen
      ), 600
    else
      $scope.tooltipVisible = self.isOpen
