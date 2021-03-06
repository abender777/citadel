class League
  class Match
    class RoundPresenter < ActionPresenter::Base
      presents :round

      delegate :match, to: :round

      def home_team
        present(match.home_team)
      end

      def away_team
        present(match.away_team)
      end

      def result
        home = home_team.link
        away = away_team.link

        if match.no_forfeit?
          non_forfeit_results(home, away)
        else
          forfeit_results(home, away)
        end.html_safe
      end

      private

      def non_forfeit_results(home, away)
        if round.home_team_score > round.away_team_score
          "#{home} beat #{away}"
        elsif round.home_team_score < round.away_team_score
          "#{home} lost to #{away}"
        else
          "#{home} tied with #{away}"
        end + ", #{round.home_team_score} to #{round.away_team_score}"
      end

      def forfeit_results(home, away)
        if match.home_team_forfeit?
          "#{away} wins by forfeit"
        elsif match.away_team_forfeit?
          "#{home} wins by forfeit"
        elsif match.mutual_forfeit?
          'mutual forfeit (both lose)'
        else
          'technical forfeit (both win)'
        end
      end
    end
  end
end
