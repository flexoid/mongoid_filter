module MongoidFilter
  class FormObject
    extend ActiveModel::Naming

    attr_reader :form_fields_struct

    def self.model_name
      ActiveModel::Name.new(self)
    end

    def initialize(filter_params)
      @form_fields_struct = OpenStruct.new(filter_params)
    end

    def method_missing(method, *args, &block)
      @form_fields_struct.public_send(method, *args, &block)
    end
  end
end
