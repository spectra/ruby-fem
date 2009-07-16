# fem.rb
#
# Monitor FILES for modification using Inotify
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

$: << File.dirname(__FILE__)
require 'inotify'
require 'timed_buffer'

class FEM

	# Initialize a new FEM object.
	#
	# persist_file:: if passed, we'll persist FEM ids in it.
	def initialize(persist_file = nil)
		@persist_file = persist_file						# This will only persist ids
		@ids          = Hash.new								# This will hold file => id
		if ! @persist_file.nil?									# Got a persist_file? Load it!
			pload
		end

		@inotify   = Inotify.new
		@dirs      = Hash.new										# This will hold dir => [filename, filename]
		@wds       = Hash.new										# This will hold dir => wd
		@callbacks = Hash.new										# This will hold file => block
		@evbuffer  = Hash.new										# This will hold file => timed_buffer

		@thread = Thread.new do
			@inotify.each_event do |event|
				mydir = wd2dir(event.wd)
				file = [ mydir, event.name ].join('/')
				if @callbacks.include?(file) and is_watched?(file)
					id = file2id(file)
					@callbacks[file].call(id, file, event.mask) if @evbuffer[file].push(event.mask)
				end
			end
		end
	end

	# Start watching a file. Returns the FEM id of it.
	def watch(file)
		dir, filename = File.split(file)
		if @dirs.include?(dir)
			if @dirs[dir].include?(filename)
				raise StandardError, "File #{file} is already watched"
			else
				@dirs[dir] << filename
				@ids[file] = get_next_id unless @ids.include?(file)
				@evbuffer[file] = TimedBuffer.new
				psave
			end
		else
			wd = @inotify.add_watch(dir, Inotify::ALL_EVENTS)
			@dirs[dir] = [filename]
			@wds[dir]  = wd
			@ids[file] = get_next_id unless @ids.include?(file)
			@evbuffer[file] = TimedBuffer.new
			psave
		end
		return @ids[file]
	end

	# Stop watching a file.
	def unwatch(file)
		if is_watched?(file)
			dir, filename = File.split(file)
			@dirs[dir].delete(filename)
			@evbuffer.delete(file)
			if @dirs[dir].empty?
				@inotify.rm_watch(@wds[dir])
				@dirs.delete(dir)
				@wds.delete(dir)
			end
		else
			raise StandardError, "File #{file} is not watched"
		end
		return file
	end

	# Add a new callback for when some event happens with that file. Only one callback is allowed per watched file.
	#
	# file:: the file being watched.
	# block:: the callback. You can assume we'll pass 3 parameters: FEM id, file and event mask for this callback.
	def add_callback(file, &block)
		dir, filename = File.split(file)
		if ! @dirs.include?(dir) or ! @dirs[dir].include?(filename)
			raise StandardError, "File #{file} is not watched"
		else
			if @callbacks.include?(file)
				raise StandardError, "File #{file} already have associated callbacks"
			else
				@callbacks[file] = block
			end
		end
	end

	# Remove a callback for a file.
	#
	# file:: the file being watched.
	def rm_callback(file)
		if @callbacks.include?(file)
			@callbacks.delete(file)
		else
			raise StandardError, "File #{file} has no registered callbacks"
		end
	end

	# Retrieve the FEM id of a file.
	#
	# file:: file being watched.
	def file2id(file)
		dir, filename = File.split(file)
		raise StandardError, "File #{file} is not watched" if ! @dirs.include?(dir) or ! @dirs[dir].include?(filename)
		@ids[file]
	end

	# Is this file watched?
	#
	# file:: file in question
	def is_watched?(file)
		dir, filename = File.split(file)
	  return true if @dirs.include?(dir) and @dirs[dir].include?(filename)
		return false
	end

	private

	# Retrieve the directory given an Inotify Watch Descriptor.
	#
	# n:: the watch descriptor
	def wd2dir(n)
		arr = @wds.find { |dir, wd| wd == n }
		return nil if arr.empty?
		return arr[0]
	end

	# Persist FEM ids.
	def psave
		return nil if @persist_file.nil?

		File.open(@persist_file, 'w') do |f|
			f.flock File::LOCK_EX
			f.write Marshal.dump([@counter, @ids])
		end
	end

	# Load FEM ids.
	def pload
		return nil if @persist_file.nil? or ! File.exists?(@persist_file)

		File.open(@persist_file, 'r') do |f|
			f.flock File::LOCK_EX
			@counter, @ids = Marshal.load(f.read)
		end
	end

	# Get the next FEM id. This is just an always-increment numer.
	def get_next_id
		@counter ||= 0
		@counter += 1
	end

end


