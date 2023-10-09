class JiraUpdater
  def initialize (issue_key, translator_shared, jira_overlay)
    @jira_overlay = jira_overlay
    @translator = translator_shared #passed translator object (passed to maintain consitent info program wide)
    @issue_key = issue_key
  end
  def update_issue(which_field, value, is_array=nil, editable=true)
    raise @translator.uneditable(which_field) if !editable #raises an explanating possible reasons of why it cannot be edited
    which_field = @translator.false_names[which_field] if @translator.false_names.has_key?(which_field) #force overrides any naming incositencies between SOAP and the Jira4r layers
    puts "Sending update for #{which_field} field with value: #{value}"
    which_field = (@translator.custom_field_names.has_value?(which_field) ? @translator.custom_field_names.invert[which_field] : which_field) #check if field is a customfield and if so translates it back to its customfield_id
    value = @translator.insert_x(which_field.to_s,value) #crosschecks with translator and updates value if which_field corresponds w/ an insert fn
    which_field = which_field.gsub(/_([a-z])/) {$1.capitalize}
    @jira_overlay.update_issue(@issue_key, which_field, value)
    puts "Successfully updated #{which_field} field to: #{value}" unless !is_array and value.is_a?(Array)
    warn("\nWarning: The value you provided is an array, but the #{which_field} field is not.\nThe field was set to: #{value[0]} (the first value of the array given)\n") if !is_array and value.is_a?(Array)   
  end
end