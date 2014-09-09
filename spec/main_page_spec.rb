require 'spec_helper'
require 'rack_session_access/capybara'
require 'rack_session_access'

feature "My feature" do
  background do
    # binding.pry
    # @user = Factory(:current_user )
  end



  scenario "logged in user access profile page" do
    binding.pry
    page.set_rack_session(:user_id => "12345")
    page.visit "/users/12345"
    page.should have_content("Sally's Posts")
  end

  # scenario "visit landing page" do
  #   page.visit "/"
  #   page.get_rack_session_key('ref').should == "123"
  # end
end
