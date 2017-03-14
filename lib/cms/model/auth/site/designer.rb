module Cms::Model::Auth::Site::Designer
  def creatable?
    readable?
  end
  
  def readable?
    return false unless Core.user.has_auth?(:designer)
    (respond_to?(:site) && site && Core.user.sites.include?(site)) || 
    (respond_to?(:sites) && (sites & Core.user.sites).present?)
  end
  
  def editable?
    readable?
  end

  def deletable?
    readable?
  end
end
