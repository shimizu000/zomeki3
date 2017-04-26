require 'will_paginate/array'

class GpCategory::Public::Node::CategoryTypesController < GpCategory::Public::Node::BaseController
  def index
    if (template = @content.index_template)
      return http_error(404) if params[:page]

      vc = view_context
      rendered = template.body.gsub(/\[\[module\/([\w-]+)\]\]/) do |matched|
          tm = @content.template_modules.find_by(name: $1)
          next unless tm

          case tm.module_type
          when 'categories_1', 'categories_2', 'categories_3'
            if vc.respond_to?(tm.module_type)
              @content.public_category_types.inject(''){|tags, category_type|
                tags << vc.content_tag(:section, class: category_type.name) do
                    html = vc.content_tag(:h2, vc.link_to(category_type.title, category_type.public_uri))
                    html << vc.send(tm.module_type, template_module: tm,
                                    categories: category_type.public_root_categories)
                  end
              }
            end
            when 'categories_summary_1', 'categories_summary_2', 'categories_summary_3'
              if vc.respond_to?(tm.module_type)
              @content.public_category_types.inject(''){|tags, category_type|
                tags << vc.content_tag(:section, class: category_type.name) do
                    title_tag = vc.content_tag(:h2, category_type.title)
                    title_tag << vc.content_tag(:span, category_type.description, class: 'category_summary') if category_type.description.present?
                    html = vc.link_to(title_tag, category_type.public_uri)
                    html << vc.send(tm.module_type, template_module: tm,
                                    categories: category_type.public_root_categories)
                  end
              }
              end
          when 'docs_1'
            if vc.respond_to?(tm.module_type)
              category_ids = @content.public_category_types.inject([]){|ids, category_type|
                ids.concat(category_type.public_root_categories.inject([]){|is, category|
                  is.concat(category.public_descendants.map(&:id))
                })
              }

              docs = find_public_docs_with_category_id(category_ids)
              docs = docs.where(content_id: tm.gp_article_content_ids) if tm.gp_article_content_ids.present?

              all_docs = docs.order(display_published_at: :desc, published_at: :desc)
              docs = all_docs.limit(tm.num_docs)
              vc.send(tm.module_type, template_module: tm,
                      ct_or_c: nil, docs: docs, all_docs: all_docs)
            end
          else
            ''
          end
        end

      render html: vc.content_tag(:div, rendered.html_safe, class: 'contentGpCategory contentGpCategoryCategoryTypes').html_safe
    else
      @category_types = @content.public_category_types.paginate(page: params[:page], per_page: 20)
        .preload_assocs(:public_node_ancestors_assocs)
      return http_error(404) if @category_types.current_page > @category_types.total_pages

      render :index_mobile if Page.mobile?
    end
  end

  def show
    @category_type = @content.public_category_types.find_by(name: params[:name])
    return http_error(404) unless @category_type

    if params[:format].in?(['rss', 'atom'])
      case @content.category_type_style
      when 'all_docs'
        category_ids = @category_type.public_categories.pluck(:id)
        @docs = find_public_docs_with_category_id(category_ids).order(display_published_at: :desc, published_at: :desc)
        @docs = @docs.display_published_after(@content.feed_docs_period.to_i.days.ago) if @content.feed_docs_period.present?
        @docs = @docs.paginate(page: params[:page], per_page: @content.feed_docs_number)
        return render_feed(@docs)
      else
        return http_error(404)
      end
    end

    Page.current_item = @category_type
    Page.title = @category_type.title

    per_page = (@more ? 30 : @content.category_type_docs_number)

    if (template = @category_type.template)
      if @more
        @template_module = template.containing_modules.detect { |m| m.name == @more_options.first }

        category_ids = @category_type.public_root_categories.inject([]){|ids, category|
          ids.concat(category.public_descendants.map(&:id))
        }
        @docs = find_public_docs_with_category_id(category_ids)

        if @template_module && @template_module.gp_article_content_ids.present?
          @docs.where!(content_id: @template_module.gp_article_content_ids)
        end

        if (filter = @more_options[1])
          prefix, code_or_name = filter.split('_', 2)

          case prefix
          when 'c'
            return http_error(404) unless @category_type.internal_category_type

            internal_category = @category_type.internal_category_type.public_root_categories.find_by(name: code_or_name)
            return http_error(404) unless internal_category

            categorizations = GpCategory::Categorization.where(categorizable_type: 'GpArticle::Doc', categorized_as: 'GpArticle::Doc',
                                                               categorizable_id: @docs.pluck(:id),
                                                               category_id: internal_category.public_descendants.map(&:id))
            @docs = GpArticle::Doc.where(id: categorizations.pluck(:categorizable_id))
          when 'g'
            group = Sys::Group.in_site(Page.site).where(code: code_or_name).first
            return http_error(404) unless group
            @docs = @docs.joins(creator: :group).where(Sys::Group.arel_table[:id].eq(group.id))
          end
        end

        @docs = @docs.order(display_published_at: :desc, published_at: :desc).paginate(page: params[:page], per_page: per_page)
        return http_error(404) if @docs.current_page > @docs.total_pages
        render :more
      else
        return http_error(404) if params[:page]

        vc = view_context
        rendered = template.body.gsub(/\[\[module\/([\w-]+)\]\]/) do |matched|
            tm = @content.template_modules.find_by(name: $1)
            next unless tm

            case tm.module_type
            when 'categories_1', 'categories_2', 'categories_3'
              if vc.respond_to?(tm.module_type)
                @category_type.public_root_categories.inject(''){|tags, category|
                  tags << vc.content_tag(:section, class: category.name) do
                      html = vc.content_tag(:h2, vc.link_to(category.title, category.public_uri))
                      html << vc.send(tm.module_type, template_module: tm,
                                      categories: category.public_children)
                    end
                }
              end
            when 'categories_summary_1', 'categories_summary_2', 'categories_summary_3'
              if vc.respond_to?(tm.module_type)
                @category_type.public_root_categories.inject(''){|tags, category|
                  tags << vc.content_tag(:section, class: category.name) do
                      title_tag = vc.content_tag(:h2, category.title)
                      title_tag << vc.content_tag(:span, category.description, class: 'category_summary') if category.description.present?
                      html = vc.link_to(title_tag, category.public_uri)
                      html << vc.send(tm.module_type, template_module: tm,
                                      categories: category.public_children)
                    end
                }
              end
            when 'docs_1'
              if vc.respond_to?(tm.module_type)
                category_ids = @category_type.public_root_categories.inject([]){|ids, category|
                  ids.concat(category.public_descendants.map(&:id))
                }

                docs = find_public_docs_with_category_id(category_ids)
                docs = docs.where(content_id: tm.gp_article_content_ids) if tm.gp_article_content_ids.present?

                all_docs = docs.order(display_published_at: :desc, published_at: :desc)
                docs = all_docs.limit(tm.num_docs)
                vc.send(tm.module_type, template_module: tm,
                        ct_or_c: @category_type, docs: docs, all_docs: all_docs)
              end
            when 'docs_3'
              if vc.respond_to?(tm.module_type) && @category_type.internal_category_type
                category_ids = @category_type.public_root_categories.inject([]){|ids, category|
                  ids.concat(category.public_descendants.map(&:id))
                }

                docs = find_public_docs_with_category_id(category_ids)
                docs = docs.where(content_id: tm.gp_article_content_ids) if tm.gp_article_content_ids.present?

                categorizations = GpCategory::Categorization.where(categorizable_type: 'GpArticle::Doc', categorizable_id: docs.pluck(:id), categorized_as: 'GpArticle::Doc')
                vc.send(tm.module_type, template_module: tm,
                        ct_or_c: @category_type,
                        categories: @category_type.internal_category_type.public_root_categories, categorizations: categorizations)
              end
            when 'docs_5'
              if vc.respond_to?(tm.module_type)
                category_ids = @category_type.public_root_categories.inject([]){|ids, category|
                  ids.concat(category.public_descendants.map(&:id))
                }

                docs = find_public_docs_with_category_id(category_ids)
                docs = docs.where(content_id: tm.gp_article_content_ids) if tm.gp_article_content_ids.present?

                docs = docs.joins(:creator => :group)
                groups = Sys::Group.where(id: docs.select(Sys::Group.arel_table[:id]).distinct)
                vc.send(tm.module_type, template_module: tm,
                        ct_or_c: @category_type,
                        groups: groups, docs: docs)
              end
            when 'docs_7', 'docs_8'
              if vc.respond_to?(tm.module_type)
                category_ids = @category_type.public_root_categories.inject([]){|ids, category|
                  ids.concat(category.public_descendants.map(&:id))
                }

                docs = find_public_docs_with_category_id(category_ids)
                docs = docs.where(content_id: tm.gp_article_content_ids) if tm.gp_article_content_ids.present?

                categorizations = GpCategory::Categorization.where(categorizable_type: 'GpArticle::Doc', categorizable_id: docs.pluck(:id), categorized_as: 'GpArticle::Doc')
                vc.send(tm.module_type, template_module: tm,
                        categories: @category_type.public_root_categories, categorizations: categorizations)
              end
            else
              ''
            end
          end

        render html: vc.content_tag(:div, rendered.html_safe, class: 'contentGpCategory contentGpCategoryCategoryType').html_safe
      end
    else
      case @content.category_type_style
      when 'all_docs'
        category_ids = @category_type.public_categories.pluck(:id)
        @docs = find_public_docs_with_category_id(category_ids).order(display_published_at: :desc, published_at: :desc)
          .paginate(page: params[:page], per_page: @content.category_type_docs_number)
          .preload_assocs(:public_node_ancestors_assocs, :public_index_assocs).to_a
        return http_error(404) if @docs.current_page > @docs.total_pages
      else
        return http_error(404) if params[:page].to_i > 1
      end

      if Page.mobile?
        render :show_mobile
      else
        render @content.category_type_style if @content.category_type_style.present?
      end
    end
  end
end
