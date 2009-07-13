require 'inotify'

class FSEM

	def initialize(persist_file = nil)
		@persist_file = persist_file						# This will only persist ids
		if ! @persist_file.nil?
			@ids     = Hash.new										# This will hold file => id
			pload
		end

		@inotify   = Inotify.new
		@dirs      = Hash.new										# This will hold dir => [filename, filename]
		@wds       = Hash.new										# This will hold dir => wd
		@callbacks = Hash.new										# This will hold file => block

		@thread = Thread.new do
			@inotify.each_event do |event|
				mydir = wd2dir(event.wd)
				file = [ mydir, event.name ].join('/')
				if @callbacks.include?(file)
					id = file2id(file)
					@callbacks[file].call(id, file, event.mask)
				end
			end
		end
	end

	def watch(file)
		dir, filename = File.split(file)
		if @dirs.include?(dir)
			if @dirs[dir].include?(filename)
				raise StandardError, "File #{file} is already watched"
			else
				@dirs[dir] << filename
				@ids[file] = get_next_id unless @ids.include?(file)
				psave
			end
		else
			wd = @inotify.add_watch(dir, Inotify::ALL_EVENTS)
			@dirs[dir] = [filename]
			@wds[dir]  = wd
			@ids[file] = get_next_id unless @ids.include?(file)
			psave
		end
	end

	def unwatch(file)
		dir, filename = File.split(file)
		if @dirs.include?(dir) and @dirs[dir].include?(filename)
			@dirs[dir].delete(filename)
			if @dirs[dir].empty?
				@inotify.rm_watch(@wds[dir])
				@dirs.delete(dir)
				@wds.delete(dir)
			end
		else
			raise StandardError, "File #{file} is not watched"
		end
	end

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

	def rm_callback(file)
		if @callbacks.include?(file)
			@callbacks.delete(file)
		else
			raise StandardError, "File #{file} has no registered callbacks"
		end
	end

	private

	def file2id(file)
		@ids[file]
	end

	def wd2dir(n)
		arr = @wds.find { |dir, wd| wd == n }
		return nil if arr.empty?
		return arr[0]
	end

	def psave
		return nil if @persist_file.nil?

		File.open(@persist_file, 'w') do |f|
			f.flock File::LOCK_EX
			f.write Marshal.dump([@counter, @ids])
		end
	end

	def pload
		return nil if @persist_file.nil? or ! File.exists?(@persist_file)

		File.open(@persist_file, 'r') do |f|
			f.flock File::LOCK_EX
			@counter, @ids = Marshal.load(f.read)
		end
	end

	def get_next_id
		@counter ||= 0
		@counter += 1
	end

end


