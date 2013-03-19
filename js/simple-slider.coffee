###
 jQuery Simple Slider

 Copyright (c) 2012 James Smith (http://loopj.com)

 Licensed under the MIT license (http://mit-license.org/)
###

(($, window) ->

  # Adds a class 'touch' to the HTML tag if this is a touch-capable device,
  # this allows our CSS to respond accordingly and, in this case, make the
  # size of the dragger 2X the size.
  if 'ontouchstart' in window
    $('html').addClass 'touch'

  #
  # Main slider class
  #

  class SimpleSlider
    # Build a slider object.
    # Exposed via el.numericalSlider(options)
    constructor: (@input, options) ->
      # Load in the settings
      @defaultOptions =
        animate: true
        snapMid: false
        classPrefix: null
        classSuffix: null
        theme: null

      @settings = $.extend({}, @defaultOptions, options)
      @settings.classSuffix = "-#{@settings.theme}" if @settings.theme

      # Hide the original input
      @input.hide()

      # Create the slider canvas
      @slider = $("<div>")
        .addClass("slider"+(@settings.classSuffix || ""))
        .css
          position: "relative"
          userSelect: "none"
          boxSizing: "border-box"
        .insertBefore @input
      if @settings.tooltip
        @tooltip = $("<div/>").addClass("tooltip")
        @slider.append( @.tooltip)
        @displayValue(Number(@input.val()))
      @slider.attr("id", @input.attr("id") + "-slider") if @input.attr("id")

      # Create the track
      @track = $("<div>")
        .addClass("track")
        .css
          position: "absolute"
          top: "50%"
          width: "100%"
          userSelect: "none"
          cursor: "pointer"
        .appendTo @slider

      # Create the slider drag target
      @dragger = $("<div>")
        .addClass("dragger")
        .css
          position: "absolute"
          top: "50%"
          userSelect: "none"
          cursor: "pointer"
        .appendTo @slider

      # Adjust dimensions now elements are in the DOM
      @slider.css
        minHeight: @dragger.outerHeight()
        marginLeft: @dragger.outerWidth()/2
        marginRight: @dragger.outerWidth()/2 + (56 if @settings.tooltip)

      @track.css
        marginTop: @track.outerHeight()/-2

      @dragger.css
        marginTop: @dragger.outerWidth()/-2
        marginLeft: @dragger.outerWidth()/-2


      # Hook up drag/drop mouse events AND touch events.  Note, we use 'on'
      # rather than 'bind', so this requires a more recent version of
      # jQuery/Zepto.

      @track.on 'touchstart mousedown', (evt) =>

        # If this mouse down isn’t the left mouse button, ignore it.  Also, If
        # this is a mousedown event, we must preventDefault to prevent
        # interacting accidentally with page content. We MUST allow the
        # default action, however for touch-based input, otherwise, it will
        # interfere with other gestures (page-scroll, pinch-to-zoom, etc.)

        if evt.type == "mousedown"
          unless evt.which is 1
            return
          evt.preventDefault()

        @domDrag(evt, true)
        @dragging = true


      @dragger.on 'touchstart mousedown', (evt) =>

        # See note above re: preventDefault() and left mouse button
        if evt.type is "mousedown"
          unless evt.which is 1
            return
          evt.preventDefault()

        # We've started moving
        @dragging = true
        @dragger.addClass "dragging"

        # Update the slider position
        @domDrag(evt, true)

        false


      $("body").on 'touchmove mousemove', (evt) =>

        # See note above re: preventDefault()
        if evt.type is "mousemove"
          evt.preventDefault();

        if @dragging
          # Update the slider position
          @domDrag(evt)

          # Always show a pointer when dragging
          $("body").css cursor: "pointer"


      $("body").on 'touchend mouseup', () =>

        if @dragging
          # Finished dragging
          @dragging = false
          @dragger.removeClass "dragging"

          # Revert the cursor
          $("body").css cursor: "auto"


      # Set slider initial position
      @pagePos = 0

      # Fill in initial slider value
      if @input.val() == ""
        @value = @getRange().min
        @displayValue(@value)
      else
        @value = @nearestValidValue(@input.val())

      @setSliderPositionFromValue(@value)

      # We are ready to go
      ratio = @valueToRatio(@value)
      @input.trigger "slider:ready",
        value: @value
        ratio: ratio
        position: ratio * @slider.outerWidth()
        el: @slider

    # Displays the value appropriately for the step value, if any, given.
    displayValue: (value) ->
      # If there is no step value, then we leave the value untouched.
      # This will allow a default slider from 0->1 to work as it did previously.
      if @settings.step && !isNaN(@settings.step)
        precision = Math.max(0, Math.ceil(Math.log(1/@settings.step)/Math.log(10)));
        value = value.toFixed(precision)
      if (this.tooltip)
        @tooltip.text(value)
      @input.val(value)

    # Set the ratio (value between 0 and 1) of the slider.
    # Exposed via el.slider("setRatio", ratio)
    setRatio: (ratio) ->
      # Range-check the ratio
      ratio = Math.min(1, ratio)
      ratio = Math.max(0, ratio)

      # Work out the value
      value = @ratioToValue(ratio)

      # Update the position of the slider on the screen
      @setSliderPositionFromValue(value)

      # Trigger value changed events
      @valueChanged(value, ratio, "setRatio")

    # Set the value of the slider
    # Exposed via el.slider("setValue", value)
    setValue: (value) ->
      # Snap value to nearest step or allowedValue
      value = @nearestValidValue(value)

      # Work out the ratio
      ratio = @valueToRatio(value)

      # Update the position of the slider on the screen
      @setSliderPositionFromValue(value)

      # Trigger value changed events
      @valueChanged(value, ratio, "setValue")

    # Respond to a dom drag event
    domDrag: (evt, animate=false) ->
      # jQuery users
      if evt.originalEvent && evt.originalEvent.touches
        {pageX, pageY} = evt.originalEvent.touches[0]

      # For Zepto users
      else if evt.touches
        {pageX, pageY} = evt.touches[0]

      # Not really sure when this would ever be used, but it probably should
      # be here.
      else
        {pageX, pageY} = evt

      # Normalize position within allowed range
      pagePos = pageX - @slider.offset().left
      pagePos = Math.min(@slider.outerWidth(), pagePos)
      pagePos = Math.max(0, pagePos)

      # If the element position has changed, do stuff
      if @pagePos != pagePos
        @pagePos = pagePos

        # Set the percentage value of the slider
        ratio = pagePos / @slider.outerWidth()

        # Trigger value changed events
        value = @ratioToValue(ratio)
        @valueChanged(value, ratio, "domDrag")

        # Update the position of the slider on the screen
        if @settings.snap
          @setSliderPositionFromValue(value, animate)
        else
          @setSliderPosition(pagePos, animate)

    # Set the slider position given a slider canvas position
    setSliderPosition: (position, animate=false) ->
      if animate and @settings.animate
        @dragger.animate left: position, 200
      else
        @dragger.css left: position

    # Set the slider position given a value
    setSliderPositionFromValue: (value, animate=false) ->
      # Get the slide ratio from the value
      ratio = @valueToRatio(value)

      # Set the slider position
      @setSliderPosition(ratio * @slider.outerWidth(), animate)

    # Get the valid range of values
    getRange: ->
      if @settings.allowedValues
        min: Math.min(@settings.allowedValues...)
        max: Math.max(@settings.allowedValues...)
      else if @settings.range
        min: parseFloat(@settings.range[0])
        max: parseFloat(@settings.range[1])
      else
        min: 0
        max: 1

    # Find the nearest valid value, checking allowedValues and step settings
    nearestValidValue: (rawValue) ->
      range = @getRange()

      # Range-check the value
      rawValue = Math.min(range.max, rawValue)
      rawValue = Math.max(range.min, rawValue)

      # Apply allowedValues or step settings
      if @settings.allowedValues
        closest = null
        $.each @settings.allowedValues, ->
          if closest == null || Math.abs(this - rawValue) < Math.abs(closest - rawValue)
            closest = this

        return closest
      else if @settings.step
        maxSteps = (range.max - range.min) / @settings.step
        steps = Math.floor((rawValue - range.min) / @settings.step)
        steps += 1 if (rawValue - range.min) % @settings.step > @settings.step / 2 and steps < maxSteps

        return steps * @settings.step + range.min
      else
        return rawValue

    # Convert a value to a ratio
    valueToRatio: (value) ->
      if @settings.equalSteps
        # Get slider ratio for equal-step
        for allowedVal, idx in @settings.allowedValues
          if !closest? || Math.abs(allowedVal - value) < Math.abs(closest - value)
            closest = allowedVal
            closestIdx = idx

        if @settings.snapMid
          (closestIdx+0.5)/@settings.allowedValues.length
        else
          (closestIdx)/(@settings.allowedValues.length - 1)

      else
        # Get slider ratio for continuous values
        range = @getRange()
        (value - range.min) / (range.max - range.min)

    # Convert a ratio to a valid value
    ratioToValue: (ratio) ->
      if @settings.equalSteps
        steps = @settings.allowedValues.length
        step = Math.round(ratio * steps - 0.5)
        idx = Math.min(step, @settings.allowedValues.length - 1)

        @settings.allowedValues[idx]
      else
        range = @getRange()
        rawValue = ratio * (range.max - range.min) + range.min

        @nearestValidValue(rawValue)

    # Trigger value changed events
    valueChanged: (value, ratio, trigger) ->
      return if value.toString() == @value.toString()

      # Save the new value
      @value = value

      # Construct event data and fire event
      eventData =
        value: value
        ratio: ratio
        position: ratio * @slider.outerWidth()
        trigger: trigger
        el: @slider

      @displayValue(value);

      @input
        .trigger($.Event("change", eventData))
        .trigger("slider:changed", eventData)


  #
  # Expose as jQuery Plugin
  #

  $.extend $.fn, simpleSlider: (settingsOrMethod, params...) ->
    publicMethods = ["setRatio", "setValue"]

    $(this).each ->
      if settingsOrMethod and settingsOrMethod in publicMethods
        obj = $(this).data("slider-object")

        obj[settingsOrMethod].apply(obj, params)
      else
        settings = settingsOrMethod
        $(this).data "slider-object", new SimpleSlider($(this), settings)


  #
  # Attach unobtrusive JS hooks
  #

  $ ->
    $("[data-slider]").each ->
      $el = $(this)

      # Build options object from data attributes
      settings = {}

      allowedValues = $el.data "slider-values"
      settings.allowedValues = (parseFloat(x) for x in allowedValues.split(",")) if allowedValues
      settings.range = $el.data("slider-range").split(",") if $el.data("slider-range")
      settings.step = $el.data("slider-step") if $el.data("slider-step")
      settings.tooltip = $el.data("slider-tooltip") if $el.data("slider-tooltip")
      settings.snap = $el.data("slider-snap")
      settings.equalSteps = $el.data("slider-equal-steps")
      settings.theme = $el.data("slider-theme") if $el.data("slider-theme")

      # Activate the plugin
      $el.simpleSlider settings

) @jQuery or @Zepto, this
