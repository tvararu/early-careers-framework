# frozen_string_literal: true

RSpec.describe Schools::AddParticipantForm, type: :model do
  let(:school_cohort) { create :school_cohort }
  let(:user) { create :user }

  subject(:form) { described_class.new(current_user_id: user.id, school_cohort_id: school_cohort.id) }

  it { is_expected.to validate_presence_of(:type).on(:type).with_message("Please select type of the new participant") }
  it { is_expected.to validate_inclusion_of(:type).in_array(form.type_options).on(:type) }

  it { is_expected.to validate_presence_of(:full_name).on(:name).with_message("Enter a full name") }
  it { is_expected.to validate_presence_of(:email).on(:email).with_message("Enter an email address") }

  describe "type" do
    context "when it is set to :ect" do
      it "sets the participant_type to ect" do
        expect { form.type = "ect" }
          .to change { form.participant_type }.to :ect
      end
    end

    context "when it is set to :mentor" do
      it "sets the participant_type to ect" do
        expect { form.type = "mentor" }
          .to change { form.participant_type }.to :mentor
      end
    end

    context "when it is set to :self" do
      it "sets the participant_type to mentor as well as full name and email to match current_user details" do
        expect { form.type = "self" }
          .to change { form.participant_type }.to(:mentor)
                                                 .and change { form.full_name }.to(user.full_name)
                                                                                  .and change { form.email }.to(user.email)
      end
    end
  end

  describe "mentor_options" do
    it "does not include mentors with withdrawn records" do
      withdrawn_mentor_record = create(:participant_profile, :mentor, :withdrawn_record, school_cohort: school_cohort).user

      expect(form.mentor_options).not_to include(withdrawn_mentor_record)
    end

    it "includes active mentors" do
      active_mentor_record = create(:participant_profile, :mentor, school_cohort: school_cohort).user

      expect(form.mentor_options).to include(active_mentor_record)
    end
  end

  describe "email_already_taken?" do
    before do
      form.email = "ray.clemence@example.com"
    end

    context "when the email is not already in use" do
      it "returns false" do
        expect(form).not_to be_email_already_taken
      end
    end

    context "when the email is in use by an ECT user" do
      let!(:ect_profile) do
        create(:participant_profile, :ect, user: create(:user, email: "ray.clemence@example.com"))
      end

      it "returns true" do
        expect(form).to be_email_already_taken
      end

      context "when the ECT profile record is withdrawn" do
        let!(:ect_profile) do
          create(:participant_profile, :withdrawn_record, :ect, user: create(:user, email: "ray.clemence@example.com"))
        end

        it "returns false" do
          expect(form).not_to be_email_already_taken
        end
      end
    end

    context "when the email is in use by a Mentor" do
      let!(:mentor_profile) do
        create(:participant_profile, :mentor, user: create(:user, email: "ray.clemence@example.com"))
      end

      it "returns true" do
        expect(form).to be_email_already_taken
      end

      context "when the mentor profile record is withdrawn" do
        let!(:mentor_profile) do
          create(:participant_profile, :withdrawn_record, :mentor, user: create(:user, email: "ray.clemence@example.com"))
        end

        it "returns false" do
          expect(form).not_to be_email_already_taken
        end
      end
    end

    context "when the email is in use by a NPQ registrant" do
      before do
        existing_user = create(:user, email: "ray.clemence@example.com")
        create(:participant_profile, :npq, user: existing_user)
      end

      it "returns false" do
        expect(form).not_to be_email_already_taken
      end
    end
  end

  describe "can_add_self?" do
    context "when the user is not a mentor" do
      it "returns true" do
        expect(form.can_add_self?).to be true
      end
    end

    context "when the user is a mentor at another school" do
      before do
        create(:participant_profile, :mentor, user: user)
      end

      it "returns false" do
        expect(form.can_add_self?).to be false
      end
    end

    context "when the user is a mentor at this school" do
      before do
        create(:participant_profile, :mentor, user: user, school_cohort: school_cohort)
      end

      it "returns false" do
        expect(form.can_add_self?).to be false
      end
    end
  end

  describe "#save!" do
    before do
      form.type = form.type_options.sample
      form.full_name = Faker::Name.name
      form.email = Faker::Internet.email
      form.mentor_id = (form.mentor_options.pluck(:id) + %w[later]).sample if form.type == :ect

      create :schedule
    end

    subject(:execution) { form.method(:save!).to_proc }

    it "creates new participant record" do
      expect(execution).to change(ParticipantProfile::ECF, :count).by 1
    end
  end
end
