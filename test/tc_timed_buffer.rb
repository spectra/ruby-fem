require 'test/unit'
require '../lib/timed_buffer.rb'

class TC_TimedBuffer < Test::Unit::TestCase

	def test_push_defaults
		buffer = TimedBuffer.new
		buffer.push(:something)
		assert ! buffer.push(:something)
		sleep 2
		assert buffer.push(:otherthing)
		1.upto(200) { |n| assert buffer.push(n) }
		assert_equal 100, buffer.length
	end

	def test_push_other_interval
		buffer = TimedBuffer.new(10)
		assert buffer.push(:something)
		assert ! buffer.push(:something)
		sleep 2
		assert ! buffer.push(:something)
		sleep 11
		assert buffer.push(:something)
	end

	def test_push_infinite_store
		buffer = TimedBuffer.new(2, nil)
		1.upto(200) { |n| assert buffer.push(n) }
		assert_equal 200, buffer.length
		1.upto(200) { |n| assert buffer.push(n) }
		assert_equal 400, buffer.length
	end

	def test_pop
		buffer = TimedBuffer.new
		buffer.push(:something)
		assert_equal :something, buffer.pop
	end

	def test_observer
		buffer = TimedBuffer.new
		buffer.add_observer(self)
		assert @something.nil?
		buffer.push :something
		assert_equal @something, :something
		1.upto(200) do |n|
			buffer.push(n)
			assert_equal @something, n
		end
	end

	def update(something)
		@something = something
	end

end

