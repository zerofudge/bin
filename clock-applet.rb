#!/usr/bin/env ruby
=begin
  clock-applet.rb
                                                                                
  Copyright (c) 2004 Ruby-GNOME2 Project Team
  This program is licenced under the same licence as Ruby-GNOME2.
                                                                                
  $Id: clock-applet.rb,v 1.2 2004/06/06 17:23:04 mutoh Exp $
=end

require 'gnomecanvas2'
require 'panelapplet2'
require 'gnome2'

class Clock < Gtk::EventBox
  Point = Struct.new("Point", :x, :y)
  class Point
    def to_p
     [x,y]
    end
    def -(p)
      [x-p.x, y-p.y]
    end
  end
  def clockhandposition(center, len, val, max)
    angle = (Math::PI * (((val * 360.0) / max) - 90.0)) / 180.0
    Point.new(center.x + (len * Math.cos(angle)),
                         center.y + (len * Math.sin(angle)))
  end
  def basehandposition(center, len, val, max)
    angle = (Math::PI * ((val * 360.0) / max)) / 180.0
    Point.new(center.x + (len * Math.cos(angle)),
                         center.y + (len * Math.sin(angle)))
  end
  def setup_clock()
    topleft = Point.new(0.0,0.0)
    bottomright = Point.new(100.0, 100.0)
    center = Point.new(bottomright.x/2, bottomright.y/2)
    @face=Gnome::CanvasEllipse.new(@canvas.root, {
                 :x1 => topleft.x,
                 :y1 => topleft.y,
                 :x2 => bottomright.x,
                 :y2 => bottomright.y,
                 :fill_color => "white",
                 :outline_color => "steelblue",
                 :width_pixels => 1})
    @radius = o = center.x * 0.50
    o  = @radius / 2
    @size =  center.x
    @knob=Gnome::CanvasEllipse.new(@canvas.root, {
                 :x1 => center.x-o,
                 :y1 => center.y-o,
                 :x2 => center.x+o,
                 :y2 => center.y+o,
                 :fill_color_rgba => 0x00669933})

    @time = Time.now
    @hourh = Gnome::CanvasPolygon.new(@canvas.root,
                                          {:points => hourhand(center),
                                            :fill_color_rgba => 0x00000080,
                                            :join_style => Gdk::GC::JOIN_ROUND,
                                            :outline_color => "black"})
    @minuteh = Gnome::CanvasPolygon.new(@canvas.root,
                                          {:points => minutehand(center),
                                            :fill_color_rgba => 0x00000080,
                                            :join_style => Gdk::GC::JOIN_ROUND,
                                            :outline_color => "black"})
    @secondh = Gnome::CanvasPolygon.new(@canvas.root,
                                          {:points => secondhand(center),
                                            :fill_color_rgba => 0xff000080,
                                            :join_style => Gdk::GC::JOIN_ROUND,
                                            :outline_color => "red"})

                 
  end
  def hourhand(center)
    val = (@time.hour % 12) + (@time.min / 60.0)
    posn = clockhandposition(center, @radius * 0.6, val, 12)
    size = @radius * 0.08
    start = basehandposition(center, size, val, 12)
    retn = basehandposition(center, - size, val, 12)
    backp = clockhandposition(center, - size, val, 12)
    [start.to_p, posn.to_p, retn.to_p, backp.to_p]
  end
  def minutehand(center)
    posn = clockhandposition(center, [@radius - 4, @radius * 0.8].max, @time.min, 60)
    size = @radius * 0.03
    start = basehandposition(center, size, @time.min, 60)
    retn = basehandposition(center, -size, @time.min, 60)
    backp = clockhandposition(center, - size, @time.min, 60)
    [start.to_p, posn.to_p, retn.to_p, backp.to_p]
  end
  def secondhand(center)
    posn = clockhandposition(center, @radius * 0.9, @time.sec, 60)
    size = @radius * 0.01
    start = basehandposition(center, size, @time.sec, 60)
    retn = basehandposition(center, -size, @time.sec, 60)
    backp = clockhandposition(center, - size, @time.sec, 60)
    [start.to_p, posn.to_p, retn.to_p, backp.to_p]
  end
  def draw_clock(resize=false)
    return false if destroyed?
    setup_clock() unless defined?(@face)
    center = Point.new(@width/2, @height/2)
    
    if resize
      @face.x1, @face.y1 = center.x - @radius, center.y - @radius
      @face.x2, @face.y2 = center.x + @radius, center.y + @radius
      o = @radius * 0.5
      @knob.x1, @knob.y1 = center.x-o, center.y-o
      @knob.x2, @knob.y2 = center.x+o, center.y+o
    end
    @time = Time.now
    @tips.set_tip(self, @time.asctime, nil)
    @hourh.points = hourhand(center)
    @minuteh.points = minutehand(center)
    @secondh.points = secondhand(center)
  end

  def initialize()
    super()
    @tips = Gtk::Tooltips.new
    set_border_width(@pad = 0)
    set_size_request((@width = 100)+(@pad*2), (@height = 100)+(@pad*2))
    @canvas = Gnome::Canvas.new(true)
    add @canvas
    draw_clock(true)
    signal_connect('size-allocate') { |w,e,*b| 
      @width, @height = [e.width,e.height].collect{|i|i - (@pad*2)}
      @size = [@width,@height].min
      @radius = @size / 2
      @canvas.set_size(@width,@height)
      @canvas.set_scroll_region(0,0,@width,@height)
      draw_clock(true)
      false
    }
    signal_connect_after('show') {|w,e| start() }
    signal_connect_after('hide') {|w,e| stop() }
    @canvas.show()
    show()
  end
  def start
	@tid= Gtk::timeout_add(1000) { draw_clock(); true }
  end
  def stop
	Gtk::timeout_remove(@tid) if @tid
	@tid = nil
  end
  def set_bg(bg)
  	modify_bg(Gtk::STATE_NORMAL, bg)
  	@canvas.modify_bg(Gtk::STATE_NORMAL, bg)
  end
end


OAFIID="OAFIID:GNOME_AnalogClockApplet_Factory"

init = proc do |applet, iid|

  def vertical(applet)
#    applet.orient == Applet::ORIENT_LEFT || applet.orient == applet.ORIENT_RIGHT
   true    
  end

  def size(applet)
    if vertical applet
      applet.set_size_request(-1,applet.size-3)
    else
      applet.set_size_request(applet.size-3,-1)
    end
  end

  applet.signal_connect('change-size') { size(applet) }
  applet.signal_connect('change-orient') { size(applet) }
  size(applet)

  clock = Clock.new
  clock.set_bg(Gdk::Color.new(2*2**16, 29*2**16, 41*2**16))
  applet.add(clock)
  applet.show_all
  
  true
end

oafiid = OAFIID
run_in_window = (ARGV.length == 1 && ARGV.first == "run-in-window")
oafiid += "_debug" if run_in_window

PanelApplet.main(oafiid, "Sample Clock Applet (Ruby-GNOME2)", "0", &init)

if run_in_window
  main_window = Gtk::Window.new
  main_window.set_title "Sample Clock Applet"
  main_window.signal_connect("destroy") { Gtk::main_quit }
  app = PanelApplet.new
  init.call(app, oafiid)
  app.reparent(main_window)
  main_window.show_all
  Gtk::main
end
