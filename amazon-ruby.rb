# coding: utf-8
require 'nokogiri'
require 'open-uri'
require 'nkf'

# step 1: convert book url to mobile url format for easy parsing
#amazon mobile website http://www.amazon.com/gp/aw
def parse_page_number (isbn,page_number=1)
  if page_number <0 
    page_number=1
  end

  mobile_reviews_url = "http://www.amazon.co.jp/gp/aw/"+isbn

  max_number_of_reviews_pages = number_of_reviews_pages(parse_all_reviews_count(mobile_reviews_url))
  if page_number > max_number_of_reviews_pages
    search_page_number = max_number_of_reviews_pages
  else
    search_page_number = page_number
  end

  mobile_reviews_url ="http://www.amazon.co.jp/gp/aw/cr/"+isbn+"/p="+search_page_number.to_s

  p mobile_reviews_url
  extract_reviews_urls_from_main_reviews_page (mobile_reviews_url)
end

#download url full page to retreive number of reviews, since number of reviews
# is not available in mobile version
def parse_all_reviews_count (url)
  parse_reviews_count = Nokogiri::HTML(open(url))
  parse_reviews_count.css('span.crAvgStars a').each do |i|
    if i.text =~ /\d* customer reviews/i
      return /\d*/.match(i.text)[0]
    end
  end
end

#detect number of reviews pages based on number of reviews since there is only
# 10 reviews in each page
def number_of_reviews_pages (reviews_count)
  if reviews_count <= 10
    pages_count = 1
  else 
    number_of_review_last_page = reviews_count % 10
    pages_count = (reviews_count-number_of_review_last_page)/10
    if number_of_review_last_page > 0
      pages_count = pages_count +1
    else
      pages_count = pages_count +0
    end
  end
end	

# extract each review url from specific page, usually 10 urls Max
def extract_reviews_urls_from_main_reviews_page current_page_url

  extracted_reviews_urls=[]
  parse_reviews_page_one = Nokogiri::HTML(open(current_page_url))
  parse_reviews_page_one.css('a').each do |i|	
    if i['href'].to_s.match(/\/gp\/aw\/cr\/r/)
      extracted_reviews_urls.push(i['href'])
    end
  end
  parse_page_all_reviews_in_page (extracted_reviews_urls)
end

# parse each review link to fetch data (all links of a single page)
def parse_page_all_reviews_in_page all_reviews_urls
  all_reviews_details=[]
  for single_review_url in all_reviews_urls
    full_url = "http://amazon.co.jp"+ single_review_url
    parse_single_review = Nokogiri::HTML(open(full_url))
    single_review_details={}
    parse_single_review.css('html body font').each do |i|	
      # レビューのあるデータを取得 
      if i.text =~ /.*├/
        s = i.text
        s.sub!(/.*└/, "")

        if s =~ /Amazon.co.jpで購入済み/
          s.sub!(/^.*Amazon.co.jpで購入済み/, "")
        end

        # 半角カナを全角カナ, 全角英数を半角英数, 全角スペースを半角スペース変換
        s = NKF::nkf('-Z1 -Ww', s)

        puts s
        puts "---------------------------------"

        single_review_details = s
      end	 
    end
    all_reviews_details.push(single_review_details)
  end
  p all_reviews_details
end

asin = "4088767624"
page_number = 6
parse_page_number(asin, page_number.to_i)
