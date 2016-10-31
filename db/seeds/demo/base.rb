# encoding: utf-8

site_name = "ZOMEKI"

zomeki_site = Cms::Site.find(1)

## ---------------------------------------------------------
## methods

def load_demo(name)
  puts "import #{name}..."
  load "#{Rails.root}/db/seeds/demo/#{name}.rb"
end

def read_data(path)
  path = "#{Rails.root}/db/seeds/demo/#{path}.txt"
  return nil unless FileTest.exists?(path)
  ::File.new(path).read.force_encoding('utf-8')
end

## ---------------------------------------------------------
## sys/groups

puts "import sys_groups..."

def create(site, parent, level_no, sort_no, code, name, name_en)
  group = Sys::Group.create! parent_id: (parent == 0 ? 0 : parent.id),
    level_no:  level_no,
    sort_no:   sort_no,
    state:     'enabled',
    web_state: 'closed',
    ldap:      0,
    code:      code,
    name:      name,
    name_en:   name_en,
    tel:       '0000-01-0000',
    fax:       '0000-01-0000',
    email:     'info@sitebridge.co.jp'
  site.groups << group
  return group
end

r = Sys::Group.find(1)

p = create zomeki_site, r, 2, 10, "1", "総務部", "somu"
    create zomeki_site, p, 3, 10, "1001", "職員課", "shokuin"
    create zomeki_site, p, 3, 20, "1002", "契約管理課", "keiyakukanri"
    create zomeki_site, p, 3, 30, "1003", "防災課", "bosai"
    create zomeki_site, p, 3, 40, "1004", "法務課", "homu"

p = create zomeki_site, r, 2, 20, "2", "企画部", "kikaku"
    create zomeki_site, p, 3, 10, "2001", "IT推進課", "itsuishinka"
    create zomeki_site, p, 3, 20, "2002", "企画経営課", "kikakukeiei"
    create zomeki_site, p, 3, 30, "2003", "財政課", "zaisei"
    create zomeki_site, p, 3, 40, "2004", "秘書広報課", "hishokoho"
    create zomeki_site, p, 3, 50, "2005", "情報推進課", "johosuishin"

p = create zomeki_site, r, 2, 30, "3", "生活部", "seikatsu"
    create zomeki_site, p, 3, 10, "3001", "市民課", "shimin"
    create zomeki_site, p, 3, 20, "3002", "税務課", "zeimu"
    create zomeki_site, p, 3, 30, "3003", "保健課", "hoken"

p = create zomeki_site, r, 2, 40, "4", "環境部", "kankyo"
    create zomeki_site, p, 3, 10, "4001", "環境政策課", "kankyoseisaku"
    create zomeki_site, p, 3, 20, "4002", "生活経済課", "seikatsukeizai"
    create zomeki_site, p, 3, 30, "4003", "安全安心課", "anzenanshin"

p = create zomeki_site, r, 2, 50, "5", "保健福祉部", "hokenfukushi"
    create zomeki_site, p, 3, 10, "5001", "子育て支援課", "kosodateshien"
    create zomeki_site, p, 3, 20, "5002", "地域福祉課", "chiikifukushi"
    create zomeki_site, p, 3, 30, "5003", "高齢者支援課", "koreishashien"
    create zomeki_site, p, 3, 40, "5004", "生活福祉課", "seikatsufukushika"
    create zomeki_site, p, 3, 50, "5005", "健康推進課", "kenkosuishin"
    create zomeki_site, p, 3, 60, "5006", "障害福祉課", "shogaifukushi"

p = create zomeki_site, r, 2, 60, "6", "都市整備部", "toshiseibi"
    create zomeki_site, p, 3, 10, "6001", "下水道課", "gesuido"
    create zomeki_site, p, 3, 20, "6002", "土木課", "doboku"
    create zomeki_site, p, 3, 30, "6003", "建築住宅課", "kenchikujyutaku"
    create zomeki_site, p, 3, 40, "6004", "道路交通課", "dorokotsu"
    create zomeki_site, p, 3, 50, "6005", "都市計画課", "toshikeikaku"

p = create zomeki_site, r, 2, 70, "7", "観光経済部", "kankokeizai"
    create zomeki_site, p, 3, 10, "7001", "商工課", "shoko"
    create zomeki_site, p, 3, 20, "7002", "農林水産課", "norinsuisan"
    create zomeki_site, p, 3, 30, "7003", "観光振興課", "kankoshinko"

