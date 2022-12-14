class MineSweeperBoard
	def initialize(xLen, yLen, numMines)
		# Board will go y, then x
		@board = _fill_board(xLen, yLen, numMines)
		@revealed = _make_blank_board(xLen, yLen)
		@flagged = _make_blank_board(xLen, yLen)
		@totalMines = numMines
		@numFlagged = 0
	end
	
	def only_mines_remain
		@board.each_with_index do |row, rowIdx|
			row.each_with_index do |cell, colIdx|
				if !cell && !@revealed[rowIdx][colIdx] then
					return false
				end
			end
		end
		return true
	end
	
	def _make_blank_board(xLen, yLen)
		board = []
		yLen.times do
			row = [false] * xLen
			board << row
		end
		return board
	end
	
	# y, then x.
	def _fill_board(xLen, yLen, numMines)
		board = _make_blank_board(xLen, yLen)
		numMines.times do
			while true
				randY = (rand * yLen).to_i
				randX = (rand * xLen).to_i
				unless board[randY][randX]
					board[randY][randX] = true
					break
				end
			end
		end
		return board
	end
	
	# start & finish are inclusive
	def _clampXRange(start, finish)
		raise "Bad range: #{start}, #{finish}" if start >= finish
		if start < 0 then
			start = 0
		end
		if finish >= @board.length
			finish = @board.length - 1 
		end
		return (start..finish)
	end
	
	def _clampYRange(start, finish)
		raise "Bad range: #{start}, #{finish}" if start >= finish
		if start < 0 then
			start = 0
		end
		if finish >= @board[0].length
			finish = @board[0].length - 1 
		end
		return (start..finish)
	end
	
	def _surrounding_mine_count(y, x)
		mines = 0
		_clampYRange(y - 1, y + 1).each do |yCheck|
			_clampXRange(x - 1, x + 1).each do |xCheck|
				if @board[yCheck][xCheck] then
					mines += 1
				end
			end
		end
		mines
	end

	# Returns true if flag toggled on space, false otherwise.
	# False is when space is already revealed (no reason to flag).
	def toggle_flag(y, x)
		return false unless !@revealed[y][x]
		if @flagged[y][x] then
			@numFlagged -= 1
		else
			@numFlagged += 1
		end
		@flagged[y][x] = !@flagged[y][x]
		return true
	end
	
	# False means hit a mine...
	def select_space(y, x)
		if @board[y][x] then
			# Hit a mine--game over...
			return false
		elsif @revealed[y][x] then
			# We've already selected that space and don't want to infinitely recurse...
			return true
		else
			# Otherwise a hidden flag could remain...
			if @flagged[y][x]
				toggle_flag(y,x)
			end
			@revealed[y][x] = true
			surrounding_mine_count = _surrounding_mine_count(y, x)
			if surrounding_mine_count > 0 then
				return true
			else
				_clampYRange(y - 1, y + 1).each do |yCheck|
					_clampXRange(x - 1, x + 1).each do |xCheck|
						# Recursion is checked for @ top of select_space
						select_space(yCheck, xCheck)
					end
				end
			end
		end
		return true
	end

	def _make_flag_count()
		"Flags: #{@numFlagged}/#{@totalMines}"
	end

	def _last_digit(i)
		i % 10
	end

	def _make_horiz_guide
		#TODO: Not sure on double digit #s...Could in theory only put the first digit...
		# 4 spaces for column guide...
		ret = "  "
		@board.size.times do |i|
			ret += "#{_last_digit(i)} "
		end
		return ret
	end
	
	# X for uncovered, _ For blank/uncovered, F for flagged, numbers elsewhere...
	# (Returns a string)
	def print_board()
		s = "#{_make_flag_count}\n\n"
		s += _make_horiz_guide
		s += "\n"
		@board.each_with_index do |row, rowIdx|
			s += "#{_last_digit(rowIdx)} "
			row.each_with_index do |cell, colIdx|
				cell_display = nil
				if @revealed[rowIdx][colIdx] then
					# Blank spot or number
					mines = _surrounding_mine_count(rowIdx, colIdx)
					if mines == 0 then
						cell_display = "_"
					else
						cell_display = mines
					end
				elsif @flagged[rowIdx][colIdx] then
					cell_display = "F"
				else
					cell_display = "X"
				end
				s += "#{cell_display} "
			end
			s += "#{_last_digit(rowIdx)} "
			s += "\n"
		end
		s += _make_horiz_guide
		s
	end

	def print_revealed_board
		s = ""
		@board.each_with_index do |row, rowIdx|
			row.each_with_index do |cell_value, colIdx|
				cell_display = cell_value ? "*" : "_"
				s += "#{cell_display} "
			end
			s += "\n"
		end
		return s
	end

	def can_clear_all
		@numFlagged == @totalMines
	end

	# Returns true if all non-flagged cleared,
	# false if a mine was hit.
	def clear_all
		@board.each_with_index do |row, rowIdx|
			row.each_with_index do |cell, colIdx|
				if !@flagged[rowIdx][colIdx] && !@revealed[rowIdx][colIdx] then
					no_mine_hit = select_space(rowIdx, colIdx)
					return false unless no_mine_hit
				end
			end
		end
		return true
	end
end

PAIR_REGEX = /\s*(\d+)\s*,\s*(\d+)/
def parse_coords(s)
	m = PAIR_REGEX.match(s)
	return nil if m.nil?
	return [m[1].to_i, m[2].to_i]
end

LOSS_MESSAGE = "HIT A MINE...GAME OVER"
WIN_MESSAGE = "ONLY MINES REMAINING -- you won."
COORDS_FORMAT_MESSAGE = "Coordinate format not recognized."

def play_game()
	directions = <<~END
	Commands:
	  SS y,x -- for select space.
	  F y, x -- to flag a space.
	  Note that coordinates are y,x and zero-based.
	  CLEAR -- clear all non-flagged spaces. Only allowed when total flags = total mines.
END
	puts directions
	b = MineSweeperBoard.new(10, 10, 8)
	while true
		if b.only_mines_remain then
			puts WIN_MESSAGE
			puts b.print_revealed_board
			break
		end
		puts b.print_board
		puts "SS y,x or F y,x"
		command = Kernel.readline
		if command[0...2] == "SS" then
			coords = parse_coords(command[2..])
			if coords.nil?
				puts COORDS_FORMAT_MESSAGE
				next
			end
			y = coords[0]
			x = coords[1]
			no_mine_hit = b.select_space(y, x)
			unless no_mine_hit
				puts LOSS_MESSAGE
				puts b.print_revealed_board
				break
			end
		elsif command[0] == "F" then
			coords = parse_coords(command[1..])
			if coords.nil?
				puts COORDS_FORMAT_MESSAGE
				next
			end
			y = coords[0]
			x = coords[1]
			did_toggle = b.toggle_flag(y, x)
			puts "Space already uncovered. No flag applied." unless did_toggle
		elsif command == "CLEAR\n" then
			if !b.can_clear_all then
				puts "CLEAR can only be applied when the number of flags matches the number of mines."
			else
				if b.clear_all
					puts WIN_MESSAGE
					puts b.print_revealed_board
				else
					puts LOSS_MESSAGE
					puts b.print_revealed_board
				end
				break
			end
		else
			puts "Command not recognized. Ignored."
		end
	end
end

play_game