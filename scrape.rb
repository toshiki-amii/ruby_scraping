require 'net/http'
require 'nokogiri'
require 'json'
require 'optparse'

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

def get_from(url)
  Net::HTTP.get(URI(url))
end

def write_file(path, text)
  File.open(path, 'w') { |file| file.write(text) }
end

def scrape_news(news)
  {
    title: news.xpath('./p/strong/a').first.text,
    url: news.xpath('./p/strong/a').first['href']
  }
end

def scrape_section(section)
  {
    category: section.xpath('./h6').text,
    news:  section.xpath('./div/div').map { |node| scrape_news(node) }
  }
end

if params[:infile]
  html = File.read(params[:infile])
else
  url = 'https://masayuki14.github.io/pit-news/'
  if params[:category]
    url = url + '?category=' + params[:category]
  end 
  html = get_from(url)
end

doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

pitnews = doc.xpath('/html/body/main/section[position() > 1]').map { |section| scrape_section(section) }

if params[:outfile]
  outfile = params[:outfile]
else
  outfile = 'pitnews.json'
end

write_file(outfile, {pitnews: pitnews}.to_json)

