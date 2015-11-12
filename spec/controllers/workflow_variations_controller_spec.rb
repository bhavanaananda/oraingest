require 'rails_helper'

describe 'Workflow Variations' do
  before do
    @routes = Sufia::Engine.routes
  end
  before(:all) do
    @user = FactoryGirl.find_or_create(:work_flow_user)
    @archivist = FactoryGirl.find_or_create(:archivist)

    @draft = GenericFile.new(title: 'Draft Submission', workflows_attributes:
                          [{identifier: 'MediatedSubmission', entries_attributes: [{status: 'Draft'}]}] )
    @draft.apply_depositor_metadata(@user.user_key)
    @submitted = GenericFile.new(title: 'Submitted Item', workflows_attributes:
                          [{identifier: 'MediatedSubmission', entries_attributes: [{status: 'Submitted'}]}] )
    @submitted.apply_depositor_metadata(@user.user_key)
    @in_review = GenericFile.new(title: 'Item In Review', workflows_attributes:
                          [{identifier: 'MediatedSubmission', entries_attributes: [{status: 'Assigned', reviewer_id: @archivist.user_key}]}] )
    @in_review.apply_depositor_metadata(@user.user_key)
    @escalated = GenericFile.new(title: 'Item In Review', workflows_attributes:
                          [{identifier: 'MediatedSubmission', entries_attributes: [{status: 'Escalated', reviewer_id: @archivist.user_key}]}] )
    @escalated.apply_depositor_metadata(@user.user_key)
    @approved = GenericFile.new(title: 'Item In Review', workflows_attributes:
                          [{identifier: 'MediatedSubmission', entries_attributes: [{status: 'Approved', reviewer_id: @archivist.user_key}]}] )
    @approved.apply_depositor_metadata(@user.user_key)
    @rejected = GenericFile.new(title: 'Item In Review', workflows_attributes:
                          [{identifier: 'MediatedSubmission', entries_attributes: [{status: 'Rejected', reviewer_id: @archivist.user_key}]}] )
    @rejected.apply_depositor_metadata(@user.user_key)

    [@draft, @submitted, @in_review, @escalated, @approved, @rejected].each {|o| o.save}

  end
  after(:all) do
    [@draft, @submitted, @in_review, @escalated, @approved, @rejected].each {|o| o.delete}
  end

  describe DashboardController do
    describe 'logged in user' do
      before (:each) do
        sign_in @user
        allow_any_instance_of(User).to receive(:groups).and_return([])
      end

      describe '#index' do
        before (:each) do
          get :index, per_page:'100'
        end

        it 'should be a success' do
          expect(response).to be_success
          expect(response).to render_template('dashboard/index')
        end
      end
    end
  end
end
