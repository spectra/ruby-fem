require 'test/unit'
require 'fileutils'
require '../lib/fsem.rb'

class TC_FSEM < Test::Unit::TestCase

	def test_watch_file
		f = FSEM.new
		filename = "/tmp/fsem_test.txt"
		f.watch(filename)
		assert_equal 1, f.file2id(filename)
	end

	def test_unwatch_file
		f = FSEM.new
		filename = "/tmp/fsem_test.txt"
		f.watch(filename)
		assert_equal 1, f.file2id(filename)
		f.unwatch(filename)
		assert_raise StandardError do
			f.file2id(filename)
		end
	end

	def test_add_callback
		f = FSEM.new
		filename = "/tmp/fsem_test.txt"

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
		FileUtils.touch("/tmp/fsem_test.txt")
	end

	def test_rm_callback
		f = FSEM.new
		filename = "/tmp/fsem_test.txt"
		f.watch(filename)
		f.add_callback(filename) { |id, file, mask|
			assert_kind_of Fixnum, mask
			assert_equal 1, id
			assert_equal file, filename
		}
		FileUtils.touch("/tmp/fsem_test.txt")

		f.rm_callback(filename)
		FileUtils.touch("/tmp/fsem_test.txt")
	end
end

