require 'sinatra'
require 'json'
require 'ruby/openai'
require 'dotenv'

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
end

client = OpenAI::Client.new



employees = [JSON.parse(File.read('shifts.json'))]

get '/shifts' do
  content_type 'application/json'

  sort_by = params['sort_by']
  sorted_employees = sort_employees(employees, sort_by)

  data_with_totals = add_totals(sorted_employees)

  daily_totals = calculate_daily_totals(data_with_totals)

  total_hours = calculate_total_hours(data_with_totals)

  most_hours_employee = employee_with_most_hours(total_hours)

  shift_plan_data = generate_plan(client, employees, data_with_totals)

  content_type :json
  { employees: employees, daily_totals: daily_totals, shift_plan_data: shift_plan_data }.to_json

  response_data = {
    employees: data_with_totals,
    daily_totals: daily_totals,
    most_hours_employee: most_hours_employee,
    shift_plan_data: shift_plan_data,
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

def calculate_total_hours(employees)
  total_hours = {}
  employees.each do |employee|
    total_hours[employee[:name]] = employee[:weekly_total]
  end
  total_hours
end

def employee_with_most_hours(total_hours)
  max_employee = total_hours.max_by { |_name, hours| hours }
  max_employee[0]
end

def generate_plan(client, employees, data_with_totals)
  most_hours_employee = data_with_totals.max_by { |employee| employee[:weekly_total] }

  total_hours = data_with_totals.sum { |employee| employee[:weekly_total] }
  average_hours = total_hours / employees.length

  target_hours_per_employee = average_hours

  shift_plan_details = []

  prompt = "Generate a shift plan for the next week to balance the hours among employees. #{most_hours_employee[:name]} has worked the most hours, providing the total amount of hours worked by each employee."

  data_with_totals.each do |employee|
    adjusted_hours = target_hours_per_employee - employee[:weekly_total].to_i
    adjusted_total_hours = employee[:weekly_total].to_i + adjusted_hours
    prompt += "\n- #{employee[:name]} (#{adjusted_total_hours} hours)"
    
    shift_plan_details << {
      name: employee[:name],
      adjusted_total_hours: adjusted_total_hours
    }
  end

  response = client.chat(
    parameters: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
    }
  )

  generated_message = response['choices'][0]['message']['content']

  { shift_plan_details: shift_plan_details, generated_message: generated_message }
end
