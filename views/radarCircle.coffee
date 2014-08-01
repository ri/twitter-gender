class circleChart

  constructor: (data) ->
    @radius = 0
    @gravity = 0
    @chargeFactor = 0
    @linkDistance = 0
    @linkStrength = 0
    @linkOpacity = 0.3
    @starting = true
    @followerCirclesOn = true
    colourOps = [
      {
        pink: "#FE0557"
        blue: "#0AABBA"
      },
      {
        pink: "#ba3cb3"
        blue: "#3b4aa6"
      },
      {
        pink: "#8e36a8"
        blue: "#355d94"
      },
      {
        pink: "#7c2867"
        blue: "#292669"
      },
      {
        pink: "#9d3495"
        blue: "#43338e"
      },
      {
        pink: "#a74188"
        blue: "#4397be"
      }
    ]
    @colours = colourOps[0]

    #containers
    @nodesData = data.nodes.filter((d) ->   d.gender is "female" or d.gender is "male")
    @linksData = data.links.filter((d) -> d.type is 'mtom' or d.type is 'mtof' or d.type is 'ftof' or d.type is 'ftom')
    @width = 1000
    @height = @width
    @center = {x: @width/2, y: @height/2}
    @geo = new Geo()
    @rings = 8
    @innerRadius = 80
    @ringScale = d3.scale.linear().domain([@rings - 1, 0]).range([@innerRadius, @width/2 - @radius])
    @femaleFollowsCount = d3.select('.connections-female')
    @maleFollowsCount = d3.select('.connections-male')

    @contain = d3.select(selection)

  setup: () =>

    @force = d3.layout.force()
      .charge(@chargeFactor)
      .gravity(@gravity)
      .linkDistance(@linkDistance)
      .linkStrength(@linkStrength)
      .size([@width, @height])
      .nodes(@nodesData)
      .links(@linksData)

    @links = @contain.selectAll("path.link")
      .data(@linksData)
      .enter()
      .append("path")
      .attr(class: 'link')

    @nodes = @contain.selectAll("g.node")
      .data(@nodesData)
      .enter()
      .append("g")
      .attr("class", "node")
      .attr('pointer-events': 'none')

    @maleCircles = @nodes.append("path").attr("class", "maleFollows").attr('pointer-events': 'none')

    @femaleCircles = @nodes.append("path").attr("class", "femaleFollows").attr('pointer-events': 'none')

    @innerCircle = @nodes.append("circle")
      .attr("class", "inner")      
      .on("mouseover", @mouseoverCircle)
      .on("mouseout", @mouseoutCircle)

    @usernameLabel = @nodes.append("text")
      .attr(class: "username")
      .text((d) -> d.username)
      .attr(x: 0)
      .attr(y: - 10)
      .attr("fill", '#ffffff')      
      .attr('text-anchor': 'middle')
      .attr('fill-opacity': 0)
      .attr('pointer-events': 'none')

    @meOverlayText = @contain.append('text')
      .style(opacity: 0)
      .attr(class: 'overlay')
      .text('This is me.')
      .attr(fill: @colours.pink)
      .attr(x: @center.x)
      .attr(y: 100)
      .attr('text-anchor': 'middle')
      .style('font-size': '18px')

    @followOverlayText = @contain.append('text')
      .style(opacity: 0)
      .attr(class: 'overlay')
      .text('These are people I follow.')
      .attr(fill: '#d3d3d3')
      .attr(x: @center.x)
      .attr(y: 240)
      .attr('text-anchor': 'middle')
      .style('font-size': '18px')

    #me node
    @me = d3.select(@nodes[0][0])
    @me.datum((d) => d.targetX = @center.x; d.targetY = @center.y; d)

    @mtmData = []
    @ftmData = []
    @ftfData = []
    @mtfData = []
    @mtmIncomingData = []
    @ftmIncomingData = []
    @ftfIncomingData = []
    @mtfIncomingData = []

    @nodes.each((d, i) =>
      d.followersCount = @links.filter((l) -> l.target is i)[0].length
      if d.gender is "female"
        unless i is 0
          followingF = @links.filter((d) -> d.source is i and not (d.target is 0) and d.type is "ftof")[0].length
          followingM = @links.filter((d) -> d.source is i and d.type is "ftom")[0].length
          followedByF = @links.filter((d) -> d.target is i and not (d.source is 0) and d.type is "ftof")[0].length
          followedByM = @links.filter((d) -> d.target is i and d.type is "mtof")[0].length
          @ftfData.push(followingF)
          @ftmData.push(followingM)
          @ftfIncomingData.push(followedByF)
          @mtfIncomingData.push(followedByM)
      else
        followingF = @links.filter((d) -> d.source is i and not (d.target is 0) and d.type is "mtof")[0].length
        followingM = @links.filter((d) -> d.source is i and d.type is "mtom")[0].length
        followedByF = @links.filter((d) -> d.target is i and not (d.source is 0) and d.type is "ftom")[0].length
        followedByM = @links.filter((d) -> d.target is i and d.type is "mtom")[0].length
        @mtfData.push(followingF)
        @mtmData.push(followingM)
        @ftmIncomingData.push(followedByF)
        @mtmIncomingData.push(followedByM)
      # console.log "#{d.username} is following #{men} men, #{women} women"
    )
    console.log @mtmData
    mData = @nodesData.filter((d) -> d.gender is "male") 
    fData = @nodesData.filter((d) -> d.gender is "female" and not(d.index is 0))


    meanMTF = d3.mean(@mtfData, (d) -> d)
    meanMTM = d3.mean(@mtmData, (d) -> d)
    medianMTF = d3.median(@mtfData, (d) -> d)
    medianMTM = d3.median(@mtmData, (d) -> d)
    meanFTF = d3.mean(@ftfData, (d) -> d)
    meanFTM = d3.mean(@ftmData, (d) -> d)
    medianFTF = d3.median(@ftfData, (d) -> d)
    medianFTM = d3.median(@ftmData, (d) -> d)

    incomingMeanMTF = d3.mean(@mtfIncomingData, (d) -> d)
    incomingMeanMTM = d3.mean(@mtmIncomingData, (d) -> d)
    incomingMedianMTF = d3.median(@mtfIncomingData, (d) -> d)
    incomingMedianMTM = d3.median(@mtmIncomingData, (d) -> d)
    incomingMeanFTF = d3.mean(@ftfIncomingData, (d) -> d)
    incomingMeanFTM = d3.mean(@ftmIncomingData, (d) -> d)
    incomingMedianFTF = d3.median(@ftfIncomingData, (d) -> d)
    incomingMedianFTM = d3.median(@ftmIncomingData, (d) -> d)
    console.log "MEAN m to f", meanMTF
    console.log "m to m", meanMTM
    console.log "MEDIAN m to f", medianMTF
    console.log "m to m", medianMTM
    console.log "MEAN f to f", meanFTF
    console.log "f to m", meanFTM
    console.log "MEDIAN f to f", medianFTF
    console.log "f to m", medianFTM

    console.log "INCOMING"
    console.log "MEAN m to f", incomingMeanMTF
    console.log "m to m", incomingMeanMTM
    console.log "MEDIAN m to f", incomingMedianMTF
    console.log "m to m", incomingMedianMTM
    console.log "MEAN f to f", incomingMeanFTF
    console.log "f to m", incomingMeanFTM
    console.log "MEDIAN f to f", incomingMedianFTF
    console.log "f to m", incomingMedianFTM

    followerMax = d3.max(@nodes.data(), (d, i) -> unless i is 0 then d.followersCount)
    @followerScale = d3.scale.log().domain([1, followerMax]).range([1, @rings - 1])

    maxFollowRadius = 40
    @followersRScale = d3.scale.linear().domain([0, followerMax]).range([0, maxFollowRadius])

    @males = @nodes.filter((d) -> d.gender is "male")
    @females = @nodes.filter((d , i) -> i != 0 and d.gender is "female")
    @allButMe = @nodes.filter((d, i) -> i != 0)
                      .sort((a , b) -> if a.gender is 'male' then -1 else 1)
    @mtof = @links.filter((d) -> d.type is 'mtof')
    @mtom = @links.filter((d) -> d.type is 'mtom')
    @metof = @links.filter((d) -> d.source is 0 and d.type is 'ftof')
    @metom = @links.filter((d) -> d.source is 0 and d.type is 'ftom')
    @ftom =  @links.filter((d) -> d.type is 'ftom' and d.source isnt 0)
    @ftof =  @links.filter((d) -> d.type is 'ftof' and d.source isnt 0)
    @combined = @links.filter((d) -> d.type is 'ftof' or d.type is 'mtom' and d.source isnt 0)
    @followingF = @links.filter((d) -> d.type is 'ftof' or d.type is 'mtof')
    @followingM = @links.filter((d) -> d.type is 'ftom' or d.type is 'mtom')
    # @cross = @links.filter((d) -> d.type is 'ftom' or d.type is 'mtof' and d.source isnt 0)
    @atome = @links.filter((d) -> d.target is 0)
    @metoa = @links.filter((d) -> d.source is 0)
    @showNodes(@nodes)

    # @contain.selectAll('circle.ring')
    #   .data([0..@rings - 1])
    #   .enter()
    #   .append('circle')
    #   .attr(class: 'ring')
    #   .attr(r: (d) => @ringScale d)
    #   .attr(cx: @center.x)
    #   .attr(cy: @center.y)
    #   .attr(fill: 'none')
    #   .attr(stroke: '#000000')
    #   .attr(opacity: 0.1)
    @drawNodes(@me)
    @drawNodes(@allButMe)
    @drawLinks(@links)
    @force.start()

    @radarLayout(@allButMe)

    @overlayArc = d3.svg.arc()
      .innerRadius(@width/2 - 10)
      .outerRadius(@width/2 - 8)
      .startAngle((d) =>
          a = -30
          @geo.d2r a
        )
      .endAngle((d) =>
          a = d.current
          @geo.d2r a
        )

    @femaleOverlay = @contain.append('path')
      .attr(class: 'overlay')
      .datum({current: -30}) 
      .attr(fill: @colours.pink)
      .attr(transform: "translate(#{@center.x},#{@center.y})")
      .attr(d: @overlayArc)
      .attr(opacity: 0.5)

    @maleOverlay = @contain.append('path') 
      .attr(class: 'overlay')
      .datum({current: -30})
      .attr(fill: @colours.blue)
      .attr(transform: "translate(#{@center.x},#{@center.y})")
      .attr(d: @overlayArc)
      .attr(opacity: 0.5)

    @femaleArcOverlayText = @contain.append('text')
      .attr(class: 'overlay')
      .text('Female')
      .attr(fill: @colours.pink)
      .attr(x: @geo.circlePoint(@center.x, @center.y, @width/8, 300).x)
      .attr(y: @geo.circlePoint(@center.x, @center.y, @width/8, 300).y)
      .attr('text-anchor': 'middle')
      .style('font-size': '18px')
      .attr(opacity: 0)
    
    @maleArcOverlayText = @contain.append('text')
      .attr(class: 'overlay')
      .text('Male')
      .attr(fill: @colours.blue)
      .attr(x: @geo.circlePoint(@center.x, @center.y, @width/8, 135).x)
      .attr(y: @geo.circlePoint(@center.x, @center.y, @width/8, 135).y)
      .attr('text-anchor': 'middle')
      .style('font-size': '18px')
      .attr(opacity: 0)    

    @force.on("tick", (e) =>
      if @starting
        @nodes.each((d) ->
          d.x = d.targetX
          d.y = d.targetY
        )
      else
        k = e.alpha * 2
        @nodes.each((d) ->
          d.x += (d.targetX - d.x) * k
          d.y += (d.targetY - d.y) * k
        )
      @nodes.attr(transform: (d) -> "translate(#{d.x},#{d.y})")
      @drawStraightLinks(@links)
    )
    @start()

  start: =>
    d3.select('.loading').transition().style(display: 'none')
    d3.select('#skip').transition().delay(1200).style(opacity: 0.6)
    @radius = 4
    @metof.attr(d: (d) =>"M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}")
    @metom.attr(d: (d) =>"M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}")
    @me.select('circle.inner').transition()
      .attr(r: @radius)
      .each('end', () =>
        @meOverlayText.transition().delay(400).style(opacity: 1)
        @meOverlayText.transition().ease("quad").duration(700).delay(1200).attr(y: @center.y - 40)
        @allButMe.select('circle.inner').transition().duration(600).delay(2600).attr(r: @radius)
        @followOverlayText.transition().delay(3200).style(opacity: 1)
        @femaleOverlay.transition().duration(1200).delay(4000).attrTween('d', @arcTween({current: 90}))
        @maleOverlay.transition().duration(1200).delay(4000).attrTween('d', @arcTween({current: -270}))
        @femaleArcOverlayText.transition().delay(5400).attr(opacity: 1)
        @maleArcOverlayText.transition().delay(6000).attr(opacity: 1)
        @metoa
          .transition()
          .duration(1200)
          .delay(7000)
          .attr(d: (d) =>
            "M #{d.source.x}, #{d.source.y}L #{d.target.x}, #{d.target.y}"
          ).each('end', @enableControls)
        @drawFollowerCircles(@nodes, 8000)
        d3.selectAll('.overlay').transition().delay(12000).duration(2000).attr(opacity: 0).each('end', () -> d3.select(this).style(display: 'none'))
      )
    
  skipIntro: =>
    d3.selectAll('*').transition().duration(0).delay(0)
    @overlaysOff()
    @metoa.attr(d: (d) => "M #{d.source.x}, #{d.source.y}L #{d.target.x}, #{d.target.y}")
    @nodes.select('circle.inner').attr(r: @radius)
    @enableControls()

  enableControls: =>
    d3.selectAll('.disabled').classed('disabled', false)
    d3.select('#skip').style(opacity: 0).on('end', () -> d3.select(this).style(display: none))
    @nodes.attr('pointer-events': 'all')
    @showLinks(@metoa)
    @updateFollows()
    @force.start()

  showNodes: (nodes, follower = false, hide = d3.select()) => 
    nodes.datum((d) -> d.visible = true; d)
    hide.datum((d) -> d.visible = false; d)
    @arrangeVisible(@allButMe)
    hide.select('.inner').transition().attr(r: 0)
    nodes.select('.inner').transition().attr(r: @radius)
    @updateFollows()
    if follower and @followerCirclesOn then @drawFollowerCircles(@nodes)

  showLinks: (links, follower = false) =>
    links.each((d) -> d.visible = true)
    if follower and @followerCirclesOn then @drawFollowerCircles(@nodes)

  showOnlyLinks: (links, follower = false) =>
    @links.each((d) -> 
      invisible = links.filter((l) -> l is d).empty()
      if invisible
        d.visible = false
      else
        d.visible = true 
    )
    @drawStraightLinks(links)
    @fadeLinks()

  fadeLinks: () =>
    @links.transition()
      .duration(400)
      .attr('stroke-opacity': (d) => if d.visible then @linkOpacity else 0)

  lightlyFadeLinks: (links) =>
    links.transition()
      .duration(400)
      .attr('stroke-opacity': (d) => if d.visible then @linkOpacity/8 else 0)

  highlightLinks: (links) =>
    links.transition()
      .duration(400)
      .attr('stroke-opacity': (d) => if d.visible then 0.6 else 0)

  lightlyFadeNodes: (nodes) =>
    nodes.transition()
      .duration(400)
      .attr('fill-opacity': 0.5)

  updateFollows: =>
    femaleFollows = @links.filter((d) -> d.visible and d.target.gender is 'female')[0].length
    maleFollows = @links.filter((d) -> d.visible and d.target.gender is 'male')[0].length

    @femaleFollowsCount.text(femaleFollows)
    @maleFollowsCount.text(maleFollows)

  resetNodes: () =>
    @nodes.transition()
      .duration(400)
      .attr('fill-opacity': 1)

  drawStraightLinks: (links) =>
    links.attr(d: (d) =>
      if d.visible
        "M #{d.source.x}, #{d.source.y}L #{d.target.x}, #{d.target.y}"
      else
        "M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}"
      )

  animateStraightLinks: (links) =>
    links.transition()
      .attr(d: (d) =>
      if d.visible
        "M #{d.source.x}, #{d.source.y}L #{d.target.x}, #{d.target.y}"
      else
        "M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}"
      )

  drawArcLinks: (links) =>
    links.attr(d: (d) =>
      if d.visible
        dx = d.target.x - d.source.x
        dy = d.target.y - d.source.y
        dr = Math.sqrt(dx * dx + dy * dy)
        nodesLength = @nodes[0].length
        mid = nodesLength/2
        posTarget = (d.target.index - d.source.index + nodesLength) % nodesLength
        if posTarget < mid
          dir = 1
        else
          dir = 0
        "M #{d.source.x}, #{d.source.y}A#{dr},#{dr} 0 0,#{dir} #{d.target.x}, #{d.target.y}"
      else
        "M #{d.source.x}, #{d.source.y}L #{d.source.x}, #{d.source.y}"
      )

  hideFollowerCircles: (nodes) =>
    defaultArc = d3.svg.arc()
          .innerRadius(0)
          .outerRadius(0)
          .startAngle(0)
          .endAngle(30)

    nodes.selectAll('path.femaleFollows, path.maleFollows')
      .transition()
      .attr(d: defaultArc)
  drawFollowerCircles: (nodes, delay = 0) =>
    nodes.each((d, i) =>
        d.maleFollowers = @links.filter((l) => l.target is d and l.source.gender is 'male' and l.visible is true)[0].length
        d.maleFollowersR = @followersRScale d.maleFollowers
        d.femaleFollowers = @links.filter((l) => l.target is d and l.source.gender is 'female' and l.visible is true)[0].length
        d.femaleFollowersR = @followersRScale d.femaleFollowers
      )

    maleArc = d3.svg.arc()
      .innerRadius((d) =>
          if not d.visible
            0
          else if d.gender is 'female'  
            @radius
          else
            @radius + d.femaleFollowersR
        )
      .outerRadius((d) =>
          if not d.visible
            0
          else if d.gender is 'female'  
            @radius + d.maleFollowersR
          else
            @radius + d.femaleFollowersR + d.maleFollowersR
      )
      .startAngle(0)
      .endAngle(30)

    femaleArc = d3.svg.arc()
      .innerRadius((d) =>
          if not d.visible
            0
          else if d.gender is 'male'  
            @radius
          else
            @radius + d.maleFollowersR
        )
      .outerRadius((d) =>
          if not d.visible
            0
          else if d.gender is 'male'  
            @radius + d.femaleFollowersR
          else
            @radius + d.femaleFollowersR + d.maleFollowersR
      )
      .startAngle(0)
      .endAngle(30)

    @nodes.selectAll('path.maleFollows')
      .attr("fill", @colours.blue)
      .attr(opacity: 0.4)
      .transition()
      .delay(delay)
      .attr(d: maleArc)
    @nodes.selectAll('path.femaleFollows')
      .attr("fill", @colours.pink)
      .attr(opacity: 0.4)
      .transition()
      .delay(delay)
      .attr(d: femaleArc)

  reset: => @force.stop(); @showOnlyLinks(@metoa); @showNodes(@allButMe, true); @force.start()
  # showMales: => @showNodes(@males); @showLinks(@metom);
  # showFemales: => @showNodes(@females); @showLinks(@metof);
  mToF: => @force.stop(); @showOnlyLinks(@mtof); @showNodes(@allButMe, true); @force.start(); 
  fToM: => @force.stop(); @showOnlyLinks(@ftom); @showNodes(@allButMe, true); @force.start(); 
  mToM: => @force.stop(); @showOnlyLinks(@mtom); @showNodes(@males, true, @females); @force.start(); 
  fToF: => @force.stop(); @showOnlyLinks(@ftof); @showNodes(@females, true, @males); @force.start(); 
  combinedMF: => @force.stop(); @showOnlyLinks(@combined); @showNodes(@allButMe, true); @force.start(); 
  # combinedCross: => @force.stop(); @showOnlyLinks(@cross); @showNodes(@allButMe, true); @force.start(); 
  fAll: => @force.stop(); @showOnlyLinks(@followingF); @showNodes(@allButMe, true); @force.start(); 
  mAll: => @force.stop(); @showOnlyLinks(@followingM); @showNodes(@allButMe, true); @force.start(); 
  full: => @force.stop(); @showOnlyLinks(@links); @showNodes(@allButMe, true); @force.start(); 

  drawNodes: (nodes) =>
    nodes.selectAll('circle.inner')
      .attr("fill", (d) =>
        if (d.gender == "female")
          fill = @colours.pink
        else if (d.gender == "male")
          fill = @colours.blue
        else 
          fill = "#d3d3d3"
      )
      .attr(r: @radius)

  drawLinks: (links) =>
    links.attr(stroke: (d) =>
        if (d.source.gender == "female")
          stroke = @colours.pink
        else if (d.source.gender == "male")
          stroke = @colours.blue
        else 
          stroke = "#d3d3d3"
      )
      .attr(fill: 'none')
      .attr('stroke-opacity': @linkOpacity)

  circularLayout: (nodes) =>
    count = nodes[0].length
    segment = 360/count


    nodes.datum((d, i) =>
      r = @width/2.2
      coord = @geo.p2c(r, i*segment)
      d.targetX = coord.x + @center.x
      d.targetY = coord.y + @center.y
      d.x = d.targetX
      d.y = d.targetY
      d
    )

  radarLayout: (nodes) =>
    count = nodes[0].length
    segment = 360/count


    nodes.datum((d, i) =>
      # console.log @followerScale d.followersCount
      r = @ringScale Math.floor(@followerScale d.followersCount)
      coord = @geo.p2c(r, i*segment)
      d.targetX = coord.x + @center.x
      d.targetY = coord.y + @center.y
      d.x = d.targetX
      d.y = d.targetY
      d
    )

  arrangeVisible: (nodes) =>
    @force.stop()
    @radarLayout(nodes.filter((d) -> d.visible is true))
    @force.start()

  arcTween: (b) =>
    (a) =>
      interpolate = d3.interpolate(a, b)
      a.current = b.current
      (t) =>
        @overlayArc(interpolate(t))

  toggleFollowerCircles: (toggle) =>
    toggleOn = toggle.classed('on')
    if toggleOn
      @hideFollowerCircles(@nodes)
      toggle.text('OFF')
      @followerCirclesOn = false
      toggle.classed('on', false)
      toggle.classed('off', true)
    else
      @drawFollowerCircles(@nodes)
      toggle.text('ON')
      @followerCirclesOn = true
      toggle.classed('on', true)
      toggle.classed('off', false)

  overlaysOff: ->
    d3.selectAll('.overlay').transition().attr(opacity: 0).each('end', () -> d3.select(this).style(display: 'none'))

  mouseoverCircle: (d) =>
    fadeLinks = @links.filter((l) -> not (l.source is d or l.target is d))
    highlightLinks = @links.filter((l) -> l.source is d or l.target is d)
    @highlightLinks(highlightLinks)
    @lightlyFadeLinks(fadeLinks)
    node = @nodes.filter((n) -> n is d)

    node.select('.username').transition().attr('fill-opacity': 1)
    @nodes.select('.inner').transition().attr("opacity", (n) -> if n is d then 1 else 0.5)
  mouseoutCircle: (d) =>
    @fadeLinks()
    node =  @nodes.filter((n) -> n is d)
    node.select('.username').transition().attr('fill-opacity': 0)
    @nodes.select('.inner').transition().attr("opacity", 1)

