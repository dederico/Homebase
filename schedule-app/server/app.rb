require 'sinatra'
require 'json'

employees = [JSON.parse(File.read('shifts.json'))]

get '/shifts' do
  content_type 'application/json'

  sort_by = params['sort_by']
  sorted_employees = sort_employees(employees, sort_by)

  data_with_totals = add_totals(sorted_employees)

  daily_totals = calculate_daily_totals(data_with_totals)

  response_data = {
    employees: data_with_totals,
    daily_totals: daily_totals
  }

  response_data.to_json
end

def sort_employees(employees, sort_by)
    case sort_by
    when 'first_name'
      employees.flatten.sort_by { |employee| employee['name'].split.first }
    when 'last_name'
      employees.flatten.sort_by { |employee| employee['name'].split.last }
    else
      employees.flatten
    end
  end

  def add_totals(employees)
    data_with_totals = []
  
    employees.each do |employee|
      puts "Employee before flatten: #{employee.inspect}"
      employee.flatten
      puts "Employee after flatten: #{employee.inspect}"
      
      daily_totals = calculate_daily_totals(employee['shifts'])
      weekly_total = calculate_weekly_total(daily_totals)
  
      data_with_totals << {
        name: employee['name'],
        shifts: employee['shifts'],
        daily_totals: daily_totals,
        weekly_total: weekly_total
      }
    end
  
    data_with_totals
  end

def calculate_daily_totals(shifts)
    daily_totals = Hash.new(0)
  
    shifts.each do |shift|
      next unless shift.is_a?(Hash) && shift.key?('day')
  
      begin
        day = shift['day'].to_i
      rescue StandardError => e
        raise e
      end
  
      daily_totals.update(day => daily_totals[day] + shift['duration'])
    end
  
    daily_totals.transform_keys!(&:to_s)
  
    daily_totals
  end

def calculate_weekly_total(daily_totals)
  daily_totals.values.sum
end
