# encoding: utf-8
class Cms::Admin::LayoutsController < Cms::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base
  include Sys::Controller::Scaffold::Publication
  
  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:designer)
  end
  
  def index
    item = Cms::Layout.new.readable
    item.page  params[:page], params[:limit]
    item.order params[:sort], 'name, id'
    @items = item.find(:all)
    _index @items
  end
  
  def show
    @item = Cms::Layout.new.readable.find(params[:id])
    return error_auth unless @item.readable?
    
    _show @item
  end

  def new
    @item = Cms::Layout.new({
      :concept_id  => Core.concept(:id),
      :state       => 'public',
      :body        => '[[content]]'
    })
  end
  
  def create
    @item = Cms::Layout.new(layout_params)
    @item.site_id = Core.site.id
    @item.state   = 'public'
    _create @item
  end
  
  def update
    @item = Cms::Layout.new.find(params[:id])
    @item.attributes = layout_params
    _update(@item, :location => url_for(:action => :edit)) do
      Core.set_concept(session, @item.concept_id)
    end
  end
  
  def destroy
    @item = Cms::Layout.new.find(params[:id])
    _destroy @item
  end
  
  def duplicate(item)
    if dupe_item = item.duplicate
      flash[:notice] = '複製処理が完了しました。'
      respond_to do |format|
        format.html { redirect_to url_for(:action => :index) }
        format.xml  { head :ok }
      end
    else
      flash[:notice] = "複製処理に失敗しました。"
      respond_to do |format|
        format.html { redirect_to url_for(:action => :show) }
        format.xml  { render :xml => item.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def layout_params
    params.require(:item).permit(:body, :concept_id, :head, :in_creator, :mobile_body, :mobile_head, :mobile_stylesheet, :name, :smart_phone_body, :smart_phone_head, :smart_phone_stylesheet, :stylesheet, :title)
  end
end
