require 'net/http'

def get_from(url)
  Net::HTTP.get(URI(url))
end

def write_file(path, text)
  File.open('techable.html', 'w') { |file| file.write(text) }
end

write_file('techable.html', get_from('https://techable.jp/'))
