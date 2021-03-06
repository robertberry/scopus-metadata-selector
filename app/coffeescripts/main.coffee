# Main script

require.config
  paths:
    jquery: "libs/jquery/jquery-min"
    underscore: "libs/underscore/underscore-min"
    backbone: "libs/backbone/backbone-min"
    text: "libs/require/text"
    Mustache: "libs/mustache/mustache"
    templates: "../templates"

require [
  "jquery",
  "sciverse",
  "config"
  "Renderer",
  "collections/Documents",
  "collections/EPrints",
  "collections/Warnings",
  "collections/Errors",
  "views/SearchResults",
  "views/JSONField",
  "views/CountSubmit",
  "views/ErrorMessages",
  "views/Spinner",
  "routers/SearchRouter",
  "controllers/StaggeredSearch",
  "views/MoreResults"
], ($, sciverse, config, Renderer, Documents, EPrints, Warnings, Errors, \
    SearchResults, JSONField, CountSubmit, ErrorMessages, Spinner, SearchRouter, \
    StaggeredSearch, MoreResults) ->
  api = new sciverse.API(config.api_key)
  app = new SearchRouter(sciverse: api)

  selectors = config.selectors

  search_form = $(selectors.search_form)
  search_input = $(selectors.search_input)
  search_submit = $(selectors.search_submit)
  import_form = $(selectors.import_form)
  results_container = $(selectors.results_container)
  more_container = $(selectors.more_container)
  spinner_container = $(selectors.spinner_container)

  search_results = new Documents()
  selected_results = new Documents()
  selected_eprints = EPrints.mirroring_documents(selected_results)
  results = new SearchResults(collection: search_results)

  import_input = new JSONField(collection: selected_eprints, utf8: yes)
  import_input.$el.attr "name", config.parameter_name
  import_input.render()
  import_button = new CountSubmit
    collection: selected_results
    template: "Import (<%= count %>)"
    disable_on_zero: yes
  # hide import submit till results
  import_button.$el.hide()
  import_form.append import_input.el
  import_form.append import_button.el

  errors = new Errors()
  error_messages = new ErrorMessages(collection: errors)
  search_form.after error_messages.el

  current_search = null

  spinner = new Spinner()
  spinner_container.html spinner.el
  spinner.hide()
  spinner.render()

  results_container.html results.el
  
  app.on "search", (search) ->
    current_search = new StaggeredSearch(search_results, search)
    current_search.on "load_page", ->
      spinner.show()
    current_search.on "page_loaded", ->
      spinner.hide()
    current_search.on "page_errors", ->
      spinner.hide()    
  
    search_more = new MoreResults(staggered_search: current_search)
    more_container.html(search_more.el)
  
    current_search.next()
    search_results.reset()
    selected_results.reset()

    search_input.val search.query
    search_submit.attr "disabled", yes
    results_container.hide()
    spinner.show()
    import_button.$el.hide()

    search.on "results", (data) ->
      search_submit.attr "disabled", no
      results_container.show()
      spinner.hide()
      import_button.$el.show()
      errors.reset []

    search.on "errors", (errs) ->
      search_submit.attr "disabled", no
      results_container.hide()
      errors.reset {error_message: err} for err in errs

  results.on "select", (document) ->
    selected_results.add document
  results.on "deselect", (document) ->
    selected_results.remove document
  
  search_form.submit (event) ->
    event.preventDefault()
    app.navigate("search/" + search_input.val(), trigger: yes)

  Backbone.history.start pushState: no
