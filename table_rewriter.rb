require 'colorize'
require 'pg_query'
require_relative 'rewrite_rule'
require_relative 'table_schema'

class TableRewriter
  SCHEMA_NAME = 'schemaname'
  TABLE_NAME = 'relname'
  WORD_LOCATION = 'location'

  KEY_TABLE_INFO = 'RangeVar'

  def initialize(sql_string, rewrite_rules, out_quote)
    @out_quote = out_quote
    @psql_quote = '"'

    @sql_string = sql_string.gsub(out_quote, @psql_quote)
    @rewrite_rules = rewrite_rules
    @done = false

    @tables = Array.new
  end

  def do
    begin
      @parsed = PgQuery.parse(@sql_string)
    rescue Exception => e
      puts 'Original SQL:'
      puts "#{@sql_string}"
      puts 'SQL parsing failed:'
      puts e.message
      return false
    end

    visit_tree(@parsed.tree, 0)
    @original_tables = @tables.map(&:clone)

    sorted_tables = TableSchema.sort_tables @tables
    tokens = tokenize sorted_tables

    puts 'Original SQL:'
    puts "#{tokens.join('')}"

    rename_tables(tokens, sorted_tables)

    puts 'Rewrote SQL:'
    puts "#{tokens.join('')}\n\n"
    @done = true
    true
  end

  def print_tables
    if @done
      TableSchema.print_tables @original_tables
    else
      puts "SQL is not parsed yet. Please call 'do' first\n\n"
    end
  end

  def visit_tree(tree, step)
    if tree.respond_to? :each
      # key, value
      tree.each do |key, val|
        val.nil? ? visit_tree(key, step + 1) : parse_element(step, key, val)
      end
    else
      # value only
    end
  end

  def parse_element(step, key, val)
    case key
      when KEY_TABLE_INFO
        insert_table_info(val)
      else
        visit_tree(val, step + 1)
    end
  end

  def insert_table_info(table_info)
    @tables << TableSchema.new(
        @tables.length + 1,
        table_info[SCHEMA_NAME],
        table_info[TABLE_NAME],
        table_info[WORD_LOCATION],
        @sql_string,
        @psql_quote,
        @out_quote
    )
  end

  def rename_tables(tokens, sorted_tables)
    sorted_tables.each do |table|
      @rewrite_rules.each do |rule|
        if rule.is_match?(table.schema, table.name)
          tokens[table.loc] = rule.rewrote.blue
          break
        end
      end
    end
  end

  def tokenize(sorted_tables)
    tokens = Array.new
    string_offset = 0
    table_index = 1
    sorted_tables.each do |table|
      tokens << @sql_string[string_offset..table.loc-1]
      tokens << table.full_name.cyan
      string_offset = table.loc + table.length
      table.loc = table_index
      table_index += 2
    end
    if string_offset < @sql_string.length
      tokens << @sql_string[string_offset..-1]
    end

    tokens
  end

  private :visit_tree, :parse_element, :insert_table_info, :rename_tables, :tokenize
end