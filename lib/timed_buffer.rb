# timed_buffer.rb
#
# Simple TimedBuffer that offers a "smooth surface" preventing event flooding
# Copyright (c) 2009 by Pablo Lorenzoni <pablo@propus.com.br>
# Released under the following terms:
#
# ----------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43):
# <pablo@propus.com.br> wrote this file and it's provided AS-IS, no
# warranties. As long as you retain this notice you can do whatever you
# want with this stuff. If we meet some day, and you think this stuff is
# worth it, you can buy me a beer in return."
# ----------------------------------------------------------------------
require 'observer'
require 'thread'

# Offers a thread-safe 'smooth surface' to prevent event flooding.
# This class includes Observable module
class TimedBuffer
	include Observable

	# Create a new TimedBuffer
	#
	# interval:: seconds of 'smoothness' (default = 2)
	# size:: maximum size of the buffer (nil = infinite; default = 100)
	def initialize(interval = 2, size = 100)
		@interval  = interval
		@size      = size

		@store     = Array.new					# where we'll store stuff
		@last_time = Time.now						# when have we seem the last item
		@mutex     = Mutex.new					# protects @store and @last_time #push and #pop
	end

	# Push something to our buffer
	# Returns true if successfully pushed or false otherwise
	def push(something)
		@mutex.synchronize do
			now = Time.now
			if (something != @store.last) or (now > (@last_time + @interval))
				# Either something was not seem by last or it was but interval has passed.
				@store.push something
				(@store.shift if @store.length > @size) unless @size.nil?
				@last_time = now
				changed
				notify_observers(something)
				return true
			else
				@last_time = now
				return false
			end
		end
	end

	# Pop something from our buffer
	def pop
		@mutex.synchronize do
			@store.pop
		end
	end

	# Length of our store
	def length
		@store.length
	end

end
