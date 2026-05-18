class GamesController < ApplicationController
  VOWELS     = %w[A E I O U].freeze
  CONSONANTS = (('A'..'Z').to_a - VOWELS).freeze
  DICTIONARY_API = "https://dictionary.lewagon.com/".freeze

  def new
    # 5 vowels + 5 consonants, shuffled
    @letters  = Array.new(5) { VOWELS.sample }
    @letters += Array.new(5) { CONSONANTS.sample }
    @letters.shuffle!

    # Reset score at the start of a new game (keep grand total)
    session[:grand_score] ||= 0
  end

  def score
    @letters = params[:letters].split
    @word     = params[:word].upcase.strip

    if valid_in_grid?(@word, @letters)
      if valid_english_word?(@word)
        @result  = :congrats
        @message = "🎉 Congratulations! \"#{@word}\" is valid and scores #{@word.length} points."
        session[:grand_score] = (session[:grand_score] || 0) + @word.length
      else
        @result  = :not_english
        @message = "❌ \"#{@word}\" can be built from the grid, but is not a valid English word."
      end
    else
      @result  = :cant_build
      @message = "❌ \"#{@word}\" cannot be built from the letters #{params[:letters]}."
    end

    @grand_score = session[:grand_score]
  end

  private

  def valid_in_grid?(word, letters)
    remaining = letters.dup
    word.chars.all? do |char|
      idx = remaining.index(char)
      return false if idx.nil?
      remaining.delete_at(idx)
      true
    end
  end

  def valid_english_word?(word)
    response = Net::HTTP.get(URI("#{DICTIONARY_API}#{word.downcase}"))
    JSON.parse(response)["found"]
  rescue
    false
  end
end
