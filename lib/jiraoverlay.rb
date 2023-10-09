require "jiraoverlay/version"
require 'jira4r/jira4r'
require File.join(File.dirname(__FILE__), 'jiraissue.rb')

module JiraOverlay
  @user = nil
  @passwd = nil
  @jira_tool = nil
  
  def self.login(user=nil,passwd=nil)
    @user, @passwd = user, passwd
    if (@user.nil? or @passwd.nil? or !@user.is_a?(String) or  !@passwd.is_a?(String))
      self.no_login
    else
      @jira_tool = Jira4R::JiraTool.new(2, 'https://ticket.domain.com')
      @jira_tool.login(@user, @passwd)
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      @jira_tool.logger = logger
      self
    end
  end
  def self.renew; self.login(@user,@passwd) end
  def self.no_login
    raise "Error not logged in please call JiraOverlay.login('your-username', 'your-password') to login."
  end
  
  def self.get_issues(jql, limit=20) 
    self.renew
    @jira_tool.getIssuesFromJqlSearch(jql, limit).collect {|i| JiraIssue.new(i, @jira_tool.getComments(i.key), @jira_tool.getComponents(i.project), @jira_tool.getVersions(i.project), @jira_tool.getFieldsForEdit(i.key), self)}
  end
  def self.get_issue(issue_id)
    self.renew
    raise ArgumentError, "\n\t Invalid arguemnt, please provide only an issue Id ex: OP-100.\n\t If you want to get an issue/s by a JQL query please use JiraOverlay.get_issues('jql-statement')." if issue_id.include?("=") or issue_id.include?("'")
    issue= @jira_tool.getIssuesFromJqlSearch("id=#{issue_id}", 1)[0]
    JiraIssue.new(issue, @jira_tool.getComments(issue.key), @jira_tool.getComponents(issue.project), @jira_tool.getVersions(issue.project), @jira_tool.getFieldsForEdit(issue.key), self)
  end
  def self.update_issue(issue_key,field_name,the_value)
    self.renew
    new_value = Jira4R::V2::RemoteFieldValue.new(field_name, the_value)
    begin 
      @jira_tool.updateIssue(issue_key, new_value)
    rescue =>e 
      raise  "Update failed: #{e}"
    end
  end

  def self.lazy
    got = self.login('username','password!').get_issue('issue_num')
  end
end