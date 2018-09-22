class Resource
  include Virtus.model

  attribute :id
  attribute :path
  attribute :title
  attribute :editor
  attribute :editor_url
  attribute :body

  class << self
    attr_writer :storage

    def storage
      @storage ||= build_storage
    end

    def build_storage
      return FileStorage.new if ENV['STORAGE'] == 'file'
      return RedisStorage.new if ENV['STORAGE'] == 'redis'
      return FileStorage.new if ENV['RAILS_ENV'].in?(['development', 'test'])
      return RedisStorage.new
    end
  end

  def self.find_or_initialize_by_path(path)
    find_by_path(path) || initialize_by_path(path)
  end

  def self.initialize_by_path(path, opts = {})
    new(
      id: rand(10**20),
      path: path,
      editor: 'brahin-slate-editor',
      editor_url: ENV.fetch('BRAHIN_SLATE_EDITOR_URL', '/modules/brahin-slate-editor.js'),
      body: ''
    ).tap do |resource|
      resource.init_plain_html_page(opts)
    end
  end

  def self.create(params)
    initialize_by_path(params[:path], params.except(:path))
  end

  def self.find_by_path(path)
    attributes = storage.get(path.presence)
    new(attributes.merge(path: path)) if attributes.present?
  end

  def self.save(path, attributes)
    storage.put(path.presence, attributes)
  end

  def self.digest(path)
    Digest::MD5.hexdigest(path)
  end

  def patch(params)
    self.body = params[:body] if params.has_key?(:body)
    self.title = params[:title] if params.has_key?(:title)
  end

  def init_plain_html_page(title: '', body: '')
    self.body = body.presence || "<h1>#{CGI.escapeHTML(title)}</h1><p></p>"
  end

  def save!
    self.class.save(path, attributes.except(:path))
  end
end
