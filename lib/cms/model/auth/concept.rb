require 'active_support/concern'

module Cms::Model::Auth::Concept
  extend ActiveSupport::Concern

  included do
    scope :readable, -> {
      rel = Core.site ? where(site_id: Core.site.id)
                      : where(site_id: nil)
      if Core.concept
        if Core.user.has_priv?(:read, item: Core.concept)
          rel.where(concept_id: Core.concept.id)
        else
          rel.none
        end
      else
        rel.where(concept_id: nil)
      end
    }
  end

  def readable
    if Core.site
      self.and :site_id, Core.site.id
    else
      self.and :site_id, 'IS', nil
    end
    
    if Core.concept
      self.and(0, 1) unless Core.user.has_priv?(:read, :item => Core.concept)
      self.and :concept_id, Core.concept.id
    else
      self.and :concept_id, 'IS', nil
    end
    return self
  end
  
  def creatable?
    return false unless Core.user.has_auth?(:designer)
    return Core.user.has_priv?(:create, :item => concept(true))
  end
  
  def readable?
    return false unless Core.user.has_auth?(:designer)
    return Core.user.has_priv?(:read, :item => concept(true))
  end
  
  def editable?
    return false unless Core.user.has_auth?(:designer)
    return Core.user.has_priv?(:update, :item => concept(true))
  end

  def deletable?
    return false unless Core.user.has_auth?(:designer)
    return Core.user.has_priv?(:delete, :item => concept(true))
  end
end
