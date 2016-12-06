require_relative 'rewrite_rule'
require_relative 'table_rewriter'

class TableRewriterFactory
  SCHEMA_NAME = 'schemaname'
  TABLE_NAME = 'relname'
  WORD_LOCATION = 'location'

  KEY_TABLE_INFO = 'RangeVar'

  def initialize(csv_file)
    @rules = RewriteRule.load_from_csv(csv_file)
  end

  def get_rewriter(sql_string, quote='"')
    TableRewriter.new(sql_string, @rules, quote)
  end

  def print_rules
    RewriteRule.print_rules @rules
  end

  if __FILE__ == $0
    writer_factory = TableRewriterFactory.new('rewrite_rules.csv')
    writer_factory.print_rules

    sql_strings = [
        'SELECT * from (select * from abc.test) xx',
        "SELECT * from \n abc.aaa",
        'SELECT "aBc"."tEst" from bbb',
        'SELECT * from abc.aaa t1 join bbb t2 on t1.a = t2.b',
        'SELECT * from abc.aaa t1 join (select * from def.test d1 join hjk.abc d2 on d1.a = d2.b) t2 on t1.a = t2.b',
        'SELECT * from bbb t1 join (select * from def.test) t2 on t1.a = t2.b',
        'SELECT * FRO',
        'SELECT abc.aaa from aBc.tEst',
        'SELECT abc.aaa from "aBc"."tEst"',
        'SELECT abc.aaa from aBc."tEst"',
        'SELECT abc.aaa from "aBc".tEst'
    ]

    sql_strings.each do |sql_string|
      writer = writer_factory.get_rewriter(sql_string)
      writer.do
      writer.print_tables
    end

    hive_sql_strings = [
        'SELECT abc.aaa from `aBc`.`tEst`',
        'SELECT abc.aaa from aBc.`tEst`',
        'SELECT abc.aaa from `aBc`.tEst'
    ]

    hive_sql_strings.each do |sql_string|
      writer = writer_factory.get_rewriter(sql_string, '`')
      writer.do
      writer.print_tables
    end

  end
end