
require 'nokogiri'
require 'open-uri'

class ScrapeMaga

  attr_accessor :use_cache, :show_progress

  def initialize

    self.use_cache = false
    self.show_progress = true

  end

  def get 
    url = ARGV.first || 'http://comichitokui.web.fc2.com/1.html'
    if !url
      puts "no url!!\n"
      exit 1
    end
    
    
    if use_cache
    
    else
      data = open(url).read
      doc = Nokogiri::HTML(data)
      p doc
    end

  end

  def put_progress(str)
    if self.show_progress
      puts "#{Time.now} hoge"
    end
  end

end

