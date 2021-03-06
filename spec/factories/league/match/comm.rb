FactoryGirl.define do
  factory :league_match_comm, class: League::Match::Comm do
    user
    association :match, factory: :league_match
    sequence(:content) { |n| "Can we play at #{n}:00" }
  end
end
