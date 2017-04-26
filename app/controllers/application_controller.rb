class ApplicationController < ActionController::Base
  include Cms::Controller::Public
  helper  FormHelper
  helper  LinkHelper
  protect_from_forgery with: :exception
  before_action :initialize_application
#  rescue_from Exception, :with => :rescue_exception

  def initialize_application
    if Core.publish
      Page.mobile = false
      Page.smart_phone = false
    else
      Page.mobile = true if request.mobile?
      Page.smart_phone = true if request.smart_phone?
      request_as_mobile if Page.mobile? && !request.mobile?
      request_as_smart_phone if Page.smart_phone? && !request.smart_phone?
    end
    return false if Core.dispatched?
    return Core.dispatched
  end

  def query(params = nil)
    Util::Http::QueryString.get_query(params)
  end

  def send_mail(fr_addr, to_addr, subject, body)
    return false if fr_addr.blank? || to_addr.blank?
    CommonMailer.plain(from: fr_addr, to: to_addr, subject: subject, body: body).deliver_now
  end

  def send_download
    #
  end

  def send_data(data, options = {})
    options = set_default_file_options(options)
    super
  end

  def send_file(path, options = {})
    options = set_default_file_options(options)
    super
  end

  private

  def set_default_file_options(options)
    if options.include?(:filename)
      options[:filename] = URI::escape(options[:filename]) if request.user_agent =~ /(MSIE|Trident)/
      options[:type] ||= Rack::Mime.mime_type(File.extname(options[:filename]))
      options[:disposition] ||= detect_disposition_from_mime(options[:type])
    end
    options
  end

  def detect_disposition_from_mime(mime_type)
    if request.user_agent =~ /Android/
      'attachment'
    elsif mime_type.to_s =~ %r!\Aimage/|\Aapplication/pdf\z!
      'inline'
    else
      'attachment'
    end
  end

  def rescue_action(error)
    case error
    when ActionController::InvalidAuthenticityToken
      http_error(422, "Invalid Authenticity Token")
    else
      super
    end
  end

  ## Production && local
  def rescue_action_in_public(exception)
    http_error(500, nil)
  end

  def http_error(status, message = nil)
    self.response_body = nil
    Page.error = status

    if status == 404
      message ||= "ページが見つかりません。"
    end

    name    = Rack::Utils::HTTP_STATUS_CODES[status]
    name    = " #{name}" if name
    message = " ( #{message} )" if message
    message = "#{status}#{name}#{message}"

    mode_regexp = Regexp.new("^(#{ZomekiCMS::ADMIN_URL_PREFIX.sub(/^_/, '')}|script)$")
    if Core.mode =~ mode_regexp && status != 404
      error_log("#{status} #{request.env['REQUEST_URI']}") if status != 404
      return render status: status, html: "<p>#{message}</p>".html_safe, layout: "admin/cms/error"
#      return respond_to do |format|
#        format.html { render :status => status, :text => "<p>#{message}</p>", :layout => "admin/cms/error" }
#        format.xml  { render :status => status, :xml => "<errors><error>#{message}</error></errors>" }
#      end
    end

    ## Render
    html = nil
    if Page.mobile
      file_status = "#{status}_mobile.html"
      file_500 = "500_mobile.html"
    else
      file_status = "#{status}.html"
      file_500 = "500.html"
    end
    if Page.site && FileTest.exist?("#{Page.site.public_path}/#{file_status}")
      html = ::File.new("#{Page.site.public_path}/#{file_status}").read
    elsif Core.site && FileTest.exist?("#{Core.site.public_path}/#{file_status}")
      html = ::File.new("#{Core.site.public_path}/#{file_status}").read
    elsif FileTest.exist?("#{Rails.public_path}/#{file_status}")
      html = ::File.new("#{Rails.public_path}/#{file_status}").read
    elsif FileTest.exist?("#{Rails.public_path}/#{file_500}")
      html = ::File.new("#{Rails.public_path}/#{file_500}").read
    else
      html = "<html>\n<head></head>\n<body>\n<p>#{message}</p>\n</body>\n</html>\n"
    end

    if Core.mode == 'ssl'
      replacer = Cms::Lib::SslLinkReplacer.new
      html = replacer.run(html, site: Page.site, current_path: Page.current_node.public_uri)
    end

    render :status => status, :inline => html
#    return respond_to do |format|
#      format.html { render :status => status, :inline => html }
#      format.xml  { render :status => status, :xml => "<errors><error>#{message}</error></errors>" }
#    end
  end

#  def rescue_exception(exception)
#    log  = exception.to_s
#    log += "\n" + exception.backtrace.join("\n") if Rails.env.to_s == 'production'
#    error_log(log)
#
#    if Core.mode =~ /^(admin|script)$/
#      html  = %Q(<div style="padding: 0px 20px 10px; color: #e00; font-weight: bold; line-height: 1.8;">)
#      html += %Q(エラーが発生しました。<br />#{exception} &lt;#{exception.class}&gt;)
#      html += %Q(</div>)
#      if Rails.env.to_s != 'production'
#        html += %Q(<div style="padding: 15px 20px; border-top: 1px solid #ccc; color: #800; line-height: 1.4;">)
#        html += exception.backtrace.join("<br />")
#        html += %Q(</div>)
#      end
#      render :inline => html, :layout => "admin/cms/error", :status => 500
#    else
#      http_error 500
#    end
#  end

  def request_as_mobile
    user_agent = 'DoCoMo/2.0 ISIM0808(c500;TB;W24H16)'
    request.env['rack.jpmobile'] = Jpmobile::Mobile::AbstractMobile.carrier('HTTP_USER_AGENT' => user_agent)
  end

  def request_as_smart_phone
    user_agent = 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 2_0_1 like Mac OS X; ja-jp) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5B108 Safari/525.20'
    request.env['rack.jpmobile'] = Jpmobile::Mobile::AbstractMobile.carrier('HTTP_USER_AGENT' => user_agent)
  end
end
