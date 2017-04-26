class Cms::PieceLinkItem < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Base::Page
  include Cms::Model::Auth::Concept

  include StateText

  belongs_to :piece,  :foreign_key => :piece_id, :class_name => 'Cms::Piece'

  after_save     Cms::Publisher::PieceRelatedCallbacks.new, if: :changed?
  before_destroy Cms::Publisher::PieceRelatedCallbacks.new

  validates :state, :name, :uri, presence: true
  
  def concept(flag = nil)
    piece.concept(flag)
  end
  
  def creatable?
    editable?
  end
  
  def deletable?
    editable?
  end
  
  def targets
    [["指定なし", ""],["別ウィンドウ","_blank"]]
  end
  
  def target
    read_attribute(:target).blank? ? nil : read_attribute(:target)
  end
  
  def target_name
    targets.each {|c| return c[0] if c[1].to_s == target.to_s}
    nil
  end
end
