require 'sinatra'
require 'json'

employees = [
  {
    name: 'Alfred Brown',
    shifts: [
      { day: 0, start_at: '12pm', end_at: '5pm', duration: 5, role: 'Server', color: 'red' },
      { day: 1, start_at: '9am', end_at: '12pm', duration: 3, role: 'Host', color: 'green' },
      { day: 3, start_at: '9am', end_at: '4pm', duration: 7, role: 'Server', color: 'red' },
      { day: 5, start_at: '9am', end_at: '2pm', duration: 5, role: 'Host', color: 'green' }
    ]
  },
  {
    name: 'Tim Cannady',
    shifts: [
      { day: 0, start_at: '11am', end_at: '6pm', duration: 7, role: 'Chef', color: 'orange' },
      { day: 1, start_at: '9am', end_at: '3pm', duration: 6, role: 'Dishwasher', color: 'purple' },
      { day: 2, start_at: '9am', end_at: '1pm', duration: 4, role: 'Chef', color: 'orange' },
      { day: 5, start_at: '9pm', end_at: '4am', duration: 7, role: 'Dishwasher', color: 'purple' }
    ]
  },
  {
    name: 'Jeff Auston',
    shifts: [
      { day: 1, start_at: '11am', end_at: '6pm', duration: 7, role: 'Chef', color: 'orange' },
      { day: 2, start_at: '9am', end_at: '3pm', duration: 6, role: 'Dishwasher', color: 'purple' },
      { day: 4, start_at: '9am', end_at: '1pm', duration: 4, role: 'Chef', color: 'orange' },
      { day: 6, start_at: '9am', end_at: '4pm', duration: 7, role: 'Dishwasher', color: 'purple' }
    ]
  }
]

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
    employees.sort_by { |employee| employee[:name].split.first }
  when 'last_name'
    employees.sort_by { |employee| employee[:name].split.last }
  else
    employees
  end
end

def add_totals(employees)
    data_with_totals = []
  
    employees.each do |employee|
      daily_totals = calculate_daily_totals(employee[:shifts])
      weekly_total = calculate_weekly_total(daily_totals)
  
      data_with_totals << {
        name: employee[:name],
        shifts: employee[:shifts],
        daily_totals: daily_totals,
        weekly_total: weekly_total
      }
    end
  
    data_with_totals
  end

def calculate_daily_totals(shifts)
    daily_totals = Hash.new(0)
  
    shifts.each do |shift|
      next unless shift.is_a?(Hash) && shift.key?(:day)
  
      begin
        day = shift[:day].to_i
      rescue StandardError => e
        raise e
      end
  
      daily_totals.update(day => daily_totals[day] + shift[:duration])
    end
  
    daily_totals.transform_keys!(&:to_s)
  
    daily_totals
  end

def calculate_weekly_total(daily_totals)
  daily_totals.values.sum
end
