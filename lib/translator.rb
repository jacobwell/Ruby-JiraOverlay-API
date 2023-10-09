class Translator
  attr_reader :false_names, :custom_field_names
  def initialize(components_in,versions_in, custom_field_names)
    @version_keys, @component_keys ={},{}
    @custom_field_names = custom_field_names
    components_in.each {|a_component| @component_keys.merge!({a_component.id => a_component.name})} #generates component_keys
    versions_in.each {|version| @version_keys.merge!({"#{version.id}" => version.name})} #generates version_keys
    @false_names = {'due_date' => 'duedate', 'epic_theme' => 'epictheme'} #items that have names that do not match the standard naming system due to incositencies between SOAP and the Jira4r layers    
    
    @TYPE_KEYS = {
        '1' => 'Bug',
      	'2'=> 'User Story',
      	'3' => 'Task',
      	'5' => 'Generic Sub-task',
      	'6' => 'Test',
      	'7' => 'Feature',
      	'8' => 'Technical Debt',
      	'9' => 'Front End Sub-task',
      	'10' => 'Back End Sub-task',
      	'16' => 'Preformance Tuning'
    }
    @STATUS_KEYS = {
      '1' => 'Open',
      '3' => 'In Progress',
      '4' => 'Reopened',
      '5' => 'Resolved',
      '6' => 'Closed',
      '10038' => 'Stub',
      '10039' => 'Being Authored',
      '10040' => 'Ready for Development',
      '10041' => 'In Development',
      '10042' => 'Deployed'
    }
  end
  
  def uneditable(which_field) #a message to be printed explaining why a field is seemingly uneditable
    "\nSorry the \"#{which_field}\" field cannot be edited. Possible Causes: 
    \t1. Jira lied when it said it could be edited .
    \t2. Opower has blocked editing of this field and Jira doesn't know it. 
    \t3. The value although a valid   option for the #{which_field} field, 
    \t    it cannot be applied to this specific issue. 
    \t4. This feature has not been implemented yet in this Jira-API interface.
    \t5. You mistakenly thought this field could be updated.\n"
  end

#setters for cleaning up issuefield data

def fix(a_field) #passes field to corresponding fix functions to fix and convert to human readable
  it = a_field.name.downcase
  if it == 'dayssincelastcomment'; fix_dayssincelastcomment(a_field)
  elsif it == 'type'; fix_type(a_field)
  elsif it == 'status'; fix_status(a_field)
  elsif it == 'duedate'; fix_duedate(a_field)
  elsif it == 'urgentproductionissue'; fix_urgentproductionissue(a_field)
  elsif it == 'epictheme'; fix_epictheme(a_field)
  elsif it == 'updated' or it == 'created'; fix_time(a_field) #generic time fixing function
  elsif it == 'created'; fix_created(a_field)
  elsif it == 'components'; fix_components(a_field)
  elsif it.to_s.include?('ersion'); fix_versions(a_field) #various version fields catch-all
  end
end

def fix_time(field)
  field.value = field.value.strftime('%m/%d/%Y') unless field.value.nil? #converts datetime object to string
end 
  
def fix_dayssincelastcomment(field)
  field.value = field.value[0] if field.value.class.to_s.include?('rray')
  field.value = field.value.to_i / 86400 unless field.value.nil? #turns unix time count into # of days
end

def fix_type(field)
  field.value = @TYPE_KEYS[field.value] if @TYPE_KEYS.has_key?(field.value)
end     

def fix_status(field)
  field.value = @STATUS_KEYS[field.value] if @STATUS_KEYS.has_key?(field.value)
end

def fix_components(field)
    field.value = field.value.collect {|version| @component_keys["#{version.id.to_s}"] if @component_keys.has_key?("#{version.id.to_s}")}
  end
  
  def fix_versions(field)
    keys = @version_keys
    field.value = field.value.collect do |version| 
      if version.class.to_s.include?('RemoteVersion') #handler added since is an object sometimes and other version fields are just string ints corresponding with a version key
        keys["#{version.id.to_s}"] if keys.has_key?("#{version.id.to_s}")
      else
        (keys.has_key?("#{version.to_s}"))  ? keys["#{version.to_s}"] : version
      end
    end
  end
  
  def fix_duedate(field)
    field.value = field.value.strftime('%m/%d/%Y') unless field.value.nil?
    field.name = 'due_date' #fixes name inconsitency
    field.is_editable = true #fixes due to not being set correctly due to naming incosintenty
  end

  def fix_urgentproductionissue(field)
    field.value = (field.value == 'Urgent Production Issue') ? 'true' : 'false' #converts into string bool
  end

  def fix_epictheme(field)
    field.name = 'epic_theme' #fixes name inconsitency
    field.is_editable = true #fixes due to not being set correctly due to naming incosintenty
  end




  #insertion functions for seter

  def insert_x(what,value) #insert catch all that passed value to appropriate method
    if what == 'type'; insert_type(value)
    elsif what == 'status'; insert_status(value)
    elsif what == 'components'; insert_components(value)
    elsif what == 'duedate'; insert_duedate(value)
    elsif what == 'urgentProductionIssue'; insert_urgentProductionIssue(value)
    elsif what.include?('ersion'); insert_versions(value)
    else value
    end
  end

  def insert_type(value)
    bw_values = @TYPE_KEYS.invert
    (bw_values.has_key?("#{value}") ? bw_values["#{value}"] : value)
  end 
  
  def insert_status(value)
    bw_values = @STATUS_KEYS.invert 
    (bw_values.has_key?("#{value}") ? bw_values["#{value}"] : value)
  end
  
  def insert_versions(value)
    bw_values = @version_keys.invert 
    if value.class.to_s.include?('rray')
      value.collect {|val| bw_values["#{val}"]  if bw_values.has_key?("#{val}")} #converts each version key using keys
    else      
      bw_values["#{value}"]  if bw_values.has_key?("#{value}") #converts in case of not beinging given as an array
    end
  end
  
  def insert_components(value)
    bw_values = @component_keys.invert 
    if value.class.to_s.include?('rray')
      value.collect {|val| bw_values["#{val}"]  if bw_values.has_key?("#{val}")} #converts each component using keys
    else      
      bw_values["#{value}"]  if bw_values.has_key?("#{value}") #converts in case of not beinging given as an array
    end
  end
 
  def insert_duedate(value)
     (DateTime.strptime(value, '%m/%d/%Y').to_time + 28801).strftime('%e/%b/%y') unless value.nil? or value == 'nil' #converts from 12/31/2011 to 31/Dec/11
  end
  
  def insert_urgentProductionIssue(value)
    'Urgent Production Issue' unless value== '0' or value.nil? or value=='false' or value == '' or !value #takes bool int or string and converts to string needed to update field
  end
end