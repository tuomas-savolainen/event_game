class SlowEnemy
	def initialize(player, delay)
		@player = player
		@delay = delay
		@current_frame = 0
		@current_choise = nil
	end
	
	attr_reader :player

	def think
		if @current_frame == @delay -1
			#time to choose
			@player.button_up(@current_choise)

			#choose between moving, aiming and attack
			choise = rand(0..2)
			if choise == 0
				#choose between turning and moving forward
				@current_choise = rand(0..2)
			elsif choise == 1
				@current_choise = 3
			else
				@current_choise = 4
			end
				
			@player.button_down(@current_choise)

			@current_frame = 0
		else
			@current_frame += 1
		end

	end
	
end