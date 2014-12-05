require_relative "game_event"
require_relative "game_item"
require_relative "vector"

def move_method_W(state, duration, param)
	#calculate in local coordinates
	delta_x = state[:speed] * Math.cos(state[:rotation_angle])
	delta_y = state[:speed] * Math.sin(state[:rotation_angle])
	
	state[:delta_vector].x = delta_x
	state[:delta_vector].y = delta_y
end

def move_method_A(state, duration, param)

	state[:rotation_angle] += (2.0/180.0)* Math::PI
	if state[:rotation_angle] > 2*Math::PI
		state[:rotation_angle] -= 2*Math::PI
	end


end

def move_method_S(state, duration, param)
	#calculate in local coordinates

	delta_x = state[:speed] * 0.5 * Math.cos(state[:rotation_angle])
	delta_y = state[:speed] * 0.5 * Math.sin(state[:rotation_angle])


	state[:delta_vector].x = -delta_x
	state[:delta_vector].y = -delta_y
end

def move_method_D(state, duration, param)
	state[:rotation_angle] -= (2.0/180.0)* Math::PI
	if state[:rotation_angle] < -2*Math::PI
		state[:rotation_angle] += 2*Math::PI
	end



end

def destroy_method(state, duration, param)
	#timed self destruct


	if duration == 0
		param[:destroy_item].call(param[:self_item].key)
	end

end


def collide_method(state, duration, param)

	#others = param[:items] - [param[:self_item]]

	others = param[:get_items].call([]) - [param[:self_item]] 

	collision = false
	radius = state[:sprite].width / 2

	position = state[:p_vector] + state[:delta_vector]


	for item in others
		if item.state[:collides]

			distance = (position - item.state[:p_vector]).length
			if distance < (radius + item.state[:sprite].width/2)

				collision = true
				return
			end
		end
	end

	if not collision
		state[:p_vector] = position
	end
end

def collide_substep_method(state, duration, param)

	#others = param[:items] - [param[:self_item]]

	others = param[:get_items].call([]) - [param[:self_item]] 

	collision = false
	radius = state[:sprite].width / 2

	positions = []
	steps = 8
	for i in 0..steps
		positions.push(state[:p_vector] + state[:delta_vector] * (i.to_f/steps))
	end

	for position in positions
		for item in others
			if item.state[:collides]

				distance = (position - item.state[:p_vector]).length
				if distance < (radius + item.state[:sprite].width/2)

					#damage on collision
					damage_item(item, param)
					#immediate (next frame) self destruct on collision
					param[:destroy_item].call(param[:self_item].key)
					collision = true
					return
				end
			end
		end
		if not collision
			state[:p_vector] = position
		end
	end

end


def damage_item(item, param)
	if item.state.has_key?(:health)
		if item.state[:health] == 1
			#destroy item if it will have 0 health
			param[:destroy_item].call(item.key)
		else
			item.state[:health] -= 1
		end
	end
end

def debug_method(state, duration, param)

	all_items = param[:get_items].call([])


	if state.has_key?(:debug_cooldown)
		if state[:debug_cooldown] == 0
			event = lambda {[GameEvent.new(:change_sprite_method, 1)]}
			all_items.each { |e|  e.receive_event(event.call()[0])}
			state[:debug_cooldown] = 10
		else
			state[:debug_cooldown] -= 1
		end
	else
		event = lambda {[GameEvent.new(:change_sprite_method, 1)]}
		all_items.each { |e|  e.receive_event(event.call()[0])}
		state[:debug_cooldown] = 10
	end

end


def change_sprite_method(state, duration, param)

	red_ring_sprite = param[:manager].load_sprites("red_ring.png", 16, 16)[0]
	green_ring_sprite = param[:manager].load_sprites("green_ring.png", 16, 16)[0]

	#check that not in debug mode allready
	if not state.has_key?(:old_sprite) or state[:old_sprite].nil?
		state[:old_sprite] = state[:sprite]
		
		if state[:collides]
			state[:sprite] = red_ring_sprite
		else
			state[:sprite] = green_ring_sprite
		end
	else
		#return back to normal
		state[:sprite] = state[:old_sprite]
		state[:old_sprite] = nil
	end
end

def earthquake_method(state, duration, param)

	#get all items
	all_items = param[:get_items].call([])

	others = all_items - [param[:self_item]]

	#select item randomly
	item = others[rand(0...others.size)]

	#delete item
	param[:destroy_item].call(item.key)

end


def shortest_directions(state, others)

	#count distances to other objects

	vectors = []
	others.each { |e| vectors.push(e.state[:p_vector] - state[:p_vector]) }


	sorted_distances = vectors.sort { |a, b|  a.length <=> b.length}

	return sorted_distances
end



