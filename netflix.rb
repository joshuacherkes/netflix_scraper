require 'mechanize'
require 'open-uri'
require 'debugger'
require 'similar_text'
# login to netflix
agent = Mechanize.new
netflix = agent.get('http://movies.netflix.com/WiHome')
login_form = netflix.forms.first
login_form.email = 'EMAIL_ADDRESS_HERE'
login_form.password = 'PASSWORD_HERE'
agent.submit(login_form)

#now start getting categories

def scrape_altgenres(starting_number)
  n = starting_number
  loop do
    begin  
      netflix_page = agent.get("http://movies.netflix.com/WiAltGenre?agid=#{n}")
    rescue 
      retry
    end
    genre = netflix_page.at('#page-title a').content
    puts "netflix genre #{n} is #{genre}"
    File.open("netflix_genres.txt", 'a+') {|f| f.write( n.to_s + "\t" + genre + "\n") } 
    n += 1
  end 
end


def every_netflix_movie_ever(starting_number)
  agent = Mechanize.new
  netflix = agent.get('http://movies.netflix.com/WiHome')
  login_form = netflix.forms.first
  login_form.email = 'EMAIL_ADDRESS_HERE'
  login_form.password = 'PASSWORD_HERE'
  agent.submit(login_form)
  n = starting_number

  loop do
    begin  
      scrape(agent, n, 1)
    rescue 
      retry
    end
    n+=1
  end
end

def word_array_from_file(text_file)
  array = []
  words = []
  File.read(text_file).each_line do |line|
    array << line
  end
  genres = array.map {|line| line.split("\t")[1] }
  words = genres.map {|genre| genre.split(" ")}.flatten
  words
end

def genres_containing_by(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    wf[genre] += 1 if (genre.include?("by") && !(genre.include?("directed") || genre.include?("created")))
  end
  wf
end

def genres_containing_school(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    wf[genre] += 1 if (genre.include?("School") && !(genre.include?("High")))
  end
  wf
end

def genres_containing_era(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    wf[genre] += 1 if (genre.include?("Era"))
  end
  wf
end

def genres_containing_books(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    wf[genre] += 1 if (genre.include?("Books") && !(genre.include?("based on")))
  end
  wf
end

def genres_containing_in(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    wf[genre] += 1 if (genre.include?(" in ") && !(genre.include?("set")))
  end
  wf
end

def genres_containing_for(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    wf[genre] += 1 if (genre.include?(" for ") && !(genre.include?("Kids") || genre.include?("ages") ))
  end
  wf
end


def word_frequency_hash(array)
  wf = Hash.new(0)
  array.each do |word|
    wf[word] += 1
  end 
  wf
end

def genres(text_file)
  array = []
  words = []
  File.read(text_file).each_line do |line|
    array << line
  end
  genres = array.map {|line| line.split("\t")[1] }
  genres
end

def list_of_ampersand_words(genres)
  wf = Hash.new(0)
  genres.each do |genre|
    match = /\b\w+ & \w+\b/.match(genre).to_s 
    wf[match] += 1 unless match == ""
  end
  wf
end

# def test_scrape(n)
#   #login
#   agent = Mechanize.new
#   netflix = agent.get('http://movies.netflix.com/WiHome')
#   login_form = netflix.forms.first
#   login_form.email = 'EMAIL_ADDRESS_HERE'
#   login_form.password = 'PASSWORD_HERE'
#   agent.submit(login_form)
#   alt_genre = n.to_s
#   alt_genre_page = agent.get("http://movies.netflix.com/WiAltGenre?agid=#{alt_genre}&pn=1&np=1")
#   movie_results = alt_genre_page.search(".boxShot-166")
#   movie_results.each do |result|
#     title = result.children[0]['alt']
#     image = result.children[0]['src']
#     url = result.children[1]['href']
#     result_string = alt_genre + "\t" + title + "\t" + image + "\t" + url
#     puts result_string
#   end
# end   


def scrape(agent, alt_genre, page_number, prev_results = nil)

  #get new page
  alt_genre = alt_genre.to_s
  alt_genre_page = agent.get("http://movies.netflix.com/WiAltGenre?agid=#{alt_genre}&pn=#{page_number.to_s}&np=1")
  movie_results = alt_genre_page.search(".boxShot-166")
  movie_ids = movie_results.map {|result| result['id']}
  #check if we are the last page 
  if movie_ids == prev_results
    puts "completed alt_genre #{alt_genre}"
  elsif alt_genre_page.at('#page-title a').content.empty?
    puts "alt_genre has no title"
  else
    movie_results.each do |result|
      title = result.children[0]['alt'].strip
      image = result.children[0]['src'].strip
      url = result.children[1]['href']
      result_string = alt_genre + "\t" + title + "\t" + image + "\t" + url + "\t" + page_number.to_s + "\n"
      puts result_string
      File.open("netflix_movies.txt", 'a+') {|f| f.write(result_string) } 
    end
    scrape(agent, alt_genre.to_i, page_number + 1, movie_ids)
  end
end

def make_genre_file(genres)
  genres.each do |genre|
    File.open("netflix_genres_no_numbers.txt", 'a+') {|f| f.write(genre) } unless genre.strip.empty?
  end
end


def most_similar_genres(genre, text_file)
  array = []
  percentages = Hash.new(0)
  File.read(text_file).each_line do |line|
    array << line
  end
  array.each do |test_genre|
    percentages[test_genre] = genre.similar(test_genre)
  end
  percentages.sort_by {|key, value| value}.reverse
end






# def scrape_movies_from_(n, page_number = 1, previous_page_search_results = nil)
#   login
#   agent = Mechanize.new
#   netflix = agent.get('http://movies.netflix.com/WiHome')
#   login_form = netflix.forms.first
#   login_form.email = 'EMAIL_ADDRESS_HERE'
#   login_form.password = 'PASSWORD_HERE'
#   agent.submit(login_form)



#   alt_genre = n.to_s
#   if previous_page_search_results.nil?
#     alt_genre_page = agent.get("http://movies.netflix.com/WiAltGenre?agid=#{alt_genre}&pn=1&np=1")
#     movie_results = alt_genre_page.search(".boxShot-166")
#     movie_results.each do |result|
#       title = result.children[0]['alt']
#       image = result.children[0]['src']
#       url = result.children[1]['href']
#       result_string = alt_genre + "\t" + title + "\t" + image + "\t" + url
#       puts result_string
#     end
#     previous_page_search_results = movie_results.map {|result| result['id']}
#     #call again
#     scrape_movies_from_((n + 1), alt_genre_page)
#   else
#     alt_genre_page = agent.get("http://movies.netflix.com/WiAltGenre?agid=#{alt_genre}&pn=1&np=1")
    

# WiGenre?agid=83&pn=38&np=1
#   alt_genre_page = agent.get("http://movies.netflix.com/WiAltGenre?agid=#{alt_genre}")
#   movie_results = alt_genre_page.search(".boxShot-166")
#   movie_results.each do |result|
#     title = result.children[0]['alt']
#     image = result.children[0]['src']
#     url = result.children[1]['href']
#     result_string = alt_genre + "\t" + title + "\t" + image + "\t" + url
#     puts result_string
#   end
# end








