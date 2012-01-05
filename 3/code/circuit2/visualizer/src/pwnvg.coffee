# Wraps a drawing element inside <svg>, like a path.
class PwnvgElement
  # Creates a wrapper around a SVG DOM element.
  #
  # @param [DOMElement] dom the DOM element.
  constructor: (@dom) ->

  # True if the element's class list includes the given argument.
  hasClass: (klass) ->
    (new RegExp('(^|\\s)' + klass + '(\\s|$)')).
        test(@dom.getAttribute('class') || '')

  # Adds a class to the element's class list.
  #
  # @return the element to facilitate method chaining
  addClass: (klass) ->
    unless @hasClass klass
      @dom.setAttribute 'class',
                        [@dom.getAttribute('class'), ' ', klass].join('').trim()
    @
    
  # Removes a class from the element's class list.
  #
  # @return the element to facilitate method chaining
  removeClass: (klass) ->
    list = @dom.getAttribute 'class'
    @dom.setAttribute 'class',
        list.replace(new RegExp('(^|\\s)' + klass + '(\\s|$)'), ' ').trim()
    @

  # Sets the element's id.
  #
  # @return the element to facilitate method chaining
  id: (newId) ->
    @dom.id = newId
    @
    
  # Removes the element from the SVG.
  #
  # @return the element to facilitate method chaining
  remove: ->
    @dom.parentNode.removeChild @dom
    @
    
  # Moves the element above all the other elements in its container.
  moveToTop: ->
    parent = @dom.parentNode
    parent.removeChild @dom
    parent.appendChild @dom
    @
    
  # Moves the element below all the other elements in its container.
  moveToBottom: ->
    parent = @dom.parentNode
    parent.removeChild @dom
    parent.insertBefore @dom, parent.firstChild
    @
    
  # Sets the element's fill color.
  fill: (colorSpec) ->
    @dom.setAttributeNS null, 'fill', colorSpec
    @

  # Sets the element's stroke color.
  stroke: (colorSpec) ->
    @dom.setAttributeNS null, 'stroke', colorSpec
    @

  # Sets the element's stroke width.
  strokeWidth: (width) ->
    @dom.setAttributeNS null, 'stroke-width', width.toString()
    @

  # Sets the element's height.
  #
  # Most useful for <symbol>.
  height: (height) ->
    @dom.setAttributeNS null, 'height', height.toString()
    @

  # Sets the element's width.
  #
  # Most useful for <symbol>.
  width: (width) ->
    @dom.setAttributeNS null, 'width', width.toString()
    @

  # Sets the element's viewBox.
  #
  # Most useful for <symbol>.
  viewBox: (minX, minY, maxX, maxY) ->
    @dom.setAttributeNS null, 'viewBox',
                        "#{minX} #{minY} #{maxX - minX} #{maxY - minY}"
    @

  # Sets the element's preserveAspectRatio attribute.
  #
  # Most useful for <symbol>.
  aspectRatio: (preserveAspectRatio) ->
    @dom.setAttributeNS null, 'preserveAspectRatio', preserveAspectRatio
    @

