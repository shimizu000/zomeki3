class Organization::Public::Piece::ContactInformationsController < Sys::Controller::Public::Base
  def pre_dispatch
    @piece = Organization::Piece::ContactInformation.where(id: Page.current_piece.id).first
    return render plain: '' unless @piece

    @item = Page.current_item
  end

  def index
    render plain: '' unless @item.kind_of?(Organization::Group)
  end
end