chart = null
selection = "body .viz-container #viz"

d3.json("/data/data4.json", (e, data) ->
  console.log data
  chart = new circleChart(data)
  chart.setup()

  d3.select('#reset').on("click", () -> chart.reset(); selectThis(this))
  # d3.select('#males_on').on("click", () -> chart.showMales())
  # d3.select('#males_off').on("click", () -> chart.hideMales())
  # d3.select('#females_on').on("click", () -> chart.showFemales())
  # d3.select('#females_off').on("click", () -> chart.hideFemales())
  d3.select('#m_to_f').on("click", () -> chart.mToF(); selectThis(this))
  d3.select('#f_to_m').on("click", () -> chart.fToM(); selectThis(this))
  d3.select('#m_to_m').on("click", () -> chart.mToM(); selectThis(this))
  d3.select('#f_to_f').on("click", () -> chart.fToF(); selectThis(this))
  d3.select('#combined').on("click", () -> chart.combinedMF(); selectThis(this))
  d3.select('#f_all').on("click", () -> chart.fAll(); selectThis(this))
  d3.select('#m_all').on("click", () -> chart.mAll(); selectThis(this))
  d3.select('#full').on("click", () -> chart.full(); selectThis(this))

  # d3.select('#all_to_me').on("click", () -> chart.toMe())
  d3.select('#outers-toggle').on("click", () -> chart.toggleFollowerCircles(d3.select(this)))
  d3.select('#skip').on("click", () -> chart.skipIntro())
)

selectThis = (el) ->
  d3.select('nav.selections .selected').classed('selected', false)
  d3.select(el).classed('selected', true)



