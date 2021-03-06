# SciVerse API abstraction

define [
  "jquery",
  "underscore",
  "backbone",
  "utils/Events"
], ($, _, Backbone, Events) ->
  exports = {}

  # Represents the SciVerse API. Only create one of these, it piggy-backs on
  # the actual Sciverse API structure, which is global.
  class exports.API
    constructor: (@api_key) ->
      sciverse.setApiKey @api_key

  # Represents a SciVerse search. Only use one at a time - due to how the
  # underlying SciVerse api works, new searches clobber ones mid-processing.
  class exports.Search extends Events
    per_page: 15

    sort: "Relevancy"

    order: "Descending"

    constructor: (@api, @options) ->
      @cache = {}
      @query = @options["query"]
      if not @query
        throw "You must provide a search query."
      @per_page = @options["per_page"] if @options["per_page"]
      @sort = @options["sort"] if @options["sort"]
      @order = @options["order"] if @options["order"]

    # Fetches a given page, firing the 'results' event once it has been
    # located (or the 'errors' event if there is a problem). Results are
    # cached locally. Pages are 0-indexed.
    fetch_page: (n) ->
      if n in @cache
        @_results @cache[n]
      else
        @searchObj = new searchObj
        @searchObj.setNumResults @per_page
        @searchObj.setSearch @query
        @searchObj.setSort @sort
        @searchObj.setSortDirection @order
        @searchObj.setOffset(@per_page * n)
        sciverse.setCallback =>
          if sciverse.areSearchResultsValid()
            @total_results = sciverse.getTotalHits()
            results = sciverse.getSearchResults()
            results["page"] = n
            @_results results
        sciverse.setErrorCallback =>
            @_errors sciverse._errors
        sciverse.runSearch @searchObj

    _results: (results) ->
      page = results["page"]
      @cache[page] = results
      @trigger "results", results

    _errors: (errors) ->
      @trigger "errors", errors

  exports