require 'net/http'
require 'nokogiri'
require 'json'
require 'optparse'

# 1.オプション解析

class PreProcesser
  def self.exec(argv)
    opt = OptionParser.new
    opt.on('--infile=VAL')
    opt.on('--outfile=VAL')
    opt.on('--category=VAL')

    params = {}
    opt.parse!(ARGV, into: params)    
    raise "Error: --infile と --category は同時に指定できません。" if params[:infile] && params[:category]
    params
  end
end

# 2.HTML読み込み

class HtmlReader

  def initialize(options)
    @infile   = options[:infile]
    @category = options[:category]
  end

  def read_website
    url = 'https://masayuki14.github.io/pit-news/'
    url = url + '?category=' + @category if @category
    Net::HTTP.get(URI(url))
  end

  def read
    if @infile
      File.read(@infile)
    else
      read_website
    end
  end

end


# 3.スクレイピング

class Scraper

  def self.scrape_news(news)
    {
      title: news.xpath('./p/strong/a').first.text,
      url: news.xpath('./p/strong/a').first['href']
    }
  end
  
  def self.scrape_section(section)
    {
      category: section.xpath('./h6').text,
      news:  section.xpath('./div/div').map { |node| scrape_news(node) }
    }
  end

  def self.scrape(html)
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')
    doc.xpath('/html/body/main/section[position() > 1]').map { |section| scrape_section(section) }
  end
end




# 4.ファイル書き出し

class JsonWriter

  def initialize(options)
    @outfile = options(:outfile)
  end

  def write_file(path, text)
    File.open(path, 'w') { |file| file.write(text) }
  end
  
  def write(pitnews)
    outfile = @outfile || 'pitnews.json'
    write_file(outfile, {pitnews: pitnews}.to_json)    
  end
end


params = PreProcesser.exec(ARGV)
html = HtmlReader.read(params)
pitnews = Scraper.scrape(html)
JsonWriter.write(params, pitnews)

