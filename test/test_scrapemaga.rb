require 'test/unit'
require 'scrapemaga'

class ScrapeMagaTest < Test::Unit::TestCase

  def setup
    @url = 'http://comichitokui.web.fc2.com/90.html'
  end


  def test_initialize
    ScrapeMaga.new(@url)
  end

  def test_scrape

    sm = ScrapeMaga.new(@url)
    sm.get

  end

  def teardown
    # ScrapeMaga.new(@url).clear_cache
  end

end

