require 'rails_helper'

describe TeamsController do
  let(:user) { create(:user) }

  describe 'GET #index' do
    before do
      create_list(:team, 50)
    end

    it 'succeeds' do
      get :index

      expect(response).to have_http_status(:success)
    end

    it 'succeeds with search' do
      get :index, params: { q: 'foo' }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #new' do
    it 'succeeds' do
      sign_in user

      get :new

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'creates a team' do
      sign_in user
      post :create, params: { team: { name: 'A', description: 'B' } }

      team = Team.find_by(name: 'A')
      expect(team).to_not be_nil
      expect(team.description).to eq('B')
      expect(team.on_roster?(user)).to be(true)
      expect(user.can?(:edit, team)).to be(true)
    end

    it 'handles duplicate teams' do
      create(:team, name: 'A')

      sign_in user
      post :create, params: { team: { name: 'A', description: 'B' } }
    end
  end

  describe 'GET #show' do
    it 'succeeds' do
      team = create(:team)

      get :show, params: { id: team.id }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit' do
    it 'succeeds' do
      team = create(:team)
      user.grant(:edit, team)

      sign_in user
      get :edit, params: { id: team.id }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH #update' do
    let(:team) { create(:team_with_avatar, name: 'A', description: 'B') }

    it 'updates a team' do
      user.grant(:edit, team)
      sign_in user

      patch :update, params: { id: team.id, team: { name: 'C', description: 'D' } }

      team.reload
      expect(team.name).to eq('C')
      expect(team.description).to eq('D')
      expect(response).to redirect_to(team_path(team))
    end

    it 'allows avatar removal' do
      user.grant(:edit, team)
      sign_in user

      patch :update, params: { id: team.id, team: { remove_avatar: true } }

      team.reload
      expect(team.avatar.url).to eq(team.avatar.default_url)
      expect(response).to redirect_to(team_path(team))
    end

    it 'fails for invalid data' do
      user.grant(:edit, team)
      sign_in user

      patch :update, params: { id: team.id, team: { name: '', description: '' } }

      team.reload
      expect(team.name).to eq('A')
      expect(team.description).to eq('B')
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #recruit' do
    before { create_list(:user, 20) }

    it 'succeeds' do
      team = create(:team)
      user.grant(:edit, team)

      sign_in user
      get :recruit, params: { id: team.id }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH #invite' do
    it 'invites a player to a team' do
      team = create(:team)
      invited = create(:user)
      user.grant(:edit, team)

      sign_in user
      patch :invite, params: { id: team.id, user_id: invited.id }

      invite = invited.team_invites.first
      expect(invite).to_not be_nil
      expect(invite.user).to eq(invited)
      expect(invite.team).to eq(team)
      expect(team.invited?(invited)).to be(true)
      expect(invited.notifications).to_not be_empty
      expect(user.notifications).to be_empty
    end
  end

  describe 'PATCH #kick' do
    it 'removes a player from a team' do
      team = create(:team)
      player = create(:user)
      team.add_player!(player)
      user.grant(:edit, team)
      sign_in user

      patch :kick, params: { id: team.id, user_id: player.id }

      expect(team.on_roster?(player)).to be(false)
      expect(team.invited?(player)).to be(false)
      expect(player.notifications).to_not be_empty
      expect(user.notifications).to be_empty
      expect(response).to redirect_to(team_path(team))
    end
  end

  describe 'PATCH #leave' do
    it 'removes a player from a team' do
      team = create(:team)
      team.add_player!(user)
      captain = create(:user)
      captain.grant(:edit, team)
      sign_in user

      patch :leave, params: { id: team.id }

      team.reload
      expect(team.on_roster?(user)).to be(false)
      expect(team.invited?(user)).to be(false)
      expect(user.notifications).to be_empty
      expect(captain.notifications).to_not be_empty
      expect(response).to redirect_to(team_path(team))
    end
  end

  describe 'DELETE #destroy' do
    let(:team) { create(:team) }
    let(:user) { create(:user) }
    let(:invited) { create(:user) }

    before do
      team.add_player!(user)
      invited.grant(:edit, team)
      team.invite(invited)
    end

    it 'succeeds for authorized user' do
      user.grant(:edit, :teams)
      sign_in user

      delete :destroy, params: { id: team.id }

      expect(Team.all).to be_empty
    end

    it 'succeeds for authorized captains' do
      invited.grant(:edit, team)
      sign_in invited

      delete :destroy, params: { id: team.id }

      expect(Team.all).to be_empty
    end

    it 'fails for unauthorized user' do
      sign_in user

      delete :destroy, params: { id: team.id }

      expect(Team.where(id: team.id)).to exist
    end
  end
end
