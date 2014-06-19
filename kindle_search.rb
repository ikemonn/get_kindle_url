require 'amazon/ecs'
require File.dirname(__FILE__) + '/conf'

Amazon::Ecs.options = {
  :associate_tag => ASSOCIATE_TAG,
  :AWS_access_key_id => AWS_ACCESS_KEY_ID,
  :AWS_secret_key => AWS_SECRET_KEY
}

# 検索キーワードに引っかかった本のタイトルとURLを取得する
def get_title_url(keyword)
  retry_count = 0

  # 検索処理
  begin
    # APIの呼び出し
    res = Amazon::Ecs.item_search(keyword, {:response_group => 'ItemAttributes', :country => 'jp', :search_index => 'KindleStore'})
  rescue
    # エラーが帰ってきたら５秒待ってリトライ
    retry_count += 1
    if retry_count < 5
      sleep 5
      retry
    else
      return false
    end
  end

  # XMLをパース
  xml_doc =  Nokogiri::XML(res.marshal_dump)

  # 本情報の配列
  book_list =  Hash.new { |hash,key| hash[key] = Hash.new {} }

  puts 'keyword: ' + keyword
  # 検索結果があるかチェック
  error_msg = xml_doc.xpath("//Error")
  if error_msg.empty? == false
    p "検索結果がありませんでした。"
    return
  end

  # 書名取得
  title_list = xml_doc.xpath("//Title")
  title_list.each_with_index do |title, count|
    book_list[count][:title] = title.text
  end

  # url取得
  url_list = xml_doc.xpath("//DetailPageURL")
  url_list.each_with_index do |url, count|
    book_list[count][:url] = url.text
  end

  # 表示
  book_list.each do |key, book|
     puts 'Title: ' + book[:title]
     puts 'URL: ' + book[:url]
  end

end


if ARGV[0].nil?
  puts "引数にファイルを指定してください。"
  exit
end
file = ARGV[0]

File.readlines(File.dirname(__FILE__) + '/' + file).each do |row|
  result = get_title_url(row)
  if result == false
    puts "エラーが発生しました。"
  end
  puts "-------------------------------------------------------"
  sleep 3
end
