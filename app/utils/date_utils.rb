module DateUtils
  module_function

  def from_date_select(hash, name)
    date_arr = [1, 2, 3].map do |index| 
      hash["#{name.to_s}"]["(#{index}i)"].to_i
    end

    Date.new *date_arr
  end

  def duration_days(start_date, end_date)
    (end_date - start_date).to_i + 1
  end
end
