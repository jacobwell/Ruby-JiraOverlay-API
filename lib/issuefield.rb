class IssueField
  #custom field object to store data and metadata
  attr_accessor :name, :value, :is_editable
  def initialize(name, value, is_editable); @name, @value, @is_editable = name, value, is_editable end
  def array? ; (value.nil?) ? nil : value.class.to_s.include?('rray') end #is it content an array?
  def editable?; @is_editable end
  def pp; puts "#{@name} #{((@is_editable) ? '<=>' : '=>')} #{@value}\n\n" end #print in a readable format, '<=>' means editable
end