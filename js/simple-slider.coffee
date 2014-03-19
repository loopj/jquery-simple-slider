###
 jQuery Simple Slider

 Copyright (c) 2012 James Smith (http://loopj.com)

 Licensed under the MIT license (http://mit-license.org/)
###

(($, window) ->

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
        highlight: false

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
      @slider.attr("id", @input.attr("id") + "-slider") if @input.attr("id")
      
      @track = @createDivElement("track")
        .css
          width: "100%"
      
      if @settings.highlight
        # Create the highlighting track on top of the track
        @highlightTrack = @createDivElement("highlight-track")
          .css
            width: "0"
      
      # Create the slider drag target
      @dragger = @createDivElement("dragger")

      # Adjust dimensions now elements are in the DOM
      @slider.css
        minHeight: @dragger.outerHeight()
        marginLeft: @dragger.outerWidth()/2
        marginRight: @dragger.outerWidth()/2

      @track.css
        marginTop: @track.outerHeight()/-2
  
      if @settings.highlight
        @highlightTrack.css
          marginTop: @track.outerHeight()/-2

      @dragger.css
        marginTop: @dragger.outerHeight()/-2
        marginLeft: @dragger.outerWidth()/-2

      # Hook up drag/drop mouse events
      @track
        .mousedown (e) =>
          @trackEvent(e)

      if @settings.highlight
        @highlightTrack
          .mousedown (e) =>
            @trackEvent(e)

      @dragger
        .mousedown (e) =>
          return unless e.which == 1

          # We've started moving
          @dragging = true
          @dragger.addClass "dragging"

          # Update the slider position
          @domDrag(e.pageX, e.pageY)

          false

      $("body")
        .mousemove (e) =>
          if @dragging
            # Update the slider position
            @domDrag(e.pageX, e.pageY)

            # Always show a pointer when dragging
            $("body").css cursor: "pointer"


        .mouseup (e) =>
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
        @input.val(@value)
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

    # Create the basis of the track-div(s)
    createDivElement: (classname) ->
      item = $("<div>")
        .addClass(classname)
        .css
          position: "absolute"
          top: "50%"
          userSelect: "none"
          cursor: "pointer"
        .appendTo @slider
      return item
    

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

    # Respond to an event on a track
    trackEvent: (e) -> 
      return unless e.which == 1

      @domDrag(e.pageX, e.pageY, true)
      @dragging = true
      false

    # Respond to a dom drag event
    domDrag: (pageX, pageY, animate=false) ->
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
        @highlightTrack.animate width: position, 200 if @settings.highlight
      else
        @dragger.css left: position
        @highlightTrack.css width: position if @settings.highlight

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

      @input
        .val(value)
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
      settings.snap = $el.data("slider-snap")
      settings.equalSteps = $el.data("slider-equal-steps")
      settings.theme = $el.data("slider-theme") if $el.data("slider-theme")
      settings.highlight = $el.data("slider-highlight") if $el.attr("data-slider-highlight")
      settings.animate = $el.data("slider-animate") if $el.data("slider-animate")?

      # Activate the plugin
      $el.simpleSlider settings

) @jQuery or @Zepto, this
