class Rank::BaseScript < Cms::Script::Publication
  def publish
    uri = @node.public_uri.to_s
    path = @node.public_path.to_s
    smart_phone_path = @node.public_smart_phone_path.to_s
    publish_more(@node, uri: uri, path: path, smart_phone_path: smart_phone_path, dependent: uri)
  end
end