p = create zomeki_site, r, 2, 80, "8", "消防本部", "shobohonbu"
    create zomeki_site, p, 3, 10, "8001", "消防本部総務課", "shobo-somu"
    create zomeki_site, p, 3, 20, "8002", "予防課", "yobo"
    create zomeki_site, p, 3, 30, "8003", "消防署", "shobosho"

p = create zomeki_site, r, 2, 90, "9", "議会事務局", "gikaijimukyoku"

p = create zomeki_site, r, 2, 100, "10", "選挙管理委員会事務局", "senkyokanriiinkaijimukyoku"

p = create zomeki_site, r, 2, 110, "11", "監査委員事務局", "kansaiinjimukyoku"


## ---------------------------------------------------------
## current_user

Core.user       = Sys::User.find_by(account: 'zomeki')
Core.user_group = Core.user.groups[0]

## ---------------------------------------------------------
## cms/sites

Cms::Site.update_all({:name => site_name})


## ---------------------------------------------------------
## cms/concepts

puts "import cms_concepts..."

def create_cms_concept(parent, sort_no, name)
  Cms::Concept.create parent_id: parent.id,
    site_id: 1,
    state: 'public',
    level_no: parent.level_no + 1,
    name: name
end

c_site  = Cms::Concept.find(1)
c_site.name = 'ルート'
c_site.save

c_top      = create_cms_concept c_site,  10, 'トップページ'
c_contents = create_cms_concept c_site,   20, 'コンテンツ'

c_event    = create_cms_concept c_contents, 10, 'イベント'

c_event    = create_cms_concept c_event, 10, 'イベント一覧'
c_event    = create_cms_concept c_event, 20, 'カレンダー'

             create_cms_concept c_contents, 20, '施設案内'
c_gnavi    = create_cms_concept c_contents, 30, 'グローバルナビ'

c_gnavi1   = create_cms_concept c_gnavi, 10, '暮らしのガイド'
c_gnavi2   = create_cms_concept c_gnavi, 20, '子育て・教育'
c_gnavi3   = create_cms_concept c_gnavi, 30, '観光・文化'
c_gnavi4   = create_cms_concept c_gnavi, 40, '事業者の方へ'
c_gnavi5   = create_cms_concept c_gnavi, 50, '市政情報'

c_mayor    = create_cms_concept c_top,   30,'市長の部屋'
c_gikai    = create_cms_concept c_top,   40,'市議会'


## ---------------------------------------------------------
## cms/contents

puts "import cms_conctents..."

def create_cms_content(concept, model, name, code)
  Cms::Content.create site_id: 1,
    concept_id: concept.id,
    state: 'public',
    model: model,
    name: name,
    code: code
end

## ---------------------------------------------------------
## cms/layouts

puts "import cms_layouts..."

def create_cms_layout(concept, name, title)
  Cms::Layout.create site_id: 1,
    concept_id: concept.id,
    state: 'public',
    head: read_data("layouts/#{name}/head"),
    body: read_data("layouts/#{name}/body"),
    mobile_head: read_data("layouts/#{name}/m_head"),
    mobile_body: read_data("layouts/#{name}/m_body"),
    smart_phone_head: read_data("layouts/#{name}/s_head"),
    smart_phone_body: read_data("layouts/#{name}/s_body"),
    name: name,
    title: title
end

l_top       = create_cms_layout c_top,  'top',     'トップ'
l_doc       = create_cms_layout c_site, 'doc',          '記事'
l_col1      = create_cms_layout c_site, 'col-1',        '固定ページ（1カラム）'
l_mayor     = create_cms_layout c_mayor, 'mayor',        '市長の部屋'
l_gikai     = create_cms_layout c_gikai, 'gikai',        '市議会'
l_emergency = create_cms_layout c_top,  'emergency-top','大規模災害時表示（TOPページ）'

## ---------------------------------------------------------
## cms/pieces

puts "import cms_pieces..."

def create_cms_piece(concept, model, name, title, content_id = nil)
  Cms::Piece.create site_id: 1,
    concept_id: concept.id,
    content_id: content_id,
    state: 'public',
    model: model,
    name: name,
    title: title,
    body: read_data("pieces/#{name}/body"),
    xml_properties: read_data("pieces/#{name}/xml_properties")
end

