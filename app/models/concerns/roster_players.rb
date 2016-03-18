module RosterPlayers
  extend ActiveSupport::Concern

  def on_roster?(user)
    players.where(user_id: user.id).exists?
  end

  def players
    if persisted?
      players_db
    else
      players_local
    end
  end

  def player_users
    players.map(&:user)
  end

  def player_ids
    players.map(&:user_id)
  end

  private

  class_methods do
    def transfers_table_name(name = 'transfers')
      @transfers_table_name ||= name
    end
  end

  def players_db
    tb_name = self.class.transfers_table_name
    t = transfers.select("DISTINCT ON(#{tb_name}.user_id) #{tb_name}.id")
                 .order(:user_id, created_at: :desc)

    transfers.where(id: t, is_joining: true)
             .joins(:user)
             .order('users.name')
             .includes(:user)
  end

  def players_local
    # TODO: Implement this properly. Right now its assuming #is_joining?
    transfers
  end
end