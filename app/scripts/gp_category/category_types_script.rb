class GpCategory::CategoryTypesScript < Cms::Script::Publication
  def publish
    uri  = @node.public_uri
    path = @node.public_path

    publish_more(@node, uri: uri, path: path, dependent: :more)

    category_types = @node.content.public_category_types
    category_types.where!(id: params[:target_category_type_id]) if params[:target_category_type_id].present?
    category_types.each do |category_type|
      uri = "#{@node.public_uri}#{category_type.name}/"
      path = "#{@node.public_path}#{category_type.name}/"
      smart_phone_path = "#{@node.public_smart_phone_path}#{category_type.name}/"

      publish_page(category_type, uri: "#{uri}index.rss", path: "#{path}index.rss", dependent: "#{category_type.name}/rss")
      publish_page(category_type, uri: "#{uri}index.atom", path: "#{path}index.atom", dependent: "#{category_type.name}/atom")
      publish_more(category_type, uri: uri, path: path, smart_phone_path: smart_phone_path, dependent: "#{category_type.name}/more")
      publish_more(category_type, uri: uri, path: path, smart_phone_path: smart_phone_path, file: 'more', dependent: "#{category_type.name}/more_docs")

      categories = category_type.public_categories.reorder(:level_no, :sort_no)
      categories.where!(id: params[:target_category_id]) if params[:target_category_id].present?
      categories.each do |category|
        publish_category(category)
      end
    end
  end

  private

  def category_feed_pieces(item)
    layout = item.layout || @node.layout
    return nil unless layout

    feed_piece_ids = layout.pieces.select{|piece| piece.model == 'GpCategory::Feed'}.map(&:id)
    GpCategory::Piece::Feed.where(:id => feed_piece_ids).all
  end

  def publish_category(cat)
    publish_category_for_template_modules(cat)

    cat_path = "#{cat.category_type.name}/#{cat.path_from_root_category}/"
    uri = "#{@node.public_uri}#{cat_path}"
    path = "#{@node.public_path}#{cat_path}"
    smart_phone_path = "#{@node.public_smart_phone_path}#{cat_path}"

    publish_page(cat.category_type, uri: "#{uri}index.rss", path: "#{path}index.rss", dependent: "#{cat_path}rss")
    publish_page(cat.category_type, uri: "#{uri}index.atom", path: "#{path}index.atom", dependent: "#{cat_path}atom")

    if @node.content.category_style == 'categories_with_docs'
      publish_page(cat.category_type, uri: uri, path: path, smart_phone_path: smart_phone_path, dependent: "#{cat_path}more")
    else
      publish_more(cat.category_type, uri: uri, path: path, smart_phone_path: smart_phone_path, dependent: "#{cat_path}more")
    end

    publish_more(cat.category_type, uri: uri, path: path, smart_phone_path: smart_phone_path, file: 'more', dependent: "#{cat_path}more_docs")

    if feed_pieces = category_feed_pieces(cat)
      feed_pieces.each do |piece|
        rss = piece.public_feed_uri('rss')
        atom = piece.public_feed_uri('atom')
        publish_page(cat.category_type, uri: "#{uri}#{rss}", path: "#{path}#{rss}", dependent: "#{cat_path}#{rss}")
        publish_page(cat.category_type, uri: "#{uri}#{atom}", path: "#{path}#{atom}", dependent: "#{cat_path}#{atom}")
      end
    end

    info_log %Q!OK: Published to "#{path}"!
  end

  def publish_category_for_template_modules(cat)
    t = cat.inherited_template
    return unless t

    tms = t.containing_modules
    tms.each do |tm|
      case tm.module_type
      when 'docs_1', 'docs_2'
        publish_link cat, ApplicationController.helpers.category_module_more_link(template_module: tm, ct_or_c: cat)
      when 'docs_3', 'docs_4'
        cat.category_type.internal_category_type.public_root_categories.each do |c|
          publish_link cat, ApplicationController.helpers.category_module_more_link(template_module: tm, ct_or_c: cat, category_name: c.name)
        end
      when 'docs_5', 'docs_6'
        docs = case tm.module_type
               when 'docs_5'
                 find_public_docs_with_category_id(cat.public_descendants.map(&:id))
               when 'docs_6'
                 find_public_docs_with_category_id(cat.id)
               end
        docs = docs.where(tm.module_type_feature, true) if docs.columns.any?{|c| c.name == tm.module_type_feature }

        docs = docs.joins(:creator => :group)
        groups = Sys::Group.where(id: docs.select(Sys::Group.arel_table[:id]).distinct)

        groups.each do |group|
          publish_link cat, ApplicationController.helpers.category_module_more_link(template_module: tm, ct_or_c: cat, group_code: group.code)
        end
      end
    end
  end

  def publish_link(cat, link)
    public_path = cat.content.site.public_path

    uri = "#{File.dirname(link)}/"
    path = "#{public_path}#{uri}"
    smart_phone_path = "#{public_path}/_smartphone#{uri}"
    file = File.basename(link, '.html')

    publish_more(cat.category_type, uri: uri, path: path, smart_phone_path: smart_phone_path,
                                    dependent: "#{uri}#{file}", file: file)
  end

  def find_public_docs_with_category_id(category_id)
    GpArticle::Doc.categorized_into(category_id).except(:order).mobile(::Page.mobile?).public_state
  end
end
