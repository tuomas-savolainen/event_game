require "gosu"

class GameItem
	def initialize(state, current_events = [])
		@state = state
		@next_state = {}
		@current_events = current_events
		@next_events = []
		if state.has_key?(:key)
			@key = state[:key]
		else
			@key = nil
		end
	end
	attr_reader :state
	attr_accessor :key


	def turn(param)
		#next_state = state + current_events
		@next_state = @state

		param[:self_item] = self
		
		#run current events (send valid ones back to self)
		@current_events.each { |e| e.run(@state, param) ? receive_event(e) : nil}
	end

	#call this before draw
	def update
		@state = @next_state
		@next_state = {}
		@current_events = @next_events
		@next_events = []
	end

	def draw
		screen_vector = from_game_to_screen(@state[:p_vector])
		@state[:sprite].draw(screen_vector.x,screen_vector.y, 0)
	end

	def send_events(event)
	end

	def receive_event(event)
		@next_events.push(event)
	end
	#function to convert from game coordinates to screencoordinates
	def from_game_to_screen(vector)
		target_x = (vector.x - @state[:sprite].width/2)
		target_y = 512 - (vector.y - @state[:sprite].height/2)
		return Vector.new(target_x, target_y)
	end
	
end


class PlayerItem < GameItem


	def draw
		screen_vector = from_game_to_screen(@state[:p_vector])

		sprite_index = @state[:health] - 1

		state[:health_bar][sprite_index].draw(screen_vector.x, screen_vector.y - state[:health_bar][0].height, 1)

		#rotation correction
		screen_vector.x += @state[:sprite].width/2
		screen_vector.y += @state[:sprite].height/2
		@state[:sprite].draw_rot(screen_vector.x, screen_vector.y, 1, -(@state[:rotation_angle]*180.0 /Math::PI), 0.5, 0.5)
		#@state[:sprite].draw(screen_vector.x,screen_vector.y, 1)



	end

end



