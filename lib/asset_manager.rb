class AssetManager
	#asset manager should assure that assets are loaded only once from the filesystem, preferrably at startup

	def initialize(window)
		@window = window
		@loaded_images = {}
	end

	#load sprites to loaded
	def load_sprites(path, x_size, y_size)
		if not @loaded_images.has_key?(path)
			sprite_sheet = Gosu::Image.load_tiles(@window, "textures/"+path, x_size, y_size, true)
			@loaded_images[path] = sprite_sheet
			return sprite_sheet
		else
			return @loaded_images[path]
		end

	end
end