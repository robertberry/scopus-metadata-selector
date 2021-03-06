# Search router

define [
  "jquery",
  "underscore",
  "backbone",
  "config",
  "sciverse"
], ($, _, Backbone, config, sciverse) ->
  # Routes for querying Scopus database
  class SearchRouter extends Backbone.Router
    routes:
      "search/:query": "search"

    initialize: (@options) ->

    filter_query: (query) ->
      # Get rid of any chars that are not letters, spaces or digits
      # Scopus API gets confused especially by parentheses, which are part of
      # its special search syntax.
      query.replace(/[^\w\s\d]/g, "")

    search: (query) ->
      search = new sciverse.Search @options['sciverse'],
        per_page: config.results_per_page
        query: @filter_query(query)
      @trigger "search", search