[
  [ c_site,   'Cms::Free', 'pc-switch', 'スマートフォン版切り替えボタン' ],
  [ c_site,   'Cms::Free', 'accessibility-tool', 'ふりがな・よみあげヘッダー' ],
  [ c_site,   'Cms::Free', 'common-header', '共通ヘッダー' ],
  [ c_site,   'Cms::Free', 'global-navi', 'グローバルナビ' ],
  [ c_top,    'Cms::Free', 'lifeevent', 'ライフイベント' ],
  [ c_top,    'Cms::Free', 'guide', '暮らしのガイド' ],
  [ c_top,    'Cms::Free', 'bn-mayor', '市長の部屋バナー' ],
  [ c_top,    'Cms::Free', 'bn-contets', '左サイドバナー（下部）' ],
  [ c_top,    'Cms::Free', 'bn-gikai', '議会バナー' ],
  [ c_top,    'Cms::Free', 'bn-contact', '市へのお問い合わせバナー' ],
  [ c_top,    'Cms::Free', 'bn-shisetsumap', '施設マップバナー' ],
  [ c_top,    'Cms::Free', 'kinkyu-list', 'もしものとき' ],
  [ c_site,   'Cms::Free', 'smart-switch', '【スマートフォン】PC切り替えボタン' ],
  [ c_site,   'Cms::BreadCrumb', 'bread-crumbs', 'パンくず' ],
  [ c_site,   'Cms::PageTitle', 'page-title', 'ページタイトル' ],
  [ c_top,    'Cms::Free', 'recently', 'ぞめき市の今' ],
  [ c_site,   'Cms::Free', 'smart-common-header', '【スマートフォン】共通ヘッダー' ],
  [ c_site,   'Cms::Free', 'copyright', 'コピーライト' ],
  [ c_site,   'Cms::Free', 'common-footer', '共通フッター' ],
  [ c_top,    'Cms::Free', 'smart-mayor', '【スマートフォン】市長の部屋' ],
  [ c_site,   'Cms::Free', 'smart-faq', '【スマートフォン】よくある質問' ],
  [ c_top,    'Cms::Free', 'smart-lifeevent', '【スマートフォン】ライフイベント' ],
  [ c_site,   'Cms::Free', 'smart-footer-navi', '【スマートフォン】フッターナビ' ],
  [ c_site,   'Cms::Free', 'footer-navi', 'フッターナビ' ],
  [ c_top,    'Cms::Free', 'smart-bn-lower', '【スマートフォン】左サイドバナー（下部）' ],
  [ c_site,   'Cms::Free', 'smart-common-footer', '【スマートフォン】共通フッター' ],
  [ c_top,    'Cms::Free', 'event-type', 'イベント表示切り替え' ],
  [ c_site,   'Cms::Free', 'back-btn', '戻るボタン' ],
  [ c_site,   'Cms::Free', 'mobile-global-navi', '【携帯】グローバルナビ' ],
  [ c_site,   'Cms::Free', 'sns', 'SNSボタン' ],
  [ c_mayor,  'Cms::Free', 'side-navi', '市長の部屋メニュー' ],
  [ c_site,   'Cms::Free', 'mobile-common-header', '【携帯】共通ヘッダー' ],
  [ c_top,    'Cms::Free', 'about', 'ぞめき市の紹介' ],
  [ c_top,    'Cms::Free', 'population', 'ぞめき市の人口' ],
  [ c_site,   'Cms::Free', 'mobile-back-navi', '【携帯】バックナビ' ],
  [ c_site,   'Cms::Free', 'mobile-common-footer', '【携帯】共通フッター' ],
  [ c_site,   'Cms::Free', 'mobile-copyright', '【携帯】コピーライト' ],
  [ c_site,   'Cms::Free', 'mobile-footer-navi', '【携帯】フッタナビ' ],
  [ c_top,    'Cms::Free', 'mobile-guide', '【携帯】暮らしのガイド' ],
  [ c_top,    'Cms::Free', 'mobile-lifeevent', '【携帯】ライフイベント' ],
  [ c_top,    'Cms::Free', 'mobile-navi', '【携帯】ぞめき市の紹介' ],
  [ c_top,    'Cms::Free', 'mobile-recent-docs-more', '【携帯】新着記事一覧へのリンク' ],
  [ c_site,   'Cms::Free', 'smart-global-navi', '【スマートフォン】グローバルナビ' ],
  [ c_top,    'Cms::Free', 'bn-faq', 'よくある質問FAQバナー' ],
  [ c_gnavi1, 'Cms::Free', 'global-navi', 'グローバルナビ' ],
  [ c_gnavi2, 'Cms::Free', 'global-navi', 'グローバルナビ' ],
  [ c_gnavi3, 'Cms::Free', 'global-navi', 'グローバルナビ' ],
  [ c_gnavi4, 'Cms::Free', 'global-navi', 'グローバルナビ' ],
  [ c_gnavi5, 'Cms::Free', 'global-navi', 'グローバルナビ' ],
  [ c_site,   'Cms::Free', 'search-navi', '検索ナビ' ],
  [ c_gikai,  'Cms::Free', 'side-navi', '議会サイドメニュー' ],
  [ c_top,    'Cms::Free', 'emergency-mode', '大規模災害時モード表示' ],
  [ c_top,    'Cms::Free', 'emergency-info', '大規模災害時メニュー' ],
  [ c_top,    'Cms::Free', 'mobile-emergency-header', '【携帯】災害ヘッダー' ],
  [ c_top,    'Cms::Free', 'mobile-emergency-information', '【携帯】緊急情報' ]
].each do |c|
  create_cms_piece c[0], c[1], c[2], c[3]
