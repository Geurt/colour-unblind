$ ->

  canvas      = document.getElementById "picture"
  context     = canvas.getContext "2d"
  image       = document.getElementById "image"
  draw_freq   = 40  # millisec, so really period: once every x ms
  window.draw_frames = 10  # how many frames should a pixel light up?
  window.r_weight = window.g_weight = window.b_weight = 100
  # save 100*sin for performance
  window.sin = []
  for i in [0..100]
    window.sin[i] = Math.round(100*Math.sin(2*Math.PI*i/100))

  $(image).on "load", ->
    context.drawImage(image,0,0,300,150)
    window.imagedata = context.getImageData(0,0,300,150)
    window.pixels = imagedata.data

    setupPixelData()

  setupPixelData = ->
    # we create an array which, for each pixel, looks like
    # [r,g,b,y,luminance,period,timer]
    # so keep in mind, it needs to be transversed by steps of 7
    window.pixeldata = []
    j = 0

    pixels = window.pixels              # the actual canvas data
    pixeldata = window.pixeldata        # the original canvas data, enriched
    for i in [0..pixels.length] by 4
      r = pixels[i]
      g = pixels[i+1]
      b = pixels[i+2]
      y = pixels[i+3]

      # save original data
      pixeldata[j]    = r       # original r channel
      pixeldata[j+1]  = g       # original g channel
      pixeldata[j+2]  = b       # original b channel
      pixeldata[j+3]  = y       # original y channel

      # calculate luminance
      l = Math.round(0.2126 * r + 0.7152 * g + 0.0722 * b)
      pixeldata[j+4]  = l

      # calculate period
      pixeldata[j+5]  = setPeriod(r,g,b)

      # set timer
      pixeldata[j+6]  = 0

      j += 7

    drawCanvas()


  setPeriod = (r,g,b) ->
      r_w = window.r_weight
      b_w = window.b_weight
      g_w = window.b_weight
      # some reasonable formula to derive a frequency for the original colour
      # weights in [-100..100]
      # rgb in [0..255]
      # unnormalized freq in -25500..25500 * 3 = -76500..76500
      # trunc to positive: 0..25500
      # normalize to ~ 1/5000..1/20 = 0,0002 - 0,05, so say:
      # frequency = (r_weight * r + g_weight * g + b_weight * b) / 500000
      # educated guess:
      period = Math.round(1000000 / (r_w * r + g_w * g + b_w * b))

  resetPeriods = ->
    pixeldata = window.pixeldata
    for j in [0..pixeldata.length] by 7
      r = pixeldata[j]
      g = pixeldata[j+1]
      b = pixeldata[j+2]
      pixeldata[j+5] = setPeriod(r,g,b)

  setPixels = ->
    j = 0
    pixels = window.pixels
    pixeldata = window.pixeldata

    console.log pixeldata[403]

    for i in [0..pixels.length] by 4
      timer = pixeldata[j+6]
      period = pixeldata[j+5]
      luminance = pixeldata[j+4]

      intensity = luminance / 100 * (1 + window.sin[Math.round(100 * timer / period)])

      # (this is the actual drawing)
      pixels[i] = pixels[i+1] = pixels[i+2] = intensity

      # we check if the individual period is reached
      if timer > period
        # reset individual timer
        pixeldata[j+6] = 0

      # we tick the pixels individual timer
      pixeldata[j+6] += 1

      j += 7

  drawCanvas = ->
    # actual drawing
    setPixels()
    imagedata = window.imagedata
    context.putImageData(imagedata,0,0)

    # ...and repeat
    setTimeout(drawCanvas, draw_freq)

  $("input").on "change", ->
    window.r_weight = document.getElementById("r").value
    window.g_weight = document.getElementById("g").value
    window.b_weight = document.getElementById("b").value

    resetPeriods()
