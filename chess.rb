require 'pry'

ALG_NOT = {
	"a" => 0,
	"b" => 1, 
	"c" => 2,
	"d" => 3,
	"e" => 4,
	"f" => 5,
	"g" => 6,
	"h" => 7
}

#coords: [y,x]
class Game
	attr_reader :board, :player_1, :player_2, :current_player
	def initialize(player_1_name, player_2_name)
		@user_color = rand(1) % 2 == 0 ? "white" : "black"
		@player_1 = Player.new(player_1_name)
		@player_2 = Player.new(player_2_name)
		@board = Board.new(@player_1, @player_2)
		@current_player = @player_1
		# board.render
	end

	def play!
		puts "#{current_player.name.downcase.capitalize}, please enter your move:"
		move_coords = gets.chomp.split('')
		start = move_coords[0..1]
		move = move_coords[2..3]
		@current_player.move!(board, ALG_NOT[start[0]], 8 - start[1].to_i, ALG_NOT[move[0]], 8 - move[1].to_i)
		board.render
		@current_player = current_player == player_1 ? player_2 : player_1
		play!
	end
end

class Player
	attr_reader :name
	def initialize(name)
		@name = name
	end

	def move!(board, start_x, start_y, move_x, move_y) 
		player_piece = board.pieces.find { |piece| piece.coords == [start_y, start_x] }
		captured = board.pieces.find { |piece| piece.coords == [move_y, move_x] }
		if player_piece != nil 
			player_piece.coords = [move_y, move_x]
			if captured != nil
				captured.die!
				board.captured_pieces << captured
			end
			return true
		else
			return false
		end
	end

	def offer_draw!
	end

	def resign!
	end
end

