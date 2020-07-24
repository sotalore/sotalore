class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  define_model_callbacks :save

  FormInvalid = ActiveRecord::RecordInvalid

  attr_reader :model, :current_user

  def initialize(model, user)
    @model = model
    @current_user = user
  end

  def self.model_name
    parts = name.split("::")

    klass = parts.pop
    short_name = klass.sub(/(.+)(Form)/, "\\1")

    namespace = parts.join("::")
    namespace_obj = namespace.empty? ? nil : const_get(namespace)

    ActiveModel::Name.new(self, namespace_obj, short_name)
  end

  def attributes=(attrs)
    if attrs.respond_to?(:permitted?) && !attrs.permitted?
      raise ActiveModel::ForbiddenAttributesError.new('Unpermitted parameters passed to ApplicationForm')
    end
    attrs.each do |k,v|
      self.public_send("#{k}=", v)
    end
  end

  def save(attrs={})
    self.attributes = attrs
    return false unless valid?
    ActiveRecord::Base.transaction do
      run_callbacks(:save) do
        block_given? ? yield : model.save
      end
    end
  end
  alias_method :update, :save

  def save!(attrs={})
    save(attrs) or raise FormInvalid.new(self)
  end

  def update!(attrs={})
    update(attrs) or raise FormInvalid.new(self)
  end

end
