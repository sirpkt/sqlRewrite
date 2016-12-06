require 'csv'

class RewriteRule

  attr_accessor :num
  attr_accessor :schema
  attr_accessor :name
  attr_accessor :rewrote

  def self.load_from_csv(csv_file)
    rules = Array.new
    begin
      CSV.foreach(csv_file) do |col1, col2, col3|
        rules << RewriteRule.new(rules.length + 1, col1, col2, col3)
      end
    rescue Exception => e
      raise('CSV parse error', e.message)
    end

    rules
  end

  def self.print_rules(rules)
    if rules.kind_of?(Array)
      puts 'Converting rules'
      rules.each do |rule|
        rule.print
      end
      puts ''
    else
      puts 'Invalid rules given'
    end
  end

  def initialize(num, schema, name, rewrote)
    @num = num
    @schema = schema
    @name = name
    @rewrote = rewrote
  end

  def is_match?(schema, name)
    @schema == schema and @name == name
  end

  def print
    puts @schema.nil? ? "rule #{@num} - #{@name} => #{@rewrote}"
                      : "rule #{@num} - #{@schema}.#{@name} => #{@rewrote}"
  end
end