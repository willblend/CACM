class RolesScenario < Scenario::Base
  uses :pages
  
  def load
    create_record Role, :admin, :name => 'admin'
    create_record Role, :developer, :name => 'developer'
    create_record Role, :editor, :name => 'editor'
  end
end