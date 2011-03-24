require File.dirname(__FILE__) + '/../../spec_helper'

describe CacmAdmin::WidgetsController do
  scenario :widgets
  
  before do 
    CacmAdmin::WidgetsController.class_eval { no_login_required }
  end

  describe "access" do
    it "should always allow the index to be accessed" do
      get :index
      response.should render_template(:index)
    end

    it "should always allow safe edit to be accessed" do
      get :safeedit, :id => widgets(:bad_widget).id
      response.should render_template(:safeedit)
    end

    it "should allow new to be accessed with clone option" do
      get :new, :clone => widgets(:teeny_widget).id
# FIXME - KAS, why won't this work?
#      Widget.should_receive(:find)
      response.should render_template(:new)
    end

    it "should always allow new to be accessed" do
      get :new
      response.should render_template(:new)
    end

    it "should raise errors for malformed content" do
      get :edit, :id => widgets(:bad_widget).id
      response.should redirect_to(safeedit_admin_widget_path(:id => widgets(:bad_widget).id))
    end

    it "should not raise errors for good content" do
      get :edit, :id => widgets(:any_widget).id
      response.should render_template(:edit)
    end

    it "should raise errors for nonexistent widgets" do
      lambda {
        get :edit, :id => 99
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should allow well formed widgets to be created" do
      post :create, :widget => widgets(:any_widget).clone.attributes.merge("name" => "unique")
      response.should redirect_to(admin_widgets_path)
    end

    it "should also not reject malformed widgets on create" do
      post :create, :widget => widgets(:bad_widget).clone.attributes.merge("name" => "malformed")
      response.should redirect_to(admin_widgets_path)
    end

    it "should require a name" do
      post :create, :widget => widgets(:bad_widget).clone.attributes.merge("name" => nil)
      response.should render_template(:new)
    end

    it "should require content" do
      post :create, :widget => widgets(:any_widget).clone.attributes.merge("content" => nil)
      response.should render_template(:new)
    end

    it "should allow updates on well formed content" do
      @widget = widgets(:any_widget)
      @widget.widgetize
      post :update, :id => @widget.id, :widget => @widget.attributes.merge(:fck_content => @widget.fck_content).merge("content" => nil), :tag_blocks => DP::Spec.fake_form_post(@widget.rtag_blocks)
      response.should redirect_to(admin_widgets_path)
    end

    it "should rejects updates on malformed content" do
      @widget = widgets(:any_widget)
      @widget.widgetize
      post :update, :id => @widget.id, :widget => @widget.attributes.merge(:fck_content => @widget.fck_content[0..-10]).merge("content" => nil), :tag_blocks => DP::Spec.fake_form_post(@widget.rtag_blocks)
      response.should render_template(:edit)
    end

    it "should destroy and redirect upon request" do
      get :destroy, :id => widgets(:bad_widget).id
      response.should redirect_to(admin_widgets_path)
    end
  end

end
