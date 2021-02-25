module V1
  module Entities
    class Base < Grape::Entity
      format_with(:without_nil) { |d| d.to_s }
      format_with(:utc_datetime) { |d| d.to_i }
    end
  end
end
