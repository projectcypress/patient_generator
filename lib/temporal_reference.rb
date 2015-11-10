class TemporalReference
  include Mongoid::Document

  field :start_time, type: Integer
  field :end_time, type: Integer


end
