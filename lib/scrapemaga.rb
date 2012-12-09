# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'uri'

class ScrapeMaga

  NEXT_PATTERN = %w/次へ 次の >> 次 next/

  attr_accessor :url, :use_cache, :show_progress, :_cache_dir
  attr_accessor :downloaded_images, :downloaded_urls
  attr_accessor :__debug

  def initialize(url)

    self.__debug = true

    self.use_cache = false
    self.show_progress = true
    self._cache_dir = '/tmp/scrape_maga'
    self.downloaded_urls = []
    self.downloaded_images = []

    self.url = url

    Dir.mkdir(_cache_dir, 0777) if _cache_dir && !File.exist?(_cache_dir)

    Dir.mkdir(cache_dir_path, 0777) if !File.exist?(cache_dir_path)


  end

  def cache_key
    url_to_key(url)
  end

  def cache_html_path
    "#{_cache_dir}/#{cache_html_name}"
  end

  def cache_html_name
    "#{cache_key}.html"
  end

  def cache_dir_path
    "#{_cache_dir}/#{cache_key}"
  end

  
  def data

    return @data if @data

    put_progress("getting data with #{url}")

    _data = cache if use_cache
    if !_data
      begin
        _uri = open(url)
        _data = _uri.read
        # _data.force_encoding(_uri.charset) if _uri.charset
        _debug("data.encoding = #{_data.encoding}")
        # _data.encode!("utf8", :invalid => :replace)
      rescue OpenURI::HTTPError
      end
    end
    add_cache(_data) if use_cache && _data

    @data = _data ? _data : nil
    return @data

  end


  def cache

    put_progress("getting cache with #{url}")

    raise "no cache dir" if !File.directory?(_cache_dir)

    Dir.foreach(_cache_dir) do |file|

      if file == cache_html_name
        return open(cache_html_path).read
      end

    end

    return nil

  end

  def add_cache(_data)
    raise "no cache dir" if !File.directory?(_cache_dir)

    put_progress("Cache File open with #{cache_dir_path}")

    if !File.exist?(cache_html_path)
      File.open(cache_html_path, "w") do |f|
        f.write(_data)
      end
    end

  end

  def clear_cache
    raise "no cache dir" if !File.directory?(_cache_dir)

    FileUtils.remove_entry(_cache_dir)

  end

  def url_to_key(_url)
    _url.gsub(/[\/\._:-]/,'-').gsub(/[^0-9a-zA-Z-]/, '_')
  end


  def get 
    if !self.url
      puts "no url!!\n"
      exit 1
    end

    return if !data

    return if downloaded_urls.include?(url)
    downloaded_urls << url
    
    doc = Nokogiri::HTML(data)

    doc.css('img').each do |imgtag|
      _debug(imgtag['src'])
      img_src = imgtag['src']

      next if !img_src
      img_src = fix_domain(img_src)
      next if !check_domain(img_src)
      
      # downloading parallel

      download_img(cache_dir_path, img_src)

      # check_image()

      create_pdf

    end

    # get next key
    doc.css('a').each do |atag|
      cont = atag.content
      put_progress("check next pattern with #{cont}")
      NEXT_PATTERN.each do |pat|
        if cont.include?(pat)
          next_url = fix_domain(atag['href'])
          if check_domain(next_url)
            if !downloaded_urls.include?(next_url)
              # TODO threading
              _debug("create new ScrapeMage instance with #{next_url}")
              sm = ScrapeMaga.new(next_url)
              sm.get

              self.downloaded_urls = self.downloaded_urls + sm.downloaded_urls
            end
          end

        end
      end
    end


    # create all pdf
    # TODO rmagick
    pdf_filename = url_to_key(URI.parse(downloaded_urls.first).host) + ".pdf"

    files = downloaded_urls.map{|_url|
      name = "#{_cache_dir}/#{url_to_key(_url)}.pdf"
      File.exist?(name) ? name : nil
    }.compact.join(" ")

    `cd #{_cache_dir} && convert #{files} ../#{pdf_filename}`

  end

  def fix_domain(fixable_url)
    ret_uri = URI.parse(fixable_url)
    original_uri = URI.parse(url)
    ret_uri = original_uri.dup.merge(fixable_url) if !ret_uri.host 
    return ret_uri.to_s
  end
  def check_domain(fixable_url)
    ret_uri = URI.parse(fixable_url)
    original_uri = URI.parse(url)
    return ret_uri.host == original_uri.host
  end

  def download_img(_dir, _url)

    put_progress("downloading img #{_url}")

    return if downloaded_images.include?(_url)
    downloaded_images << _url

    # TODO set Thread

    basename = File.basename(URI.parse(_url).path)
    filepath = "#{_dir}/#{basename}"

    return if File.exist?(filepath)

    _data = open(_url).read
    File.open(filepath, "w") do |f|
      f.write(_data)
    end

  end

  def create_pdf

    # TODO use rmagick

    files = downloaded_images.map{|_url| File.basename(URI.parse(_url).path)}.join(" ")
    `cd #{cache_dir_path} && convert #{files} ../#{cache_key}.pdf`

  end

  def put_progress(str)
    if self.show_progress
      puts "SCRAPEMAGA::#{Time.now}::#{str}\n"
    end
  end

  def _debug(str)
    if __debug
      puts "SCRAPEMAGA_DEBUG::#{Time.now}::#{str}\n"
    end
  end

end

