require 'logger'
require 'open-uri'
require 'time'
require 'nokogiri'

BASE_URL = 'http://atnd.org/events/'

def get_atnd(id, ua = '')
  log = Logger.new('./log/crawl.log')
  data = { }
  data[:id] = id
  data[:check_time] = Time.now

  url = BASE_URL + id.to_s
  log.info("Try #{url}")

  begin
    doc = (Nokogiri::HTML(open(url, 'User-Agent' => ua).read)/'div.wrapper')

    # title / subtitle
    data[:title] = (doc/'hgroup.title.clearfix'/'h1').inner_text
    data[:subtitle] = (doc/'hgroup.title.clearfix'/'h2').inner_text

    # event informations
    elements = (doc/'div.main'/'div.events-show-info.dl-items.a-b'/'dl')
    # start/end time
    data[:time_start] = Time.parse((elements[0]/'dd'/'abbr.dtstart').attribute('title').value)
    data[:time_end] = Time.parse((elements[0]/'dd'/'abbr.dtend').attribute('title').value) if !(elements[0]/'dd'/'abbr.dtend').empty?

    # capacity
    data[:capacity] = (elements[1]/'dd').inner_text.to_i

    # location
    data[:location] = (elements[2]/'dd').inner_text
    data[:address] = (elements[2]/'dd'/'span').inner_text

    # url
    data[:event_url] = (elements[3]/'dd'/'a').attribute('href').value

    # owner/account
    data[:owner_name] = (elements[4]/'dd').inner_text
    data[:owner_account] = (elements[4]/'dd'/'a').attribute('href').value

    # hashtag
    data[:hashtag] = (elements[5]/'dd').inner_text

    # body
    data[:body_html] = (doc/'div.mg-b20').inner_html
    data[:body_text] = (doc/'div.mg-b20').inner_text

    # menber info
    member_info = (doc/'aside.side'/'div#members-info'/'li'/'strong')
    data[:join_size] = member_info[0].inner_text.to_i

    case member_info.size
    when 2
      data[:cancel_size] = member_info[1].inner_text.to_i
    when 3
      data[:sub_size] = member_info[1].inner_text.to_i
      data[:cancel_size] = member_info[2].inner_text.to_i
    end

    # join member
    data[:join_members] = [ ]
    (doc/'aside.side'/'section#members-join'/'li').each do |e|
      member = {  }
      member[:name] = (e/'a').inner_text
      member[:url] = (e/'a').attribute('href').value
      member[:comment] = (e/'em').inner_text
      data[:join_members].push member
    end

    # cancel member
    data[:cancel_members] = [ ]
    (doc/'aside.side'/'section#members-cancel'/'li').each do |e|
      member = {  }
      member[:name] = (e/'a').inner_text
      member[:url] = (e/'a').attribute('href').value
      member[:comment] = (e/'em').inner_text
      data[:cancel_members].push member
    end
  rescue => e
    log.error("Failed to #{url}: #{e.message}")
    data[:error] = e.message
  end

  data
end

if __FILE__ == $0
  p get_atnd(1)
end