end

## ---------------------------------------------------------
## cms/nodes

puts "import cms_nodes..."

def create_cms_content_node(content, layout, model, name, title)
  parent = Cms::Node.find_by(:id => 1, :parent_id => 0)
  Cms::Node.create   site_id: 1,
   concept_id:   content.concept_id,
   content_id:   content.id,
   parent_id:    parent.id,
   state:        'public',
   route_id:     parent.id,
   directory:    (name =~ /\./ ? 0 : 1),
   published_at: Time.now,
   layout_id:    layout.blank? ? nil : layout.id,
   model:        model,
   name:         name,
   title:        title
end

def create_cms_node(concept, parent, layout, model, name, title, body = nil)
  body_text = body.present? ? read_data("nodes/#{body}.txt"): nil
  Cms::Node.create   site_id: 1,
   concept_id:   concept.id,
   parent_id:    parent.id ,
   state:        'public',
   route_id:     parent.id,
   directory:    (name =~ /\./ ? 0 : 1),
   published_at: Time.now,
   layout_id:    layout.blank? ? nil : layout.id,
   model:        model,
   name:         name,
   title:        title,
   body:         body_text
end

n_top   = Cms::Node.find_by(:id => 1, :parent_id => 0)
p_index = Cms::Node.find_by(:id => 2, :name => "index.html")
         p_index.update_columns(concept_id: c_top.id, layout_id: l_top.id)
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'privacy.html', '個人情報の取り扱い',  'pages/privacy/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', '404.html', 'ページが見つかりませんでした',  'pages/404/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'search.html', '検索結果',  'pages/search/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'riyo.html', 'ホームページ利用について',  'pages/riyo/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'web_accessibility.html', 'ウェブアクセシビリティについて',  'pages/web_accessibility/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'link.html', 'リンク集',  'pages/link/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'copyright.html', 'リンク・著作権・免責事項',  'pages/copyright/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Page', 'banner.html', 'バナー広告について',  'pages/banner/body'
         create_cms_node c_site, n_top, l_top, 'Cms::Sitemap', 'sitemap.html', 'サイトマップ',  'pages/sitemap/body'

n_mayor  = create_cms_node c_site, n_top, l_mayor, 'Cms::Directory', 'mayor', 'ぞめき市長の部屋'
         create_cms_node c_site, n_mayor, l_mayor, 'Cms::Page', 'index.html', '市長の部屋',  'mayor/index/body'
         create_cms_node c_site, n_mayor, l_mayor, 'Cms::Page', 'profile.html', 'プロフィール',  'mayor/profile/body'
         create_cms_node c_site, n_mayor, l_mayor, 'Cms::Page', 'gallery.html', '市長フォトギャラリー',  'mayor/gallery/body'
         create_cms_node c_site, n_mayor, l_mayor, 'Cms::Page', 'kosaihi.html', '市長交際費執行状況',  'mayor/kosaihi/body'
         create_cms_node c_site, n_mayor, l_mayor, 'Cms::Page', 'hyomei.html', '所信表明',  'mayor/hyomei/body'
         create_cms_node c_site, n_mayor, l_mayor, 'Cms::Page', 'shuninaisatsu.html', '就任のごあいさつ',  'mayor/shuninaisatsu/body'



n_gikai  = create_cms_node c_site, n_top, l_gikai, 'Cms::Directory', 'gikai', 'ぞめき市議会'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'index.html', 'ぞめき市議会',  'gikai/index/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'kekka.html', '定例会・臨時会の結果',  'gikai/kekka/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'seigan.html', '請願・陳情のご案内',  'gikai/seigan/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'kensaku.html', '会議録検索',  'gikai/kensaku/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'dayori.html', 'ぞめき市議会だより',  'gikai/dayori/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'meibo.html', '議員名簿',  'gikai/meibo/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'kosei.html', '市議会の構成',  'gikai/kosei/body'
         create_cms_node c_site, n_gikai, l_gikai, 'Cms::Page', 'botyo.html', '傍聴のご案内',  'gikai/botyo/body'