class Board
	attr_reader :board_arr, :captured_pieces
	attr_accessor :pieces
	def initialize(player_1, player_2)
		@board_arr = []
		@pieces = [
			Piece.new(player_2, :rook, 0, 0, "r"),
			Piece.new(player_2, :knight, 0, 1, "n"),
			Piece.new(player_2, :bishop, 0, 2, "b"),
			Piece.new(player_2, :queen, 0, 3, "q"),
			Piece.new(player_2, :king, 0, 4, "k"),
			Piece.new(player_2, :bishop, 0, 5, "b"),
			Piece.new(player_2, :knight, 0, 6, "n"),
			Piece.new(player_2, :rook, 0, 7, "r"),

			Piece.new(player_1, :rook, 7, 0, "R"),
			Piece.new(player_1, :knight, 7, 1, "N"),
			Piece.new(player_1, :bishop, 7, 2, "B"),
			Piece.new(player_1, :queen, 7, 3, "Q"),
			Piece.new(player_1, :king, 7, 4, "K"),
			Piece.new(player_1, :bishop, 7, 5, "B"),
			Piece.new(player_1, :knight, 7, 6, "N"),
			Piece.new(player_1, :rook, 7, 7, "R")
		]
		(0..7).each { |n| @pieces << Piece.new(player_2, :pawn, 1, n, "p") }
		(0..7).each { |n| @pieces << Piece.new(player_1, :pawn, 6, n, "P") }
		@captured_pieces = []
	end

	# def render
	# 	board_arr = Array.new(64, "_")
	# 	pieces.each { |piece| board_arr[to_index(piece.coords)] = piece.display_char if piece.alive }
	# 	puts "   __ __ __ __ __ __ __ __"
	# 	y_count = 8
	# 	board_arr.each_slice(8).each do |row|
	# 		formatted_row = row.map(&:to_s).map{ |content| content.length == 1 ? content + "_" : content[0..1] }
	# 		puts  y_count.to_s + " |" + formatted_row.join("|") + "|"
	# 		y_count -= 1
	# 	end
	# 	puts "   a  b  c  d  e  f  g  h "
	# 	puts 
	# 	puts "Captured: " + captured_pieces.map(&:display_char).join(", ") if !captured_pieces.empty?
	# end

	def render
		board_arr = Array.new(64, " ")
		pieces.each { |piece| board_arr[to_index(piece.coords)] = piece.display_char if piece.alive }
		puts "   ___ ___ ___ ___ ___ ___ ___ ___"
		y_count = 8
		board_arr.each_slice(8).each do |row|
			formatted_row = row.map(&:to_s).map{ |content| content.length == 1 ? " " + content + " " : content[0..1] }
			puts  y_count.to_s + " |" + formatted_row.join("|") + "|"
			puts "  |___|___|___|___|___|___|___|___|"
			y_count -= 1
		end
		puts "    a   b   c   d   e   f   g   h"
		puts 
		puts "Captured: " + captured_pieces.map(&:display_char).join(", ") if !captured_pieces.empty?
	end

	def in_check?(player)
		player_king = pieces.find { |piece| piece.type == :king && piece.player == player }
		is_threatened?(player_king)
	end

	def is_threatened?(player_piece)
		opponent_pieces = pieces.select { |piece| piece.player != player_piece.player }
		opponent_piece_types = opponent_pieces.map(&:type).uniq
		opponent_piece_types.any? do |type|
			opponent_pieces.select { |piece| piece.type == type }.any? do |piece|
				possible_move?(piece.type.to_s, piece.coords, player_piece.coords, piece.player)
			end
		end
	end

	def possible_queen_move?(start_coords, move_coords, player)
		possible_rook_move?(start_coords, move_coords, player) || possible_bishop_move?(start_coords, move_coords, player)
	end


	def possible_knight_move?(start_coords, move_coords, player)
		destination = pieces.find { |piece| piece.coords == move_coords } 
		
		ene = [start_coords[0] - 1, start_coords[1] + 2]
		nne = [start_coords[0] - 2, start_coords[1] + 1]
		nnw = [start_coords[0] - 2, start_coords[1] - 1]
		wnw = [start_coords[0] - 1, start_coords[1] - 2]
		wsw = [start_coords[0] + 1, start_coords[1] - 2]
		ssw = [start_coords[0] + 2, start_coords[1] - 1]
		sse = [start_coords[0] + 2, start_coords[1] + 1]
		ese = [start_coords[0] + 1, start_coords[1] + 2]
		
		empty_board_moves = [ene, nne, nnw, wnw, wsw, ssw, sse, ese].select do |move|
			(0 <= move[0] && move[0] <= 7) && (0 <= move[1] && move[1] <= 7)
		end

		if empty_board_moves.include?(move_coords)
			if destination
				return destination.player != player
			else
				return true
			end		
			return true
		else
			return false
		end
	end

	def possible_rook_move?(start_coords, move_coords, player)
		destination = pieces.find { |piece| piece.coords == move_coords }
		if ((destination && destination.player == player) || 
			(start_coords[0] != move_coords[0] && start_coords[1] != move_coords[1]))
			return false
		end

		if start_coords[0] == move_coords[0]
			row_obstacles = pieces.select { |piece| piece.coords[0] == start_coords[0] &&
				(
					start_coords[1] < piece.coords[1] && piece.cords[1] <= move_coords[1] || 
					move_coords[1] <= piece.coords[1] && piece.coords[1] < start_coords[1]
				)
			}
			return false if row_obstacles.length > 1
		else
			column_obstacles = pieces.select { |piece| piece.coords[1] == start_coords[1] &&
				(
					start_coords[0] < piece.coords[0] && piece.coords[0] <= move_coords[0] || 
					move_coords[0] <= piece.coords[0] && piece.coords[0] < start_coords[0]
				)
			}
			return false if column_obstacles.length > 1
		end

		return true
	end

	def possible_bishop_move?(start_coords, move_coords, player)
		destination = pieces.find { |piece| piece.coords == move_coords }
		if ((destination && destination.player == player) || 
			((start_coords[0] - move_coords[0]).abs != (start_coords[1] - move_coords[1]).abs))
			return false
		end

		if move_coords[0] - start_coords[0] == move_coords[1] - start_coords[1]
			positive_slope_obstacles = pieces.select do |piece| 
				piece.coords[0] - start_coords[0] == piece.coords[1] - start_coords[1] &&
				(
					start_coords[0] < piece.coords[0] && piece.coords[0] <= move_coords[0] ||
					move_coords[0] <= piece.coords[0] && piece.coords[0] < start_coords[0]
				)

			end
			return false if positive_slope_obstacles.length > 1
		else 
			negative_slope_obstacles = pieces.select do |piece| 
				piece.coords[0] - start_coords[0] == -(piece.coords[1] - start_coords[1]) &&
				(
					start_coords[0] < piece.coords[0] && piece.coords[0] <= move_coords[0] ||
					move_coords[0] <= piece.coords[0] && piece.coords[0] < start_coords[0]
				)

			end
			return false if negative_slope_obstacles.length > 1
		end

		return true
	end

	def possible_move?(piece_type, start_coords, move_coords, player)
		case piece_type
		when "bishop"
			possible_bishop_move?(start_coords, move_coords, player)
		when "rook"
			possible_rook_move?(start_coords, move_coords, player)
		when "knight"
			possible_knight_move?(start_coords, move_coords, player)
		when "queen"
			possible_queen_move?(start_coords, move_coords, player)
		end
	end

	def possible_moves(piece_type, start_coords, player)
		possible = []
		(0..7).each do |j|
			(0..7).each do |i|
				case piece_type
				when "bishop"
					if possible_bishop_move?(start_coords, [j,i], player)
						possible << [j,i]
					end
				when "rook"
					if possible_rook_move?(start_coords, [j,i], player)
						possible << [j,i]
					end
				when "knight"
					if possible_knight_move?(start_coords, [j,i], player)
						possible << [j,i]
					end
				when "queen"
					if possible_queen_move?(start_coords, [j,i], player)
						possible << [j,i]
					end
				end
			end
		end
		possible
	end

	# def possible_rook_moves(start_coords, player)
	# 	start_x = start_coords[1]
	# 	start_y = start_coords[0]
	# 	row_obstacles = pieces.select { | piece| piece.coords[0] == start_y }
	# 	column_obstacles = pieces.select { |piece| piece.coords[1] == start_x }

	# 	inf_x_piece = row_obstacles.select { |piece| piece.coords[1] < start_x }.inject do |tracker, candidate| 
	# 		candidate.coords[1] > tracker.coords[1] ? candidate : tracker
	# 	end

	# 	sup_x_piece = row_obstacles.select { |piece| piece.coords[1] > start_x }.inject do |tracker, candidate|
	# 		candidate.coords[1] < tracker.coords[1] ? candidate : tracker
	# 	end

	# 	inf_y_piece = column_obstacles.select { |piece| piece.coords[0] < start_y }.inject do |tracker, candidate|
	# 		candidate.coords[0] > tracker.coords[0] ? candidate : tracker
	# 	end

	# 	sup_y_piece = column_obstacles.select { |piece| piece.coords[0] > start_y }.inject do |tracker, candidate|
	# 		candidate.coords[0] < tracker.coords[0] ? candidate : tracker
	# 	end

	# 	min_x = inf_x_piece ? (inf_x_piece.player == player ? inf_x_piece.coords[1] + 1 : inf_x_piece.coords[1]) : 0
	# 	max_x = sup_x_piece ? (sup_x_piece.player == player ? sup_x_piece.coords[1] - 1 : sup_x_piece.coords[1]) : 7
	# 	min_y = inf_y_piece ? (inf_y_piece.player == player ? inf_y_piece.coords[0] + 1 : inf_y_piece.coords[0]) : 0
	# 	max_y = sup_y_piece ? (sup_y_piece.player == player ? sup_y_piece.coords[0] - 1 : sup_y_piece.coords[0]) : 7

	# 	possible = []
	# 	(min_y..max_y).each { |j| possible << [j, start_coords[1]] }
	# 	(min_x..max_x).each { |i| possible << [start_coords[0], i] }
	# 	possible.delete(start_coords)
	# 	possible
	# end

	def valid_move?(piece, move_x, move_y)
		case @type
		when :pawn
			valid_pawn_move?(piece, move_x, move_y)
		when :rook
			valid_rood_move?(piece, move_x, move_y)
		when :knight
			valid_knight_move?(piece, move_x, move_y)
		when :bishop
			valid_bishop_move?(piece, move_x, move_y)
		when :queen 
			valid_queen_move?(piece, move_x, move_y)
		when :king
			valid_king_move?(piece, move_x, move_y)
		end
	end

	def valid_pawn_move?(piece, move_x, move_y)
		true
	end
		
	def valid_rood_move?(piece, move_x, move_y)
		true
	end
			
	def valid_knight_move?(piece, move_x, move_y)
		true
	end
		
	def valid_bishop_move?(piece, move_x, move_y)
		true
	end
	
	def valid_queen_move?(piece, move_x, move_y)
		true
	end

	def valid_king_move?(piece, move_x, move_y)
		true
	end

	def to_index(coords)
		coords[0] * 8 + coords[1]
	end

	def to_coords(idx)
		[idx / 8, idx % 8]	
	end


