
require "lovekit.support"

{graphics: g} = love

export ^

import insert, remove from table

class Transition
  new: (@before, @after) =>

  -- return: alive
  update: => false
  draw: =>

class FadeTransition extends Sequence
  time: 0.4
  color: {80, 80, 80}

  new: (@before, @after) =>
    @p = 0
    super -> tween @, @time, p: 1.0

  update: (dt) =>
    @after\update dt if @p > 0.5
    super dt

  draw: =>
    alpha = if @p < 0.5
      @before\draw!
      @p * 2
    else
      @after\draw!
      (1 - @p) * 2

    {_r, _g, _b} = @color
    g.setColor _r, _g, _b, alpha * 255
    g.rectangle "fill", 0, 0, g.getWidth!, g.getHeight!
    g.setColor 255,255,255

-- handles a stack of objects that can respond to events
class Dispatcher
  default_transition: Transition

  new: (initial) =>
    @stack = { initial }
    initial\on_show self if initial.on_show

  send: (event, ...) =>
    current = @top!
    current[event] current, ... if current and current[event]

  top: => @stack[#@stack]
  parent: => @stack[#@stack - 1]

  reset: (initial) =>
    @stack = {}
    @push initial

  push: (state, transition=@default_transition) =>
    @transition = if transition and @top!
      transition @top!, state

    insert @stack, state
    state\on_show self if state.on_show

  pop: (n=1, transition=@default_transition) =>
    @transition = if transition
      transition @top!,@stack[#@stack - n]

    while n > 0
      love.event.push "quit" if #@stack == 0
      top = @top!
      top\on_hide self if top and top.on_hide

      remove @stack
      n -= 1

    new_top = @top!
    if new_top and new_top.on_show
      new_top\on_show self, true

  bind: (love) =>
    for fn in *{"draw", "update", "keypressed", "mousepressed", "mousereleased"}
      func = self[fn]
      love[fn] = (...) -> func self, ...

  keypressed: (key, code) =>
    return if @send "on_key",  key, code
    switch key
      when "escape"
        love.event.push "quit"

  mousepressed: (...) => @send "mousepressed", ...
  mousereleased: (...) => @send "mousereleased", ...

  draw: =>
    if t = @transition
      t\draw!
    else
      @send "draw"

  update: (dt) =>
    if t = @transition
      unless t\update dt
        @transition = nil
    else
      @send "update", dt

