class RolesController < ApplicationController
  make_resourceful do
    actions :index, :new, :create, :edit, :update, :destroy
    
    response_for(:create, :update, :destroy, :destroy_fails) do |format|
      format.html { redirect_to roles_path }
    end
    
    before :new, :edit, :create, :update do
      @users = User.find(:all, :order => 'name ASC')
    end
  end
end
