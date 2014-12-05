
require "gosu"
require_relative "game_context"
require_relative "game_player"
require_relative "slow_enemy"
require_relative "game_event"

class GameWindow < Gosu::Window
	#create new 640 x 512 pixel, non fullscreen window with 33.333 ms delay per frame
	def initialize(screen_x = 640, screen_y = 512, full_screen = false, delay = 33.333333)
		#super 640, 512, false, 33.33333333
		super(screen_x, screen_y, full_screen, delay)
		@screen_x = screen_x
		@screen_y = screen_y
		self.caption = "Colliding with circles"

		@computer_won = Gosu::Image.from_text(self, "Computer Won!", "fonts/PressStart2P.ttf", 16)
		@player_won = Gosu::Image.from_text(self, "Player Won!", "fonts/PressStart2P.ttf", 16)
		@press_enter = Gosu::Image.from_text(self, "[Press ENTER to continue]", "fonts/PressStart2P.ttf", 12)
		@end_sprite = @computer_won

		@game_ended = false

		@context = GameContext.new(self, screen_y)

		player0 = GamePlayer.new()

		enemy0_keys =
		{
			0 => lambda {[GameEvent.new(:move_method_W, 3), GameEvent.new(:collide_method, 3)]},
			1 => lambda {[GameEvent.new(:move_method_A, 3)]},
			2 => lambda {[GameEvent.new(:move_method_D, 3)]},
			3 => lambda {[GameEvent.new(:auto_aiming_method, 3)]},
			4 => lambda {[GameEvent.new(:heat_seeking_method, 1)]}
		}

		enemy0 = GamePlayer.new(enemy0_keys)
		enemy1 = GamePlayer.new(enemy0_keys)


		ai0 = SlowEnemy.new(enemy0, 4)
		ai1 = SlowEnemy.new(enemy1, 4)

		@ais = [ai0, ai1]

		@players = {player0: player0, enemy0: enemy0, enemy1: enemy1}

	end


	#add game logic here
	def update

		@ais.each { |e| e.think }
		@context.turn(@players)
		@context.update
		@context.create_items
		@context.remove_items
		result = @context.end_game

		if not result.nil?
			@game_ended = true
			if result == "player"
				@end_sprite = @player_won
			else
				@end_sprite = @computer_won
			end
		end

	end

	#draw to window here
	def draw
		if not @game_ended
			@context.draw
		else
			@end_sprite.draw(@screen_x/2-@end_sprite.width/2,@screen_y/2 - @end_sprite.height/2,0)
			@press_enter.draw(@screen_x/2-@press_enter.width/2, @screen_y/2 - @press_enter.height/2 + @end_sprite.height*2, 0)
		end
	end

	#catch the ESC key
	def button_down(id)
		if id == Gosu::KbEscape
			puts("got escape key, exiting...")
			close
		elsif id == Gosu::KbReturn
			close
		else
			@players[:player0].button_down(id)
		end
	end

	def button_up(id)
		@players[:player0].button_up(id)

	end
	
end