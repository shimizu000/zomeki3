class GpArticle::Public::Piece::DocsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = GpArticle::Piece::Doc.find_by(id: Page.current_piece.id)
    render plain: '' unless @piece

    @item = Page.current_item
  end

  def index
    @docs = @piece.content.public_docs_for_list.limit(@piece.docs_number)
                  .order(@piece.docs_order_as_sql)
                  .preload_assocs(:public_node_ancestors_assocs, :public_index_assocs)

    render :index_mobile if Page.mobile?
  end
end