## ---------------------------------------------------------
## cms/data_text
puts 'import cms data...'

def create_data_text(concept, name, title)
  Cms::DataText.create site_id: concept.site_id,
    state: 'public',
    concept_id: concept.id,
    name: name,
    title: title,
    body: read_data("data/texts/#{name}/body")
end

create_data_text c_site, 'site-name', 'サイト名'
create_data_text c_site, 'site-name-en', 'サイト名（英語表記）'
create_data_text c_site, 'address', '住所'
create_data_text c_site, 'post-number', '郵便番号'
create_data_text c_site, 'tel', '電話番号'
create_data_text c_site, 'fax ', 'ファックス'
create_data_text c_site, 'search-result', '検索結果'
create_data_text c_site, 'head-col1', 'HEAD：1カラム'
create_data_text c_site, 'head-emergency', 'HEAD：大規模災害時表示'
create_data_text c_site, 'head-smart-top', 'HEAD：スマートフォントップページ'
create_data_text c_site, 'head-col2', 'HEAD：2カラム'
create_data_text c_site, 'analytics', 'Googleアナリティクス'
create_data_text c_site, 'search-box', '検索ボックス'
create_data_text c_site, 'head-smart', 'HEAD：スマートフォン'
create_data_text c_site, 'head-top', 'HEAD：トップページ'

## ---------------------------------------------------------
## cms/data_files

banner_node    = Cms::DataFileNode.create site_id: c_top.site_id,
    concept_id: c_top.id, name: 'banner', title: 'バナー画像'
lifeevent_node = Cms::DataFileNode.create site_id: c_top.site_id,
    concept_id: c_top.id, name: 'lifeevent', title: 'ライフイベント'


def create_data_file(concept, node_id, name, title, mime_type)
  file = Cms::DataFile.create site_id: concept.site_id, state: 'public',
    concept_id: concept.id, node_id: node_id,
    name: name, title: title,
    file: Sys::Lib::File::NoUploadedFile.new("#{Rails.root}/db/seeds/demo/data/files/#{name}", :mime_type => mime_type)
  file.publish
end
create_data_file c_site ,   nil, 'qr.gif', 'QRコード', 'image/gif'
create_data_file c_mayor, nil, 'mayor1.gif', '市長', 'image/gif'
create_data_file c_top, banner_node.id, 'bt-shicho.png', '市長の部屋', 'image/png'
create_data_file c_top, banner_node.id, 'bt-shigikai.png', '市議会', 'image/png'
create_data_file c_top, banner_node.id, 'bt-furusatonozei.png', 'ふるさと納税', 'image/png'
create_data_file c_top, banner_node.id, 'bt-goiken.png', '市へのご意見', 'image/png'
create_data_file c_top, banner_node.id, 'bt-opendata.png', 'オープンデータ', 'image/png'
create_data_file c_top, banner_node.id, 'bt-shinseisho.png', '申請書ダウンロード', 'image/png'
create_data_file c_top, banner_node.id, 'bn-contact.gif', '市へのお問い合わせ', 'image/gif'
create_data_file c_top, banner_node.id, 'bn-shisetsumap.gif', '施設マップ', 'image/gif'
create_data_file c_top, banner_node.id, 'bn-faq.gif', 'よくある質問FAQ', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-byokikega.gif', '病気・けが', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-hikkoshisumai.gif', '引っ越し・住まい', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-kekkonrikon.gif', '結婚・離婚', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-koreikaigo.gif', '高齢者・介護', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-kosodatekyoiku.gif', '子育て・就学', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-ninshinshussan.gif', '妊娠・出産', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-seijinshushoku.gif', '成人・就職', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-shibosozoku.gif', '死亡・相続', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-shitsugyotaishoku.gif', '失業・退職', 'image/gif'
create_data_file c_top, lifeevent_node.id, 'bt-shogaisha.gif', '障がい者', 'image/gif'


## ---------------------------------------------------------
## each modules

GpCategory::Category.skip_callback(:save, :after, :enqueue_publisher_callback)
load_demo "gp_category"
load_demo "navi"
load_demo "flow"
load_demo "gp_calendar"
load_demo "gp_template"
load_demo "tag"
load_demo "sns"
load_demo "map"
load_demo "organization"
load_demo "gp_article"
load_demo "ad_banner"
load_demo "survey"
load_demo "rank"
load_demo "feed"
load_demo "biz_calendar"
GpCategory::Category.set_callback(:save, :after, :enqueue_publisher_callback)