end


class Piece
	attr_reader :player, :alive, :display_char
	attr_accessor :type, :x, :y, :coords
	def initialize(player, type, y, x, display_char)
		@type = type
		# @x = x
		# @y = y
		@player = player
		@alive = true
		@coords = [y,x]
		@display_char = display_char
	end

	def die!
		@alive = false
	end

	def move!(move_x, move_y)
		@x = move_x
		@y = move_y
		@coords = [y,x]
	end
end


#MAIN
# puts "Player 1, please enter your name:"
# player_1_name = gets.chomp
# puts "Player 2, please enter your name:"
# player_2_name = gets.chomp
# Game.new(player_1_name, player_2_name).play!

def test
	puts yield ? "pass" : "fail"
end


#Driver Code
game = Game.new("player_1", "player_2")
game.board.render
puts "Is player_2 in check?"
puts game.board.in_check?(game.player_2) ? "Yes" : "No"
puts "Moving queen..."
game.player_1.move!(game.board, 3, 7, 3, 1)
game.board.render
puts "Is player_2 in check now?"
puts game.board.in_check?(game.player_2) ? "Yes" : "No"

# puts "Testing rook-move-validator..."
# test { !game.board.possible_rook_move?([3,4],[4,6],game.player_1) }
# test { game.board.possible_rook_move?([3,4],[3,7],game.player_1) }
# test { game.board.possible_rook_move?([3,4],[2,4],game.player_1) }
# test { game.board.possible_rook_move?([3,4],[1,4],game.player_1) }
# test { !game.board.possible_rook_move?([3,4],[6,4],game.player_1) }

# puts "Testing bishop-move-validator..."
# test { !game.board.possible_bishop_move?([3,4], [5,5],game.player_1) }
# test { game.board.possible_bishop_move?([3,4], [4,5],game.player_1) }
# test { game.board.possible_bishop_move?([3,4], [4,3],game.player_1) }
# test { game.board.possible_bishop_move?([3,4], [2,5],game.player_1) }
# test { game.board.possible_bishop_move?([3,4], [2,3],game.player_1) }
# test { game.board.possible_bishop_move?([3,4],[1,2],game.player_1) }
# test { !game.board.possible_bishop_move?([3,4],[6,7],game.player_1) }

# puts "Testing knight-move-validator..."
# test { !game.board.possible_knight_move?([3,4], [4,1],game.player_1) }
# test { game.board.possible_knight_move?([3,4], [2,6],game.player_1) }




# puts "Possible knight moves from [3,4] for player_1:"
# game.board.pieces << Piece.new(game.player_1, :tester, 3, 4, "#")
# game.board.possible_moves("knight",[3,4], game.player_1).each do |move_coords|
# 	game.board.pieces << Piece.new(game.player_1, :indicator, move_coords[0], move_coords[1], ".")
# end
# game.board.render


