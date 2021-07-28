# frozen_string_literal: true

module Schools
  class Year2020Form
    include ActiveModel::Model
    include ActiveModel::Serialization

    attr_accessor :school_id, :induction_programme_choice, :core_induction_programme_id, :full_name, :email, :participants

    validates :induction_programme_choice, presence: true, on: :choose_induction_programme
    validates :core_induction_programme_id, presence: true, on: :choose_cip

    validates :full_name, presence: true, on: :create_teacher
    # TODO: unique emails
    validates :email,
              presence: true,
              notify_email: { allow_blank: true },
              on: :create_teacher

    def attributes
      { school_id: nil, induction_programme_choice: nil, core_induction_programme_id: nil, participants: nil }
    end

    def induction_programme_options
      [
        OpenStruct.new(id: "core_induction_programme", name: "Yes"),
        OpenStruct.new(id: "design_our_own", name: "No, we will support our NQTs another way"),
        OpenStruct.new(id: "no_early_career_teachers", name: "No, we don't have any NQTs"),
      ]
    end

    def school
      School.friendly.find(school_id) || School.find_by(urn: school_id)
    end

    def core_induction_programme
      CoreInductionProgramme.find(core_induction_programme_id)
    end

    def cohort
      Cohort.find_by(start_year: 2020)
    end

    def store_new_participant
      self.participants = get_participants << { full_name: full_name, email: email, index: new_participant_index }
      self.full_name = nil
      self.email = nil
    end

    def get_participants
      participants&.filter { |participant| participant } || []
    end

    def new_participant_index
      max_index = 0
      get_participants.each { |participant| max_index = [max_index, participant[:index]].max }
      max_index + 1
    end

    def get_participant(index)
      get_participants.find { |participant| participant[:index] == index }
    end

    def update_participant(index)
      new_participants = get_participants.map do |participant|
        if participant[:index] == index
          participant[:full_name] = full_name
          participant[:email] = email
        end
        participant
      end
      self.participants = new_participants
      self.full_name = nil
      self.email = nil
    end

    def remove_participant(index)
      self.participants = get_participants.filter { |participant| participant[:index] != index }
    end

    def opt_out?
      induction_programme_choice == "design_our_own" || induction_programme_choice == "no_early_career_teachers"
    end

    def opt_out!
      school_cohort = SchoolCohort.find_or_initialize_by(school: school, cohort: cohort)
      school_cohort.induction_programme_choice = induction_programme_choice
      school_cohort.save!
    end

    def save!
      ActiveRecord::Base.transaction do
        school_cohort = SchoolCohort.find_or_initialize_by(school: school, cohort: cohort)
        school_cohort.induction_programme_choice = "core_induction_programme"
        school_cohort.core_induction_programme = core_induction_programme
        school_cohort.save!

        EarlyCareerTeachers::Create.call(
          full_name: full_name,
          email: email,
          school_cohort: school_cohort,
          mentor_profile_id: nil,
        )
      end
    end
  end
end