def normal_plasma_method(state, duration, param)
	if state[:primary_cooldown] == 0

		#create ball of plasma next to the player
		speed = 8
		plasma_state = 
		{
			sprite: param[:manager].load_sprites("white_plasma.png", 16, 16)[0],
			p_vector: state[:p_vector] + Vector.new((state[:sprite].width+speed)*Math.cos(state[:rotation_angle]),  (state[:sprite].height+speed)*Math.sin(state[:rotation_angle])),
			delta_vector: Vector.new(0,0),
			collides: false, 
			rotation_angle: state[:rotation_angle],
			speed: speed,
		}


		plasma_events = [GameEvent.new(:move_method_W, 30), GameEvent.new(:collide_substep_method, 30), GameEvent.new(:destroy_method, 30)]

		plasma = GameItem.new(plasma_state, plasma_events)

		param[:create_item].call(plasma)

		state[:primary_cooldown] = 5
	else
		state[:primary_cooldown] -= 1
	end

end

def shield_plasma_method(state, duration, param)
	if state[:secondary_cooldown] == 0

		#create ball of plasma next to the player
		speed = 8
		plasma_state = lambda { |angle|
		{
			sprite: param[:manager].load_sprites("white_plasma.png", 16, 16)[0],
			p_vector: state[:p_vector] + Vector.new((state[:sprite].width+speed)*Math.cos(state[:rotation_angle]+angle),  (state[:sprite].height+speed)*Math.sin(state[:rotation_angle]+angle)),
			delta_vector: Vector.new(0,0),
			collides: false, 
			rotation_angle: state[:rotation_angle]+angle,
			speed: speed
		}}


		plasma_events = lambda {[GameEvent.new(:move_method_W, 30), GameEvent.new(:collide_substep_method, 30), GameEvent.new(:destroy_method, 30)] }

		count = 8

		for i in 0...count
			param[:create_item].call(GameItem.new(plasma_state.call(i*2*Math::PI/count.to_f), plasma_events.call()))
		end

		state[:secondary_cooldown] = 20
	else
		state[:secondary_cooldown] -= 1
	end

end


def heat_seeking_method(state, duration, param)

	if state[:primary_cooldown] == 0

		#create ball of plasma next to the player
		speed = 8
		plasma_state = 
		{
			sprite: param[:manager].load_sprites("white_plasma.png", 16, 16)[0],
			p_vector: state[:p_vector] + Vector.new((state[:sprite].width+speed)*Math.cos(state[:rotation_angle]),  (state[:sprite].height+speed)*Math.sin(state[:rotation_angle])),
			delta_vector: Vector.new(0,0),
			collides: false, 
			rotation_angle: state[:rotation_angle],
			speed: speed
		}


		plasma_events = [GameEvent.new(:move_method_W, 30), GameEvent.new(:auto_aiming_method, 30), GameEvent.new(:collide_substep_method, 30), GameEvent.new(:destroy_method, 30)]
		plasma = GameItem.new(plasma_state, plasma_events)

		param[:create_item].call(plasma)

		state[:primary_cooldown] = 5
	else
		state[:primary_cooldown] -= 1
	end

end


def auto_aiming_method(state, duration, param)
	others = param[:get_items].call([]) - [param[:self_item]]

	warm = []
	others.each { |e| e.state.has_key?(:heat) ? warm.push(e) : nil}

	if not warm.empty?

		directions = shortest_directions(state, warm)

		closest = directions[0]

		unit_vector = closest.normalize

		#state[:delta_vector] = unit_vector * state[:speed]

		target_angle = Math.atan2(unit_vector.y, unit_vector.x)
		if state[:rotation_angle] < target_angle
			state[:rotation_angle] += (4.0/180.0)* Math::PI
		elsif state[:rotation_angle] > target_angle
			state[:rotation_angle] -= (4.0/180.0)* Math::PI
		end
	end
end




class GamePlayer
	def initialize(device_map = nil)
		#device map consists of key => lambda {GameEvent} pairs, thus each keypress gives new event object
		if not device_map.nil?
			@device_map = device_map
		else
			@device_map = 
			{
				Gosu::KbW => lambda {[GameEvent.new(:move_method_W, 3), GameEvent.new(:collide_method, 3)]},
				Gosu::KbA => lambda {[GameEvent.new(:move_method_A, 3)]},
				Gosu::KbS => lambda {[GameEvent.new(:move_method_S, 3), GameEvent.new(:collide_method, 3)]},
				Gosu::KbD => lambda {[GameEvent.new(:move_method_D, 3)]},
				Gosu::KbO => lambda {[GameEvent.new(:debug_method, 1)]},
				Gosu::Kb1 => lambda {[GameEvent.new(:normal_plasma_method, 1)]},
				Gosu::Kb2 => lambda {[GameEvent.new(:shield_plasma_method, 1)]}
				
			}
		end
		@current_events = {}
	end
	attr_reader :current_events

	def button_down(id)
		if not id.nil? and @device_map.has_key?(id)
			@current_events[id] = @device_map[id]
		end
	end

	def button_up(id)
		if not id.nil? and @current_events.has_key?(id)
			@current_events.delete(id)
		end
	end
	
end