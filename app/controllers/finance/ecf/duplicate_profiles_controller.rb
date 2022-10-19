module Finance
  module ECF
    class DuplicateProfilesController < BaseController
      def index
        @participant_profiles = Duplicate.where("id = master_participant_profile_id")
        @training_statuses    = Duplicate.select(:training_status).distinct
        @induction_statuses   = Duplicate.select(:induction_status).distinct
        @breadcrumbs          = [
          helpers.govuk_breadcrumb_link_to("Finance dashboard", finance_landing_page_path),
          helpers.govuk_breadcrumb_link_to("Master profiles", finance_ecf_duplicate_profiles_path),
        ]
      end

      def show
        @participant_profile = Duplicate.find(params[:id])
        @breadcrumbs         = [
          helpers.govuk_breadcrumb_link_to("Finance dashboard", finance_landing_page_path),
          helpers.govuk_breadcrumb_link_to("Master profiles", finance_ecf_duplicate_profiles_path),
          helpers.govuk_breadcrumb_link_to(@participant_profile.user.full_name, finance_ecf_duplicate_profile_path(@participant_profile)),
        ]
      end

      def edit
        @participant_profile = Duplicate.find(params[:id])
        @breadcrumbs         = [
          helpers.govuk_breadcrumb_link_to("Finance dashboard", finance_landing_page_path),
          helpers.govuk_breadcrumb_link_to("Master profiles", finance_ecf_duplicate_profiles_path),
          helpers.govuk_breadcrumb_link_to(@participant_profile.user.full_name, finance_ecf_duplicate_profile_path(@participant_profile)),
          helpers.govuk_breadcrumb_link_to(@participant_profile.user.full_name, edit_finance_ecf_duplicate_profile_path(@participant_profile)),
        ]
      end

      def destroy
        # TODO:
        # master_participant_profile = Duplicate.find(params[:id])
        # ParticipantPropfile::ECF.find(master_participant_profile.duplicate_participant_profile_ids).each do |participant_profile|
        #   participant_profile.update!(type: participant_profile.ect? ? "ParticipantProfile::Deleted::ECF" : "ParticipantProfile::Deleted::Mentor")
        # end
        redirect_to finance_ecf_duplicate_profiles_path
      end
    end
  end
end
