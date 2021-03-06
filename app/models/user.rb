require 'elasticsearch/model'

class User < ApplicationRecord
  include Searchable
  include Auth::Model

  EMAIL_CONFIRMATION_TIMEOUT = 1.hour

  has_many :titles, -> { order(created_at: :desc) }
  has_many :names, -> { order(created_at: :desc) }, class_name: 'NameChange'
  has_many :notifications, -> { order(created_at: :desc) }
  has_many :forums_subscriptions, class_name: 'Forums::Subscription'

  has_many :team_players, class_name: 'Team::Player'
  private :team_players, :team_players=
  has_many :teams, through: :team_players
  has_many :team_invites, class_name: 'Team::Invite'
  has_many :team_transfers, -> { order(created_at: :desc) }, class_name: 'Team::Transfer'

  has_many :roster_players, class_name: 'League::Roster::Player'
  private :roster_players, :roster_players=
  has_many :rosters, through: :roster_players, class_name: 'League::Roster'
  has_many :roster_transfers,         class_name: 'League::Roster::Transfer'
  has_many :roster_transfer_requests, class_name: 'League::Roster::TransferRequest'

  devise :rememberable, :trackable, :omniauthable, omniauth_providers: [:steam]

  validates :name, presence: true, uniqueness: true, length: { in: 1..64 }
  validates :steam_id, presence: true, uniqueness: true,
                       numericality: { greater_than: 0 }
  validates :description, presence: true, allow_blank: true
  validates :email, allow_blank: true, format: { with: /@/ } # How you actually validate emails

  validates_permission_to :edit, :users

  validates_permission_to :edit, :team
  validates_permission_to :edit, :teams

  validates_permission_to :edit, :games

  validates_permission_to :edit, :league
  validates_permission_to :edit, :leagues

  validates_permission_to :manage_rosters, :league
  validates_permission_to :manage_rosters, :leagues

  validates_permission_to :edit, :permissions

  validates_permission_to :manage, :forums
  validates_permission_to :manage, :forums_topic,  class_name: '::Forums::Topic'
  validates_permission_to :manage, :forums_thread, class_name: '::Forums::Thread'

  mount_uploader :avatar, AvatarUploader

  alias_attribute :to_s, :name

  searchable_fields :name, :steam_id, :steam_id_nice
  search_mappings do
    indexes :name, analyzer: 'search'
    indexes :steam_id, analyzer: 'keyword'
    indexes :steam_id_nice, analyzer: 'keyword'
  end

  def steam_profile_url
    "http://steamcommunity.com/profiles/#{steam_id}"
  end

  def matches
    rosters_sql = rosters.select(:id).to_sql
    League::Match.where("home_team_id IN (#{rosters_sql}) OR away_team_id IN (#{rosters_sql})")
  end

  def entered?(comp)
    comp.players(user: self).exists?
  end

  def steam_id_nice
    SteamId.to_str(steam_id)
  end

  def admin?
    can?(:edit, :teams) ||
      can?(:edit, :leagues) ||
      can?(:edit, :games) ||
      can?(:manage_rosters, :leagues) ||
      can?(:edit, :permissions)
  end

  def aka
    names.approved.where.not(name: name)
  end

  def notify!(message, link)
    notifications.create!(message: message, link: link)
  end

  def confirm
    update(confirmed_at: Time.current)
  end

  def generate_confirmation_token
    self.confirmed_at = nil
    self.confirmation_sent_at = Time.current
    self.confirmation_token = SecureRandom.urlsafe_base64(64)
  end

  def confirmation_timed_out?
    (Time.current - confirmation_sent_at) > EMAIL_CONFIRMATION_TIMEOUT
  end

  def confirmed?
    !confirmed_at.nil?
  end

  # Always remember using devise rememberable
  def remember_me
    true
  end

  private

  def get_player_rosters(transfers, transfer_sort, rosters, rosters_sort)
    # TODO: transfer_sort and rosters_sort can be inferred
    ids = player_transfers(transfers, transfer_sort)
    rosters.joins(:transfers)
           .where(rosters_sort => { id: ids, is_joining: true })
           .order(:name)
  end
end
