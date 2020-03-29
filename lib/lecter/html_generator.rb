require 'lecter/html_row'

module Lecter
  class HtmlGenerator
    COUNT_LINES_AROUND_RUNNING_ROW = 5.freeze
    ELLIPSIS = "...\n".freeze

    def initialize(data)
      @data = data
    end
    
    def call
      @data.each_with_index.map do |item, item_index|
        @file_name = item.keys.first
        @executable_row_numbers = item.values.split(' ').flatten.map(&:to_i)
        previous_row_is_empty = false
        file_context = File.open(Rails.root.join(file_name), 'r').read.split("\n")

        @html_rows = file_context.each_with_index.map do |file_row, file_row_index|
          @file_row_index = file_row_index
          row_executable = executable_row_numbers.include?(file_row_index + 1)

          if row_executable || file_row_in_showing_range?(file_row_index)
            previous_row_is_empty = false
            Lecter::HtmlRow.new(
              file_row,
              file_row_index + 1,
              row_executable,
              executable_row_numbers).create
          elsif !previous_row_is_empty
            previous_row_is_empty = true
            ELLIPSIS
          end
        end

        FileListing.new(file_name, html_rows)
      end
    end

    private

    attr_accessor :executable_row_numbers, :file_row_index, :file_name, :html_rows

    def file_row_in_showing_range?(index)
      executable_row_numbers.reduce(false) do |memo, line_index|
        memo || file_row_index.in?(
          line_index - COUNT_LINES_AROUND_RUNNING_ROW - 1..
            line_index + COUNT_LINES_AROUND_RUNNING_ROW - 1)
      end
    end
  end

  FileListing = Struct.new(:file_name, :html_rows)
end