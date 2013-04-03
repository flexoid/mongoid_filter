require "mongoid-filter/version"
require 'ostruct'

module MongoidFilter
  extend ActiveSupport::Concern

  class FormObject
    attr_reader :form_fields_struct

    def initialize(filter_params)
      @form_fields_struct = OpenStruct.new(filter_params)
    end

    def method_missing(method, *args, &block)
      @form_fields_struct.public_send(method, *args, &block)
    end
  end

  included do
    cattr_accessor :filter_fields do
      []
    end
    cattr_accessor :special_filters do
      {}
    end
  end

  module ClassMethods
    def can_filter_by(*fields)
      self.filter_fields.concat(fields.flatten.map(&:to_sym))
    end

    def special_filter(field, deserializing_proc)
      self.special_filters.merge!(field => deserializing_proc)
    end

    def filter_by(filter_params)
      condition = {}
      prepare_filter_params(filter_params).each do |attribute, value|
        field_name, operator = parse_attribute(attribute)
        condition.merge!(build_expression(field_name, operator, value)) if field_name.in? filter_fields
      end
      criteria = where(condition)
      criteria.instance_variable_set(:@filter_form_object, FormObject.new(filter_params))
      criteria
    end

    def filter_form_object
      criteria.instance_variable_get(:@filter_form_object) || FormObject.new({})
    end

    private
      def parse_attribute(attribute)
        parts = attribute.split('_')
        field_name = parts[0...-1].join('_').to_sym
        operator = parts[-1].to_sym
        [field_name, operator]
      end

      def build_expression(field_name, operator, value)
        value = deserialize_value(field_name, value)
        case operator
        when :eq
          {field_name => value}
        when :gt, :lt, :gte, :lte
          {field_name.send(operator) => value}
        when :from
          {field_name.gte => value}
        when :to
          {field_name.lte => value}
        else
          {}
        end
      end

      def prepare_filter_params(filter_params)
        (filter_params || {}).select { |key, value| value.present? }.with_indifferent_access
      end

      def deserialize_value(field_name, value)
        self.special_filters[field_name].try(:call, value) || value
      end

  end
end
