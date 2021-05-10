require 'net/http'
require 'nokogiri'
require 'json'
require 'optparse'

# 1.オプション解析

opt = OptionParser.new
opt.on('--infile=VAL')
opt.on('--outfile=VAL')
opt.on('--category=VAL')

params = {}
opt.parse!(ARGV, into: params)

if params[:infile] && params[:category]
  puts "Error: --infile と --category は同時に指定できません。"
  exit(1)
end

# 1.オプション解析ここまで

# 2.HTML読み込み

def get_from(url)
  Net::HTTP.get(URI(url))
end

# 4.ファイル書き出し

def write_file(path, text)
  File.open(path, 'w') { |file| file.write(text) }
end

# 3.スクレイピング

def scrape_news(news)
  {
    title: news.xpath('./p/strong/a').first.text,
    url: news.xpath('./p/strong/a').first['href']
  }
end

# 3.スクレイピング

def scrape_section(section)
  {
    category: section.xpath('./h6').text,
    news:  section.xpath('./div/div').map { |node| scrape_news(node) }
  }
end

# 2.HTML読み込み

if params[:infile]
  html = File.read(params[:infile])
else
  url = 'https://masayuki14.github.io/pit-news/'
  if params[:category]
    url = url + '?category=' + params[:category]
  end 
  html = get_from(url)
end

# 3.スクレイピング

doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

pitnews = doc.xpath('/html/body/main/section[position() > 1]').map { |section| scrape_section(section) }

# 4.ファイル書き出し

if params[:outfile]
  outfile = params[:outfile]
else
  outfile = 'pitnews.json'
end

write_file(outfile, {pitnews: pitnews}.to_json)

