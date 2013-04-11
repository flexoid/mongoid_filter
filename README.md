# MongoidFilter

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'mongoid_filter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid_filter

## Usage

### Example

#### Model
```ruby
class Log
  include Mongoid::Document
  include MongoidFilter

  field :event_type,  type: String
  field :status,      type: Boolean

  # It will allow us to filter by this three fields
  can_filter_by :event_type, :status, :created_at

  # Specify custom method to create object from params
  special_filter :created_at, ->(date) { Date.strptime(date, '%m/%d/%Y') }
end
```
#### Controller
```ruby
@logs = Log.where(user_id: user.id).filter_by(params[:search])
```

#### View
```erb
<%= form_for @request_logs.filter_form_object, as: :search do |f| %>
  <%= f.select :event_type_eq, Log.event_types %>
  <%= f.select :status_eq, Log.statuses %>
  <%= f.text_area :created_at_gt %>
<% end %>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
