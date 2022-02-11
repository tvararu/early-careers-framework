# frozen_string_literal: true

RSpec.shared_examples "a participant change schedule action service" do
  it_behaves_like "a participant action service"

  let!(:january_schedule) do
    create(
      :schedule,
      schedule_identifier: "ecf-january-standard-2021",
      identifier_alias: "ecf-january-standard-2021-alias",
      name: "ECF January standard schedule 2021",
    )
  end

  let(:expected_schedule) { january_schedule }

  it "changes the schedule on user's profile" do
    expect {
      described_class.new(params: given_params).call
      user_profile.reload
    }.to change(user_profile, :schedule).to(expected_schedule)
  end

  let(:schedule_identifier_alias) { "ecf-january-standard-2021-alias" }

  it "succeeds when given alias of schedule identifier" do
    params = given_params.merge({ schedule_identifier: schedule_identifier_alias })

    expect {
      described_class.new(params: params).call
      user_profile.reload
    }.to change(user_profile, :schedule).to(expected_schedule)
  end

  it "fails when the schedule is invalid" do
    params = given_params.merge({ schedule_identifier: "wibble" })
    expect { described_class.new(params: params).call }.to raise_error(ActionController::ParameterMissing)
  end

  it "fails when the participant is withdrawn" do
    ParticipantProfileState.create!(participant_profile: user_profile, state: "withdrawn")
    expect { described_class.new(params: given_params).call }.to raise_error(ActionController::ParameterMissing)
  end

  it "creates a schedule on profile" do
    expect { described_class.new(params: participant_params).call }.to change { ParticipantProfileSchedule.count }.by(1)
    expect(user_profile.participant_profile_schedules.first.schedule.schedule_identifier).to eq(expected_schedule.schedule_identifier)
  end

  context "when a pending declaration exists" do
    let!(:declaration) do
      start_date = user_profile.schedule.milestones.first.start_date
      create(:participant_declaration, declaration_date: start_date + 1.day, course_identifier: "ecf-induction", declaration_type: "started", cpd_lead_provider: cpd_lead_provider, participant_profile: user_profile)
    end

    it "fails when it would invalidate a valid declaration" do
      expected_schedule.milestones.each { |milestone| milestone.update!(start_date: milestone.start_date + 6.months, milestone_date: milestone.milestone_date + 6.months) }

      expect { described_class.new(params: given_params).call }.to raise_error(ActionController::ParameterMissing)
    end

    it "ignores voided declarations when changing the schedule" do
      declaration.voided!
      january_schedule.milestones.each { |milestone| milestone.update!(start_date: milestone.start_date + 6.months, milestone_date: milestone.milestone_date + 6.months) }

      described_class.new(params: given_params).call
      expect(user_profile.reload.schedule.schedule_identifier).to eq(expected_schedule.schedule_identifier)
    end
  end
end
