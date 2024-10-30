require 'json'

# Define file paths for input and output files
users_file = 'users.json'
companies_file = 'companies.json'
output_file = 'output.txt'

# Load users and companies data from JSON files with error handling
def load_data(file)
  JSON.parse(File.read(file))
rescue Errno::ENOENT
  puts "Error: File #{file} not found."
  exit
rescue JSON::ParserError
  puts "Error: File #{file} contains invalid JSON."
  exit
end

users = load_data(users_file)
companies = load_data(companies_file)

# Create a mapping of companies by ID for easy access
# This lets us quickly look up company info based on its ID
company_map = companies.each_with_object({}) do |company, map|
  map[company['id']] = company
end

# Main function to process users and companies and generate the formatted output
def process_users_and_companies(users, company_map)
  output = [] # Array to store each formatted line of output

  # Iterate through companies in ID order for sorted output
  company_map.keys.sort.each do |company_id|
    company = company_map[company_id]
    next unless company # Skip if company data is missing or invalid

    # Add company header information to output
    output << "\tCompany Id: #{company['id']}"
    output << "\tCompany Name: #{company['name']}"
    output << "\tUsers Emailed:"

    # Prepare to categorize users by their email status
    emailed_users = []
    not_emailed_users = []
    total_top_up = 0 # Track total top-up for the company

    # Filter users by company and active status, then sort alphabetically by last name
    active_users = users.select { |user| user['company_id'] == company_id && user['active_status'] }
    active_users.sort_by! { |user| user['last_name'] }

    active_users.each do |user|
      # Capture user's token balance before the top-up for reporting
      previous_tokens = user['tokens']
      top_up_amount = company['top_up']

      # Apply token top-up
      user['tokens'] += top_up_amount
      total_top_up += top_up_amount

      # Format user information for output
      user_info = "\t\t#{user['last_name']}, #{user['first_name']}, #{user['email']}\n" \
                  "\t\t  Previous Token Balance, #{previous_tokens}\n" \
                  "\t\t  New Token Balance #{user['tokens']}"

      # Sort users into emailed/not-emailed based on their email status
      if user['email_status']
        emailed_users << user_info
      else
        not_emailed_users << user_info
      end
    end

    # Add formatted user data to output under "Users Emailed" and "Users Not Emailed"
    output.concat(emailed_users) unless emailed_users.empty?
    output << "\tUsers Not Emailed:" unless not_emailed_users.empty?
    output.concat(not_emailed_users) unless not_emailed_users.empty?

    # Add company-wide total top-up summary
    output << "\tTotal amount of top ups for #{company['name']}: #{total_top_up}"
    output << "" # Blank line for spacing between companies
  end

  output
end

# Write formatted output to the output file with error handling
def write_output(output, file_path)
    File.open(file_path, 'w') do |file|
      output.each { |line| file.puts(line) }
    end
    puts "Output written to #{file_path}"
  rescue IOError
    puts "Error: Unable to write to file #{file_path}."
    exit
  end

# Generate the report data and write it to the output file
output_lines = process_users_and_companies(users, company_map)
write_output(output_lines, output_file)