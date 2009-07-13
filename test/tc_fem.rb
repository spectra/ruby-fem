require 'test/unit'
require 'fileutils'
require '../lib/fem.rb'

class TC_FEM < Test::Unit::TestCase

	def test_watch_file
		f = FEM.new
		filename = "/tmp/fem_test.txt"
		f.watch(filename)
		assert_equal 1, f.file2id(filename)
		assert f.is_watched?(filename)
	end

	def test_unwatch_file
		f = FEM.new
		filename = "/tmp/fem_test.txt"
		f.watch(filename)
		assert_equal 1, f.file2id(filename)
		f.unwatch(filename)
		assert_raise StandardError do
			f.file2id(filename)
		end
		assert ! f.is_watched?(filename)
	end

	def test_add_callback
		f = FEM.new
		filename = "/tmp/fem_test.txt"

		assert_raise StandardError do
			f.add_callback(filename) { puts "foobar" }
		end

		f.watch(filename)
		f.add_callback(filename) { |id, file, mask|
			assert_kind_of Fixnum, mask
			assert_equal 1, id
			assert_equal file, filename
		}

		assert_raise StandardError do
			f.add_callback(filename) { puts "foobar" }
		end
		FileUtils.touch("/tmp/fem_test.txt")
	end

	def test_rm_callback
		f = FEM.new
		filename = "/tmp/fem_test.txt"
		f.watch(filename)
		f.add_callback(filename) { |id, file, mask|
			assert_kind_of Fixnum, mask
			assert_equal 1, id
			assert_equal file, filename
		}
		FileUtils.touch("/tmp/fem_test.txt")

		f.rm_callback(filename)
		FileUtils.touch("/tmp/fem_test.txt")
	end
end

