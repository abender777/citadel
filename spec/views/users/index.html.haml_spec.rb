require 'rails_helper'

describe 'users/index' do
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }

  it 'shows all users' do
    assign(:users, User.paginate(page: 1))

    render

    expect(rendered).to include(user1.name)
    expect(rendered).to include(user2.name)
  end
end