# Wraps a SVG element that can hold drawing commands.
#
# Example SVG elements are <svg>, <g>, and <defs>.
class PwnvgContainer extends PwnvgElement
  # Creates a path inside the SVG container.
  path: (pathData) ->
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'path'
    newDom.setAttributeNS null, 'd', pathData.toString()
    @dom.appendChild newDom
    new PwnvgElement newDom

  # Creates a rectangle inside the SVG container.
  rect: (x1, y1, x2, y2) ->
    [x2, x1] = [x1, x2] if x1 > x2
    [y2, y1] = [y1, y2] if y1 > y2
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'rect'
    newDom.setAttributeNS null, 'x', x1
    newDom.setAttributeNS null, 'y', y1
    newDom.setAttributeNS null, 'width', x2 - x1
    newDom.setAttributeNS null, 'height', y2 - y1
    @dom.appendChild newDom
    new PwnvgElement newDom

  # Creates a circle inside the SVG container.
  circle: (x, y, r) ->
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'circle'
    newDom.setAttributeNS null, 'cx', x
    newDom.setAttributeNS null, 'cy', y
    newDom.setAttributeNS null, 'r', r
    @dom.appendChild newDom
    new PwnvgElement newDom
  
  # Creates a symbol inside the SVG container.
  #
  # Ideally, the symbol should be created in a <defs> container.
  symbol: (id) ->
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'symbol'
    newDom.id = id
    @dom.appendChild newDom
    new PwnvgContainer newDom

  # Creates a group inside the SVG container.
  group: ->
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'g'
    @dom.appendChild newDom
    new PwnvgContainer newDom
    
  # Instantiates a previously defined object.
  use: (uri, x, y, width, height) ->
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'use'
    newDom.setAttributeNS 'http://www.w3.org/1999/xlink', 'href', uri
    newDom.setAttributeNS null, 'x', x
    newDom.setAttributeNS null, 'y', y
    newDom.setAttributeNS null, 'width', width
    newDom.setAttributeNS null, 'height', height
    @dom.appendChild newDom
    new PwnvgElement newDom
  
  # Parses some raw SVG as a drawing element and injects it into the tree.
  rawSvgElem: (svgText) ->
    new PwnvgElement @insertRawSvg(svgText)

  # Parses some raw SVG as a container and injects it into the tree.
  rawSvgGroup: (svgText) ->
    new PwnvgContainer @insertRawSvg(svgText)
    
  # Parses a string containing a SVG fragment into this element's DOM tree.
  #
  # Returns the last created DOM element.
  insertRawSvg: (svgText) ->
    parser = new DOMParser
    svgStart = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
    svgEnd = '</svg>'
    svgDoc = parser.parseFromString [svgStart, svgText, svgEnd].join(''),
                                    'image/svg+xml'
    document = @dom.ownerDocument
    for node in svgDoc.rootElement.childNodes
      if node.nodeType == Node.ELEMENT_NODE
        @dom.appendChild document.importNode(node)
    @dom.lastNode

  # Fast insertRawSvg implementation broken in today's W3C standard + browsers.
  insertRawSvg2: (svgText) ->
    #   Chrome: http://crbug.com/107982
    #   Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=711821
    range = @dom.ownerDocument.createRange()
    range.selectNodeContents @dom
    newDom = range.createContextualFragment svgText
    @dom.appendChild newDom
    @dom.lastChild

  # Helper for building a path data string.
  #
  # @return a new PwnvgPathBuilder instance
  @path: ->
    new PwnvgPathBuilder


# Wraps a <svg> element.
class Pwnvg extends PwnvgContainer
  # Creates a SVG element inside a container.
  #
  # @param domContainer a DOM element that will receive the new SVG element
  # @param minX left of the SVG coordinate system
  # @param maxX right of the SVG coordinate system
  # @param minY top of the SVG coordinate system
  # @param maxY bottom of the SVG coordinate system
  constructor: (domContainer, @minX, @minY, @maxX, @maxY) ->
    newDom = document.createElementNS 'http://www.w3.org/2000/svg', 'svg'
    newDom.setAttributeNS null, 'version', '1.1'
    newDom.setAttributeNS 'http://www.w3.org/2000/xmlns/', 'xmlns:xlink',
                          'http://www.w3.org/1999/xlink'
    newDom.setAttributeNS 'http://www.w3.org/2000/xmlns/', 'xmlns',
                          'http://www.w3.org/2000/svg'
    super newDom
    @viewBox @minX, @minY, @maxX, @maxY
    domContainer.appendChild newDom
  
    # Build out the <defs> section of the <svg>.
    defsDom = document.createElementNS 'http://www.w3.org/2000/svg', 'defs'
    newDom.appendChild defsDom
    @defs = new PwnvgContainer defsDom


# Builder for path data strings.
class PwnvgPathBuilder
  # Creates an empty path.
  constructor: ->
    @command = []
    
  # Adds an absolute-move command to the path.
  #
  # @param x the X coordinate to move the pen to
  # @param y the Y coordinate to move the pen to
  # @return the path builder to facilitate method chaining
  moveTo: (x, y) ->
    @command.push 'M'
    @command.push x
    @command.push ','
    @command.push y
    @

  # Adds a relative-move command to the path.
  #
  # @param x how much to move the pen along the X axis
  # @param x how much to move the pen along the Y axis
  # @return the path builder to facilitate method chaining
  moveBy: (dx, dy) ->
    @command.push 'm'
    @command.push dx
    @command.push ','
    @command.push dy
    @

  # Adds an absolute-move-and-draw-line command to the path.
  #
  # @param x the X coordinate to move the pen to
  # @param y the Y coordinate to move the pen to
  # @return the path builder to facilitate method chaining
  lineTo: (x, y) ->
    @command.push 'L'
    @command.push x
    @command.push ','
    @command.push y
    @

  # Adds a relative-move-and-draw-line command to the path.
  #
  # @param x how much to move the pen along the X axis
  # @param x how much to move the pen along the Y axis
  # @return the path builder to facilitate method chaining
  lineBy: (dx, dy) ->
    @command.push 'l'
    @command.push dx
    @command.push ','
    @command.push dy
    @
    
  # Closes the path.
  #
  # @return the path builder to facilitate method chaining
  close: ->
    @command.push 'Z'
    @

  # The path data string constructed by this builder.
  toString: ->
    @command.join ''


# Export the Pwnvg class.
window.Pwnvg = Pwnvg
