module Leagues
  module Rosters
    class TransfersController < ApplicationController
      include TransferPermissions

      before_action do
        @roster = League::Roster.find(params[:roster_id])
        @league = @roster.league
      end
      before_action :require_transfer_permissions

      def create
        @transfer_request = Rosters::Transfers::CreationService.call(@roster, transfer_params)

        unless @transfer_request.errors.empty?
          flash[:error] = @transfer_request.errors.full_messages.first
        end
        redirect_to edit_roster_path(@roster)
      end

      private

      def transfer_params
        params.require(:request).permit(:user_id, :is_joining)
      end

      def require_transfer_permissions
        redirect_to team_path(@roster) unless user_can_manage_transfers?
      end
    end
  end
end
