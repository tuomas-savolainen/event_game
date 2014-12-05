#!/usr/bin/env ruby

require_relative "lib/game_window"



if __FILE__ == $0
	
	puts("Starting game...")
	window = GameWindow.new
	window.show

end