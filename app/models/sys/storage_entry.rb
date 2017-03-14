class Sys::StorageEntry
  include ActiveModel::Model
  include ActiveModel::Dirty
  include Cms::Model::Auth::Site::Designer

  attr_accessor :base_dir, :name, :entry_type
  attr_accessor :body, :site_id
  attr_accessor :allow_overwrite

  validates :name, presence: true
  with_options if: -> { entry_type == :file && name.present? } do
    validates :name, format: { with: /\A[0-9A-Za-z@\.\-\_]+\z/, message: ->(object, data) { 'ファイル名は半角英数字で入力してください。' } }
    validate :validate_file_existence, unless: -> { allow_overwrite }
    validate :validate_mime_type
    validate :validate_file_size
  end

  with_options if: -> { entry_type == :directory && name.present? } do
    validates :name, format: { with: /\A[0-9A-Za-z@\.\-\_]+\z/, message: ->(object, data) { 'ディレクトリ名は半角英数字で入力してください。' } }
    validates :name, format: { with: /\A[^_]/, message: '先頭に「_」を含むディレクトリは作成できません。' }
    validate :validate_directory_existence, unless: -> { allow_overwrite }
  end

  def path
    ::File.join(base_dir, name)
  end

  def mtime
    ::Storage.mtime(path)
  end

  def mime_type
    ::Storage.mime_type(path)
  end

  def size
    ::Storage.size(path)
  end

  def kb_size
    ::Storage.kb_size(path)
  end

  def text_file?
    return false if entry_type != :file
    mime_type.blank? || mime_type =~ /(text|javascript)/i
  end

  def exists?
    ::Storage.exists?(path)
  end

  def read_body
    self.body = ::Storage.binread(path)
    self.body = NKF.nkf('-w', self.body) if text_file?
    self.body
  rescue => e
    '読み込みに失敗しました。'
  end

  def site
    Cms::Site.find_by(id: site_id)
  end

  def site_root_path?
    path == Rails.root.join("sites/#{format('%04d', site_id)}").to_s
  end

  def path_from_site_root
    path.sub(Rails.root.join("sites/#{format('%04d', site_id)}").to_s, '').sub(%r|^/|, '')
  end

  def navi_from_site_root
    dirs = path_from_site_root.split(/\//)
    dirs.drop(1).map.with_index do |n, idx|
      [n, dirs.slice(0, idx + 2).join("/")]
    end
  end

  def readable?
    public_path = Rails.root.join("sites/#{format('%04d', site_id)}/public")
    super && (Core.user.root? || path =~ %r|^#{public_path}|)
  end

  def entries
    items = []
    ::Storage.entries(path).each do |entry_name|
      entry_path = ::File.join(path, entry_name)
      items << self.class.from_path(entry_path)
    end
    items.sort_by { |item| [item.entry_type, item.name] }
  end

  def save(options = {})
    options[:validate] = true unless options.key?(:validate)
    return false if options[:validate] && invalid?

    case entry_type
    when :directory
      ::Storage.mkdir(path) unless ::Storage.exists?(path)
    when :file
      ::Storage.binwrite(path, body)
    end
    return true
  rescue => e
    errors.add(:base, e)
    return false
  end

  def destroy
    ::Storage.rm_rf(path)
    return true
  rescue => e  
    errors.add(:base, e)
    return false
  end

  def upload_files(files, options = {})
    results = []
    zip_results = []
    files.each do |file|
      if options[:unzip] && file.original_filename =~ /^.+\.zip$/
        res = []
        begin
          res += unzip(file, options)
        rescue => e
          res << { name: file.original_filename, msg: "ZIPファイルの解凍に失敗しました。(#{e})", status: 'NG' }
        end
        zip_results << { name: file.original_filename, results: res }
      else
        item = self.class.new(base_dir: path, name: file.original_filename, body: file.read, entry_type: :file, site_id: site_id)
        item.allow_overwrite = options[:overwrite]
        if item.save
          results << { name: item.name, msg: 'アップロード完了', status: 'OK' }
        else
          item.errors.full_messages.each do |msg|
            results << { name: item.name, msg: msg, status: 'NG' }
          end
        end
      end
    end
    return results, zip_results
  end

  def unzip(file, options = {})
    res = []
    require 'zip'
    Zip::InputStream.open(file.tempfile, 0) do |input|
      while (entry = input.get_next_entry)
        e_name = entry.name.to_utf8
        new_path = ::File.join(path, e_name)
        new_base_dir = ::File.dirname(new_path)
        new_name  = ::File.basename(new_path)

        if entry.name_is_directory?
          item = self.class.new(base_dir: new_base_dir, name: new_name, entry_type: :directory, site_id: site_id)
          item.allow_overwrite = options[:overwrite]
          if item.save
            res << { name: e_name, msg: 'アップロード完了', status: 'OK' }
          else
            item.errors.full_messages.each do |msg|
              res << { name: e_name, msg: msg, status: 'NG' }
            end
          end
        else
          entry.get_input_stream do |stream|
            item = self.class.new(base_dir: new_base_dir, name: new_name, body: stream.read, entry_type: :file, site_id: site_id)
            item.allow_overwrite = options[:overwrite]
            if item.save
              res << { name: e_name, msg: 'アップロード完了', status: 'OK' }
            else
              item.errors.full_messages.each do |msg|
                res << { name: e_name, msg: msg, status: 'NG' }
              end
            end
          end
        end
      end
    end
    res
  end

  private

  def validate_directory_existence
    if ::Storage.exists?(path)
      errors.add(:base, 'ディレクトリは既に存在します。')
    end
  end

  def validate_file_existence
    if ::Storage.exists?(path)
      errors.add(:base, 'ファイルは既に存在します。')
    end
  end

  def load_allowed_attachment_types
    return nil unless site
    types = site.setting_site_allowed_attachment_type.to_s.split(/ *, */)
    types.map { |t| t = ".#{t.gsub(/ /, '').downcase}" }.select(&:present?)
  end

  def validate_mime_type
    types = load_allowed_attachment_types
    if types.present? && !types.include?(::File.extname(name).downcase)
      errors.add(:base, "許可されていないファイルです。（#{types.join(', ')}）")
    end
  end

  def load_upload_max_size
    return nil unless site
    ext = ::File.extname(name).downcase
    site.get_upload_max_size(ext) || site.setting_site_file_upload_max_size.to_i
  end

  def validate_file_size
    max_size = load_upload_max_size
    if max_size && body && body.size > max_size.to_i * (1024**2)
      errors.add(:base, "容量制限を超えています。＜#{max_size}MB＞")
    end
  end

  class << self
    def from_path(path)
      item = self.new(base_dir: ::File.dirname(path), name: ::File.basename(path))
      item.entry_type =
        if ::Storage.directory?(item.path)
          :directory
        elsif ::Storage.file?(item.path)
          :file
        end
      item.site_id =
        if item.base_dir == "#{Rails.root}/sites"
          item.name.to_i
        else
          item.base_dir.scan(%r|#{Rails.root}/sites/(\d+)|).flatten.try!(:first).try!(:to_i)
        end
      item
    end
  end
end
