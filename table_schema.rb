class TableSchema

  attr_accessor :num
  attr_accessor :schema
  attr_accessor :name
  attr_accessor :loc
  attr_accessor :full_name

  def self.sort_tables(tables)
    if tables.kind_of?(Array)
      tables.sort { |x, y| x.loc <=> y.loc }
    else
      raise 'invalid tables given'
    end
  end

  def self.print_tables(tables)
    if tables.kind_of?(Array)
      puts 'Detected tables (with position in SQL string)'
      tables.each do |table|
        table.print
      end
      puts ''
    else
      puts 'Invalid tables given'
    end
  end

  def initialize(num, schema, name, loc, sql_string, in_quote, out_quote)
    @num = num
    @schema = schema
    @name = name
    @loc = loc

    @is_schema_quoted = false
    @is_name_quoted = false
    check_quoted(sql_string, in_quote)

    @full_name = (@schema.nil? ? '' : quote_schema_if_needed(out_quote) + '.') + quote_name_if_needed(out_quote)
  end

  def check_quoted(sql_string, quote)
    if @schema.nil?
      @is_name_quoted = check_quoted_name(sql_string, quote, 0)
    else
      if sql_string[@loc] == quote
        @is_schema_quoted = true
        @is_name_quoted = check_quoted_name(sql_string, quote, @schema.length + 3)
      else
        @is_name_quoted = check_quoted_name(sql_string, quote, @schema.length + 1)
      end
    end
  end

  def check_quoted_name(sql_string, quote, offset)
    sql_string[@loc + offset] == quote
  end

  def quote_schema_if_needed(out_quote)
    @is_schema_quoted ? out_quote + @schema + out_quote : @schema
  end

  def quote_name_if_needed(out_quote)
    @is_name_quoted ? out_quote + @name + out_quote : @name
  end

  def print
    puts "#{@num} - #{@full_name} at #{@loc}"
  end

  def length
    @full_name.length
  end

  private :check_quoted, :check_quoted_name, :quote_schema_if_needed, :quote_name_if_needed

end