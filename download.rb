#!/usr/bin/env ruby
require 'date'
require 'fileutils'
require 'nokogiri'
require 'open-uri'
require 'uri'

def read(url)
  Nokogiri::HTML(open(url), url)
end

def download(element, folder, file = nil)
  uri = URI.join(element.document.url, URI.encode(element['href']).sub(/^http:/, 'https:'))
  file = File.join(__dir__, "mtr-#{Date.today.to_s}", folder, file || File.basename(element['href']))
  FileUtils.mkdir_p(File.dirname(file))
  puts "Downloading #{uri} ..."
  IO.copy_stream(open(uri), file)
end

fares = read('https://www.mtr.com.hk/en/customer/tickets/octopus_fares.html')
fares.css('[href$=pdf]').each do |fare|
  download(fare, 'Fares')
end

maps = read('https://www.mtr.com.hk/en/customer/services/system_map.html')
download(maps.at_css('[href$=pdf]'), 'Maps')
maps.css('.generalcontent table').each do |line|
  stations      = line.at_css('td:nth-child(1)').xpath('text()')
  location_maps = line.css('td:nth-child(2) a')
  layout_maps   = line.css('td:nth-child(3) a')
  location_folder = line.at_css('th:nth-child(2)').text.strip
  layout_folder   = line.at_css('th:nth-child(3)').text.strip
  location_maps.each_with_index do |_, i|
    station_file = "#{stations[i].text.strip}.pdf"
    download(location_maps[i], File.join('Maps', location_folder), station_file)
    download(layout_maps[i],   File.join('Maps', layout_folder),   station_file)
  end
end

alternatives = read('https://www.mtr.com.hk/en/customer/services/needs_index.html')
alternatives.css('[href$=pdf]').each do |alternative|
  download(alternative, 'Alternatives', "#{alternative.text.strip}.pdf")
end
