require 'spec_helper'
require 'rack_session_access/capybara'

feature "My feature" do
  background do
    current_user = {
      user_id: 12345,
      name: "Sally"
    }
    page.set_rack_session(:current_user => current_user)
  end



  scenario "logged in user access profile page" do
    page.visit "/users/12345"
    page.should have_content("Sally's Posts")
  end

  # scenario "visit landing page" do
  #   page.visit "/"
  #   page.get_rack_session_key('ref').should == "123"
  # end
end
