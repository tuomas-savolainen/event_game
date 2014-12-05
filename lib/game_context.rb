require_relative "asset_manager"
require_relative "vector"
require_relative "game_item"

class GameContext
	def initialize(window, screen_y)
		@window = window
		@screen_y = screen_y

		@active_items = {}

		#array consisting of items to be added to the active_items for the next frame
		@next_items = []

		#array consisting of keys that correspond items to be removed on the next turn
		@remove_items = []

		@key_count = 0

		@asset_manager = AssetManager.new(window)

		terrain_items = create_map(@asset_manager)
		terrain_items.each { |e|  create_item(e)}

		@counter = 0

	end

	#run turns for each item
	def turn(players)
		#check there exists item with the same key as the player has
		#create new events from the lambda function
		#send new events to the recipient


		for player in players
			if @active_items.has_key?(player[0])
				for f in player[1].current_events.values
					events = f.call()
					for event in events
						@active_items[player[0]].receive_event(event)
					end
				end
			end
		end

		param = 
		{
			:get_items => lambda {|keys| get_items(keys)}, 
			:destroy_item => lambda {|key| destroy_item(key)}, 
			:create_item => lambda {|item| create_item(item)},
			:manager => @asset_manager
		}
		@active_items.each_value{|e| e.turn(param)}

	end

	def get_items(keys)
		#returns an array of items with the given keys
		#if the keys is empty returns all items
		if keys.empty?
			return @active_items.values
		else
			result = []
			keys.each { |e| @active_items.has_key?(e) ? result.push(@active_items[e]) : nil}
			return result
		end
	end


	#update items (according to events that happened during the turn)
	def update
		@active_items.each_value { |e| e.update}
	end

	#draw the items to the screen
	def draw

		@active_items.each_value { |e| e.draw }
	end

	#add item, if item's current key is nil it will be replaced by new (unique) key
	def create_item(item)

		if item.key.nil?
			item.key = create_unique_item_key
		end
		@next_items.push(item)
	end

	#destroy item, keys that don't exist in the active_items will have no effect
	def destroy_item(key)
		if not key.nil?
			@remove_items.push(key)
		end
	end

	#add new items to the game
	def create_items
		@next_items.each { |e|  @active_items[e.key] = e}
		@next_items = []
	end

	#remove items from the game
	def remove_items
		@remove_items.each { |e|  @active_items.delete(e)}
		@remove_items = []
	end


	def create_unique_item_key
		key = "game_item_#{@key_count}"
		@key_count += 1
		return key
	end

	def end_game
		#check if player lost --> Computer wins
		if get_items([:player0]).empty?
			return "computer"
		#check if player won
		elsif get_items([:enemy0, :enemy1]).empty?
			return "player"
		end
	end


end


def create_map(asset_manager, item_hash = nil, tiles = nil, tile_size_x = 16, tile_size_y = 16)
	
	half_x = tile_size_x / 2
	half_y = tile_size_y / 2

	terrain = []

	sand_sprite = asset_manager.load_sprites("space_tiles.png", 16, 16)[0]
	wall_sprite = asset_manager.load_sprites("space_tiles.png", 16, 16)[3]
	space_man_sprite = asset_manager.load_sprites("space_man_up.png", 16, 16)[0]
	green_monster_sprite = asset_manager.load_sprites("green_monster_up.png", 16, 16)[0]
	health_bar_sprites = asset_manager.load_sprites("health_bar.png", 16, 6)

	sand_state = lambda {|p_vector| {sprite: sand_sprite, p_vector: p_vector, collides: false}}
	wall_state = lambda {|p_vector| {sprite: wall_sprite, p_vector: p_vector, collides: true}}
	player_state = lambda {|p_vector|
	{
		sprite: space_man_sprite, 
		p_vector: p_vector, 
		delta_vector: Vector.new(0,0), 
		collides: true, 
		key: :player0, 
		rotation_angle: 0.0, 
		primary_cooldown: 0,
		secondary_cooldown: 0, 
		speed: 1, 
		heat: 10, 
		health: 14, 
		health_bar: health_bar_sprites
	}}

	enemy0_state = lambda {|p_vector|
	{
		sprite: green_monster_sprite, 
		p_vector: p_vector, 
		delta_vector: Vector.new(0,0), 
		collides: true, 
		key: :enemy0, 
		rotation_angle: 0.0, 
		primary_cooldown: 0, 
		speed: 1, 
		health: 14,
		health_bar: health_bar_sprites
	}}

	enemy1_state = lambda {|p_vector|
	{
		sprite: green_monster_sprite, 
		p_vector: p_vector, 
		delta_vector: Vector.new(0,0), 
		collides: true, 
		key: :enemy1, 
		rotation_angle: 0.0, 
		primary_cooldown: 0, 
		speed: 1, 
		health: 14,
		health_bar: health_bar_sprites
	}}


	item_hash = 
	{
		0 => [lambda {|p_vector| GameItem.new(sand_state.call(p_vector))}],
		1 => [lambda {|p_vector| GameItem.new(wall_state.call(p_vector))}],
		2 => [lambda {|p_vector| GameItem.new(sand_state.call(p_vector))}, lambda {|p_vector| PlayerItem.new(player_state.call(p_vector))}],
		3 => [lambda {|p_vector| GameItem.new(sand_state.call(p_vector))}, lambda {|p_vector| PlayerItem.new(enemy0_state.call(p_vector))}],
		4 => [lambda {|p_vector| GameItem.new(sand_state.call(p_vector))}, lambda {|p_vector| PlayerItem.new(enemy1_state.call(p_vector))}]
	}

	tiles = 
	[
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,1,0,0,0,0,0,0,0,3,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,1,0,0,2,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1],
		[1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
		[1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	]

	for y in 0...tiles.size
		for x in 0...tiles[y].size
			numeric = tiles[y][x]
			g_x = x*tile_size_x + half_x
			g_y = (tiles.size-y)*tile_size_y + half_y

			#create item's of according to item hash and add to the terrain array

			item_hash[numeric].each{ |e| terrain.push( e.call(Vector.new(g_x, g_y)) ) }
		end
	end

	return terrain
end


