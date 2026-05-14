# frozen_string_literal: true

require 'net/http'
require 'nokogiri'
require 'json'
require 'uri'

API_URL = ENV.fetch('API_URL', 'http://localhost:4567')
SECRET  = ENV.fetch('CRAWLER_SECRET', '')
TARGETS = File.join(__dir__, 'targets.txt')

def fetch_page(url)
  uri = URI.parse(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 15) do |http|
    http.get(uri.request_uri, 'User-Agent' => 'WhoKnowsBot/1.0')
  end
  return nil unless response.code == '200'

  response.body
rescue StandardError => e
  warn "fetch error #{url}: #{e.message}"
  nil
end

def extract(html, url)
  doc = Nokogiri::HTML(html)
  doc.css('script, style, nav, footer, header').each(&:remove)
  title   = doc.at('title')&.text&.strip || url
  lang    = doc.at('html')&.[]('lang').to_s.split('-').first
  lang    = %w[en da].include?(lang) ? lang : 'en'
  content = doc.at('body')&.text&.gsub(/\s+/, ' ')&.strip || ''
  { 'title' => title, 'url' => url, 'language' => lang, 'content' => content }
end

def post_pages(pages)
  uri = URI.parse("#{API_URL}/api/pages")
  req = Net::HTTP::Post.new(uri)
  req['Content-Type']     = 'application/json'
  req['X-Crawler-Secret'] = SECRET
  req.body = pages.to_json

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    res = http.request(req)
    puts "POST /api/pages -> #{res.code} #{res.body}"
  end
rescue StandardError => e
  warn "post error: #{e.message}"
end

urls = File.readlines(TARGETS, chomp: true).reject { |l| l.strip.empty? || l.start_with?('#') }
pages = urls.filter_map do |url|
  print "Scraping #{url} ... "
  html = fetch_page(url)
  unless html
    puts 'skipped'
    next
  end
  page = extract(html, url)
  puts "ok (#{page['language']}, #{page['content'].length} chars)"
  page
end

post_pages(pages) unless pages.empty?
