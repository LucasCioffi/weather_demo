require 'rails_helper'

RSpec.feature "Main", type: :feature do
  scenario "User visits the homepage" do
    visit '/'
    expect(page).to have_content('Enter your address')
  end
end