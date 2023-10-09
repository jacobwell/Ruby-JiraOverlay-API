require File.join(File.dirname(__FILE__), 'issuefield.rb')
require File.join(File.dirname(__FILE__), 'jiraupdater.rb')
require File.join(File.dirname(__FILE__), 'translator.rb')

class JiraIssue
  attr_reader :more_fields, :issue_fields, :comments, :translator
  def initialize(issue_in,comments,components,versions,editable_fields_in, jira_overlay)
    @custom_field_names, $component_names = {}, {}
    @issue_in = issue_in
    @more_fields = make_field_tables(editable_fields_in).compact.sort #gets a list of all editable fields for the issue
    @more_fields.fill('epicTheme',@more_fields.index('epictheme'),1) #if more fields includes epictheme, fixes its name
    @translator = Translator.new(components,versions, @custom_field_names)
    @issue_fields = make_issue_fields.flatten.compact.sort {|x,y| x.name<=>y.name }
    @comments = comments #no fancy implimentation or object for yet
    @updater = JiraUpdater.new(issue_in.key, @translator, jira_overlay)
    @issue_fields.each do |a_field| #creates all the getters and setters for all the Jira fields that are set (rest are handled via missing_method)
      self.instance_variable_set("@#{a_field.name}", a_field.value)  #creates and initializes an instance variable for this key/value pair
      self.class.send(:define_method, a_field.name, proc{self.instance_variable_get("@#{a_field.name}")})  #creates the getter that returns the instance variable
      self.class.send(:define_method, "#{a_field.name}=", proc {|v| @updater.update_issue(a_field.name, v, a_field.array?, a_field.editable?)}) #creates the setter that will try to update the field
    end
  end
  def pp; @issue_fields.each {|field| field.pp} end
  def make_field_tables(editable_fields_given) #creates more_fields table and gets a large chunk of customfield names and id
    editable_fields_given.collect do |obj|
      pieces = obj.name.delete('/').downcase.split(' ').join("_") #camelizes field name
      @custom_field_names.merge!({obj.id => pieces})  if obj.id.include?('customfield_') #add key/value to table if is valid field
      pieces unless cannot_edit.include?(pieces)
    end
  end
  def make_issue_fields
    @issue_in.instance_variables.collect do |r| #Jira4R returns an issue object where all values are stored as methods
      r_new = r.to_s.gsub(/(.)([A-Z])/,'\1_\2').downcase
      r_new.slice!(0) #removes the colon from the symbol
      r_val = @issue_in.instance_variable_get(r)
      unless r_new == 'custom_field_values'
        the_field = IssueField.new(r_new,r_val, @more_fields.include?(r_new))
        @more_fields.delete(@more_fields) #removes from the more_fields to prevent redundancy
        @translator.fix(the_field) #fixes values and other information so is easier for user to read
        the_field
      else #handles customFields
        r_val.collect do |i|
          key_name = i.customfieldId
          key_name = (@custom_field_names.has_key?(key_name)) ? @custom_field_names[key_name] : key_name #tries to see if the customfield name has already been found
          the_var2 = i.instance_variable_get(:@values)
          the_field = IssueField.new(key_name,the_var2, @more_fields.include?(key_name))
          @more_fields.delete(key_name) #removes from the more_fields to prevent redundancy
          @translator.fix(the_field)  #fixes values and other information so is easier for user to read
          the_field
        end
      end
    end
  end
 def method_missing(called, *args, &block) #catch all to update an issue if a method is missing
   #i.e if a field is not set but is editable no method is made, so this catch all will allow them to be set 
   if args.length >= 1 #helps filter out misc. wrong method calls
     field = called.to_s #converts from symbol to image
     field.slice!('=') #the = sign from the setter is still on, so is removed
     @updater.update_issue(field,args[0])
   else; false
   end
 end
 def cannot_edit
   ['attachment', #not implemented yet
   'days_since_last_comment', #jira mistakenly reports this as editable
   'dueDate', #is redundant due to naming incositencies between jira and soap
   'functional_spec_link', #not implemented yet since is not in SBOX
   'story_point_range' #not implemented yet since is not in SBOX
   ]
 end
end