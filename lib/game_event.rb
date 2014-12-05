class GameEvent
	def initialize(method, duration = 1)
		@method = method
		@duration = duration
	end
	attr_accessor :valid
	attr_accessor :duration
	attr_accessor :method


	def run(state, param)
		if @duration > 0
			@duration -= 1
			send @method, state, @duration, param
			return true
		else
			return false
		end
	end

end