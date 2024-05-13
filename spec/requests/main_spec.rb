require 'rails_helper'

RSpec.feature "Main", type: :feature do
  scenario "user visits the homepage" do
    visit root_path
    expect(page).to have_content("Enter your address")
  end
end