
define [
  "extensions/MustacheView",
  "text!templates/more_results.html"
], (MustacheView, template) ->
  class MoreResults extends Backbone.View
    tagName: "div"

    events:
      "click": "on_click"

    attributes:
      class: "more_results"

    template: template

    initialize: (@options) ->
      @search = @options["staggered_search"]

      @search.search.on "results", =>
        if @more()
          @render()
          @$el.show()
        else
          @$el.hide()

    more: ->
      @search.how_many_more()

    on_click: ->
      @search.next()
      @$el.hide()
