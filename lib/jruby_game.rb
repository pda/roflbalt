require 'java'

import javax.swing.JFrame
import javax.swing.JLabel
import java.awt.event.KeyListener

CONTROL_WIDTH = 400
CONTROL_HEIGHT = 400

class JRubyGame < Game
  def initialize
    setup_frame
    super
  end
  
  def setup_frame
    @frame = JFrame.new("ROFL Control")
    @frame.set_size CONTROL_WIDTH, CONTROL_HEIGHT
    @frame.default_close_operation = JFrame::EXIT_ON_CLOSE
    jlabel = JLabel.new("'q' to Quit, 'n' for New, 'Any Key' for jump!")
    @frame.add jlabel
    @frame.pack
    # Listen for keystrokes, play notes
    @frame.add_key_listener KeyListener.impl { |name, event|
      case name
      when :keyPressed
        @world.player.jump
        if event.key_char == 113  # q
          @frame.visible = false
          @frame.dispose
          @run = false
        elsif event.key_char == 110  # n
          reset
        end
      when :keyReleased
      end
    }
    @frame.visible = true
  end
  def on_exit
    @frame.visible = false
    @frame.dispose
    super
  end
end

