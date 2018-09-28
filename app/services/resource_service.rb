class ResourceService < Dry::Struct
  extend Memoist
  include AccessLevel

  attribute :path, ResourcePath
  attribute :access_token, Types::Strict::String.optional

  def self.call(attrs)
    catch :halt do
      new(attrs).process
    end
  end

  def resource
    Resource[path]
  end
  memoize :resource

  def validate_permission!(action_level)
    return if can?(action_level)
    message =
      case action_level
      when READ then 'You are not authorized to see this page.'
      when WRITE then 'You are not authorized to edit this page.'
      when CREATE then 'You are not authorized to create a page here.'
      else 'You are not authorized to do this.'
      end
    raise Errors::UnauthorizedError.new(message)
  end

  def can?(action_level)
    @authorization ||= PathAuthorization.get(path, access_token)
    @authorization.can?(action_level)
  end

  def create_resource_with_ownership(params = {})
    resource.create!(params)

    unless can?(ADMIN)
      PathAuthorization.create!(
        path: path,
        token: access_token,
        level: AccessLevel::ADMIN,
      )
    end
  end
end
