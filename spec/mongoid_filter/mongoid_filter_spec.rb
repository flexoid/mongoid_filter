require 'spec_helper'

describe MongoidFilter do
  let(:movie_klass) do
    Class.new do
      include Mongoid::Document
      include MongoidFilter
    end
  end

  let(:movie) { movie_klass.new }
  let(:filter_params) { {year_gte: 2005, director_eq: 'Christopher Nolan'} }

  describe "accessors" do
    it "exist in class" do
      expect(movie_klass.respond_to?(:filter_fields)).to be_true
      expect(movie_klass.respond_to?(:filter_fields=)).to be_true
      expect(movie_klass.respond_to?(:special_filters)).to be_true
      expect(movie_klass.respond_to?(:special_filters=)).to be_true
      expect(movie_klass.respond_to?(:filter_field_aliases)).to be_true
      expect(movie_klass.respond_to?(:filter_field_aliases=)).to be_true
    end
  end

  describe "#can_filter_by" do
    before(:each) do
      movie_klass.instance_eval do
        can_filter_by :director, :rating, :premiere_date
        can_filter_by :year
      end
    end

    it "adds fields to class_attribute" do
      expect(movie_klass.filter_fields).to eq([:director, :rating, :premiere_date, :year])
    end
  end

  describe "#special_filter" do
    @special_filter_proc = ->(date) { Date.strptime(date, '%m/%d/%Y') }
    before(:each) do
      movie_klass.instance_eval do
        special_filter :premiere_date, @special_filter_proc, field_name: :release_date
      end
    end

    it "adds filter proc to spefial filters" do
      expect(movie_klass.special_filters).to eq({premiere_date: @special_filter_proc})
    end

    it "adds field alias to aliases hash" do
      expect(movie_klass.filter_field_aliases).to eq({premiere_date: :release_date})
    end
  end

  describe "#filter_form_object" do
    context "returns empty form object" do
      let(:empty_ostruct) { OpenStruct.new }

      it "when #filter_by isn't applied to model" do
        form_object = movie_klass.filter_form_object
        expect(form_object.form_fields_struct).to eq(empty_ostruct)
      end

      it "when #filter_by invoked on model with empty hash" do
        form_object = movie_klass.filter_by({}).filter_form_object
        expect(form_object.form_fields_struct).to eq(empty_ostruct)
      end

      it "when #filter_by invoked on criteria with empty hash" do
        form_object = movie_klass.where(year: 2013).filter_by({}).filter_form_object
        expect(form_object.form_fields_struct).to eq(empty_ostruct)
      end
    end

    context "returns correct form object" do
      let(:ostruct) { MongoidFilter::FormObject.new(filter_params).form_fields_struct }

      it "when #filter_by invoked on model with params" do
        form_object = movie_klass.filter_by(filter_params).filter_form_object
        expect(form_object.form_fields_struct).to eq(ostruct)
      end

      it "when #filter_by invoked on criteria with params" do
        form_object = movie_klass.where(year: 2013).
          filter_by(filter_params).filter_form_object
        expect(form_object.form_fields_struct).to eq(ostruct)
      end
    end
  end

  describe "#filter_by" do
    before(:each) do
      movie_klass.instance_eval do
        can_filter_by :director, :year, :premiere_date, :score
        special_filter :score,
          ->(score) { score * 10 },
          field_name: :rating
      end
    end

    describe "operator" do
      %w(gt gte lt lte).each do |operator|
        it operator do
          expect(movie_klass.filter_by({:"year_#{operator}" => 2000}).selector).
            to eq({'year' => {"$#{operator}" => 2000}})
        end
      end

      it "from" do
        expect(movie_klass.filter_by({year_from: 2000}).selector).
          to eq({'year' => {'$gte' => 2000}})
      end

      it "to" do
        expect(movie_klass.filter_by({year_to: 2000}).selector).
          to eq({'year' => {'$lte' => 2000}})
      end

      it "in" do
        expect(movie_klass.filter_by({year_in: [2000, 2001]}).selector).
          to eq({'year' => {'$in' => [2000, 2001]}})
      end

      it "cont" do
        expect(movie_klass.filter_by({director_cont: 'Nolan'}).selector).
          to eq({'director' => /.*Nolan.*/i})
      end

      it "combination of operators" do
        expect(movie_klass.filter_by(filter_params).selector).
          to eq({'year' => {'$gte' => 2005}, 'director' => 'Christopher Nolan'})
      end

      it "unsupported operator" do
        expect(movie_klass.filter_by({year_greater: 2000}).selector).to eq({})
      end
    end

    describe 'special filter' do
      it 'with custom field name' do
        expect(movie_klass.filter_by({score_gt: 10}).selector).
          to eq({'rating' => {'$gt' => 100}})
      end
    end
  end

  describe "FormObject" do
    subject { MongoidFilter::FormObject.new(filter_params) }
    it "forwards getting values to inner OStruct" do
      expect(subject.year_gte).to eq(2005)
      expect(subject.director_eq).to eq('Christopher Nolan')
    end
  end
end
