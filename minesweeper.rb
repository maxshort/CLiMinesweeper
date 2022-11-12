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

	def toggle_flag(y, x)
		if @flagged[y][x] then
			@numFlagged -= 1
		else
			@numFlagged += 1
		end
		@flagged[y][x] = !@flagged[y][x]
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
			# What's the reveal logic? Select a space if this space is 0 and keep selecting spaces until you hit a non-zero ?
			# MAkes sense because that's just a user convenience thing...if it's 0, you'll select all surrounding spaces anyway...
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

	def _make_horiz_guide
		#TODO: Not sure on double digit #s...Could in theory only put the first digit...
		# 4 spaces for column guide...
		ret = "  "
		@board.size.times do |i|
			ret += "#{i} "
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
			s += "#{rowIdx} "
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
			s += "#{rowIdx} "
			s += "\n"
		end
		s += _make_horiz_guide
		s
	end
end

#TODO: Get a flag count going...
#TODO: Also want to tell when we actually win -- when only mines remain...
def play_game()
	directions = <<~END
	Commands:
	  SS y,x -- for select space.
	  F y, x -- to flag a space.
	  Note that coordinates are y,x and zero-based.
END
	puts directions
	b = MineSweeperBoard.new(10, 10, 8)
	while true
		if b.only_mines_remain then
			puts "ONLY MINES REMAINING -- you won."
			break
		end
		puts b.print_board
		puts "SS y,x or F y,x"
		command = Kernel.readline
		#TODO: Not robust against double digits, etc.
		if command[0...2] == "SS" then
			y = command[3].to_i
			x = command[5].to_i
			no_mine_hit = b.select_space(y, x)
			unless no_mine_hit
				puts "HIT A MINE...GAME OVER"
				return
			end
		elsif command[0] == "F" then
			y = command[2].to_i
			x = command[4].to_i
			b.toggle_flag(y, x)
		else
			puts "Command not recognized. Ignored."
		end
	end
end

play_game