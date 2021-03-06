require 'rails_helper'

describe MatchSeeder::RoundRobin do
  context 'even number of teams' do
    before(:all) do
      @div = create(:league_division)
      @rosters = create_list(:league_roster, 6, division: @div)
      round = build(:league_match_round)

      5.times do
        described_class.seed_round_for(@div.reload, rounds: [round])
      end
    end

    it 'creates matches covering all teams' do
      @rosters.each do |roster|
        expect(roster.rosters_not_played).to be_empty
      end
    end

    xit 'evenly spreads home and away team matches' do
      @rosters.each do |roster|
        expect(roster.home_team_matches.not_bye.size)
          .to be_within(1).of(roster.away_team_matches.size)
      end
    end
  end

  context 'odd number of teams' do
    before(:all) do
      @div = create(:league_division)
      @rosters = create_list(:league_roster, 5, division: @div)
      round = build(:league_match_round)

      5.times do
        described_class.seed_round_for(@div.reload, rounds: [round])
      end
    end

    it 'creates matches covering all teams' do
      @rosters.each do |roster|
        expect(roster.rosters_not_played).to be_empty
      end
    end

    xit 'evenly spreads home and away team matches' do
      @rosters.each do |roster|
        expect(roster.home_team_matches.not_bye.size)
          .to be_within(1).of(roster.away_team_matches.size)
      end
    end

    it 'evenly spreads bye matches' do
      @rosters.each do |roster|
        expect(roster.matches.bye.size).to be <= 1
      end
    end
  end

  context 'disbanded teams' do
    before(:all) do
      @div = create(:league_division)
      @rosters = create_list(:league_roster, 6, division: @div)
      @rosters.first.disband

      round = build(:league_match_round)
      5.times do
        result = described_class.seed_round_for(@div.reload, rounds: [round])
        expect(result).to be_truthy
      end
    end

    it 'creates matches covering all teams' do
      @div.rosters.active.each do |roster|
        expect(roster.rosters_not_played).to be_empty
      end
    end

    xit 'evenly spreads home and away team matches' do
      @div.rosters.active.each do |roster|
        expect(roster.home_team_matches.not_bye.size)
          .to be_within(1).of(roster.away_team_matches.size)
      end
    end

    it 'evenly spreads bye matches' do
      @div.rosters.active.each do |roster|
        expect(roster.matches.bye.size).to be <= 1
      end
    end
  end

  it 'handles invalid options' do
    @div = create(:league_division)
    @rosters = create_list(:league_roster, 3, division: @div)

    round = build(:league_match_round, home_team_score: -10)
    result = described_class.seed_round_for(@div.reload, rounds: [round])

    expect(result).to be_truthy
    expect(result.first).to be_invalid
  end
end
