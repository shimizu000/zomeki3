class Sys::Admin::StorageFilesController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  before_action :force_html_format
  before_action :filter_by_do_param

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)

    site_path = Rails.root.join("sites/#{format('%04d', Core.site.id)}").to_s
    @root_dirs =
      if Core.user.root?
        Dir.glob("#{site_path}/*").map { |path| [dir = File.basename(path), dir] }
      else
        [['public', 'public']]
      end

    params[:path] = 'public' if params[:path].blank?
    @root_dir = params[:path].split('/').first

    @path = ::File.join(site_path, params[:path].to_s)
    return http_error(404) unless File.exist?(@path)

    @parent = Sys::StorageEntry.from_path(::File.dirname(@path))
    return http_error(404) unless @parent.exists?

    @item = Sys::StorageEntry.from_path(@path)
    return http_error(404) unless @item.exists?
    return error_auth unless @item.readable?
  end

  def index
    @current = @item
    @items = @current.entries
    _index @items
  end

  def show
    if @item.entry_type == :file
      render :show_file, formats: [:html]
    else
      render :show_dir
    end
  end

  def download
    send_data(@item.read_body, content_type: @item.mime_type, disposition: :attachment)
  end

  def create
    @current = @item

    if params[:create_directory]
      @item = Sys::StorageEntry.new(base_dir: @current.path, name: params[:item][:new_directory], entry_type: :directory, site_id: Core.site.id)
      if @item.save
        flash.now[:notice] = 'ディレクトリを作成しました。'
      else
        flash.now[:notice] = 'ディレクトリの作成に失敗しました。'
      end
    elsif params[:create_file]
      @item = Sys::StorageEntry.new(base_dir: @current.path, name: params[:item][:new_file], entry_type: :file, site_id: Core.site.id)
      if @item.save
        flash[:notice] = 'ファイルを作成しました。'
        return redirect_to(do: :show, path: @item.path_from_site_root)
      else
        flash.now[:notice] = 'ファイルの作成に失敗しました。'
      end
    elsif params[:upload_file]
      @item = @current.dup
      @results, @unzip_results = @item.upload_files(params[:item][:new_upload],
                                                    overwrite: params.dig(:item, :upload_overwrite).presence,
                                                    unzip: !params.dig(:item, :open_zip).presence)
    end

    @items = @current.entries
    render :index
  end

  def edit
    if @item.entry_type == :file
      render :edit_file, formats: [:html]
    else
      http_error(404)
    end
  end

  def update
    if @item.entry_type == :file
      @item.body = params[:body]
      if @item.save(validate: false)
        flash[:notice] = "更新処理が完了しました。"
        redirect_to(path: @parent.path_from_site_root)
      else
        flash[:notice] = "更新処理に失敗しました。"
        render :edit_file, formats: [:html]
      end
    else
      http_error(404)
    end
  end

  def destroy
    if @item.destroy
      flash[:notice] = "削除処理が完了しました。"
    else
      flash[:notice] = "削除処理に失敗しました。"
    end

    redirect_to(path: @parent.path_from_site_root)
  end

  private

  def force_html_format
    request.format = :html
  end

  def filter_by_do_param
    @do = params[:do].presence || 'index'
    case @do
    when 'show'
      show
    when 'edit'
      edit
    when 'update'
      update
    when 'destroy'
      destroy
    when 'download'
      download
    end
  end
end
