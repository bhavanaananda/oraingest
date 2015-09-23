require "rails_helper"

describe ConferenceItem do

  describe 'attributes' do

    before do
      @conferenceItem = ConferenceItem.new
    end

    subject { @conferenceItem }

    it { is_expected.to respond_to(:permissions) }
    # it { is_expected.to respond_to(:permissions_attributes) }
    it { is_expected.to respond_to(:workflows) }
    # it { is_expected.to respond_to(:workflows_attributes) }

    context 'ConferenceItemRdfDatastream' do
      it { is_expected.to respond_to(:title) }
      it { is_expected.to respond_to(:subtitle) }
      it { is_expected.to respond_to(:abstract) }
      it { is_expected.to respond_to(:subject ) }
      it { is_expected.to respond_to(:keyword) }
      it { is_expected.to respond_to(:worktype) }
      it { is_expected.to respond_to(:medium) }
      it { is_expected.to respond_to(:language) }
      it { is_expected.to respond_to(:publicationStatus) }
      it { is_expected.to respond_to(:reviewStatus) }
      it { is_expected.to respond_to(:license) }
      it { is_expected.to respond_to(:dateCopyrighted) }
      it { is_expected.to respond_to(:rightsHolder) }
      it { is_expected.to respond_to(:rights) }
      it { is_expected.to respond_to(:rightsActivity) }
      it { is_expected.to respond_to(:creation) }
      it { is_expected.to respond_to(:funding) }
      it { is_expected.to respond_to(:publication) }
      it { is_expected.to respond_to(:presentedAt) }

    end

  end

  describe 'when creating a new conference item' do
    before do
      @conferenceItem = ConferenceItem.new
    end

    it 'initializes the submission workflow' do
      @conferenceItem.save
      expect(@conferenceItem.workflows).not_to be_empty
    end

    it 'removes blank assertions' do
      @conferenceItem.title = 'Test title'
      @conferenceItem.subtitle = ''
      @conferenceItem.save
      expect(@conferenceItem.title).to eq(['Test title'])
      expect(@conferenceItem.subtitle).to eq([])
      expect(@conferenceItem.keyword).to eq([])
    end
  end

  describe 'applying permissions' do
    before do
      @conferenceItem = ConferenceItem.new
      @reviewer = FactoryGirl.find_or_create(:reviewer)
      @conferenceItem.apply_permissions(@reviewer)
    end

    it 'should set the permisions' do
      expect(@conferenceItem.permissions).not_to be_empty
    end

    it 'sets the permissions to reviewer/group/edit' do
      permission = @conferenceItem.permissions.first
      expect(permission.name).to eq('reviewer')
      expect(permission.type).to eq('group')
      expect(permission.access).to eq('edit')
    end
  end

  describe '#to_jq_upload' do
    before do
      @conferenceItem = ConferenceItem.new
      @jq_upload = @conferenceItem.to_jq_upload('title', 120, 'uuid:nn999n999', 'dsid')
    end

    it 'creates the jq upload params' do
      expect(@jq_upload).to be_a(Hash)
    end

    it 'sets the name' do
      expect(@jq_upload['name']).to eq('title')
    end

    it 'sets the size' do
      expect(@jq_upload['size']).to eq(120)
    end

    it 'sets the url' do
      expect(@jq_upload['url']).to eq('/conferenceitems/uuid:nn999n999/file/dsid')
    end

    it 'sets the thumbnail url' do
      expect(@jq_upload['thumbnail_url']).to eq('fileIcons/default-icon-48x48.png')
    end

    it 'sets the delete url' do
      expect(@jq_upload['delete_url']).to eq('/conferenceitems/uuid:nn999n999/file/dsid')
    end

    it 'sets the delete type' do
      expect(@jq_upload['delete_type']).to eq('DELETE')
    end

  end

end