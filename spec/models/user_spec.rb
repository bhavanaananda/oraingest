require 'rails_helper'

describe User do
  let(:user) { FactoryGirl.build(:user) }

  describe '#to_s' do
    it 'should return email' do
      expect(user.to_s).to eq(user.email)
    end
  end
  
  describe '#display_name' do
    let(:names) { {'firstname' => 'Foo', 'lastname' => 'Bar'} }
    
    it 'with first and last names' do
      expect(user.display_name(names)).to eq('Foo Bar')
    end
    
    it 'with first name' do
      names.delete('lastname')
      expect(user.display_name(names)).to eq('Foo')
    end
    
    it 'with last name' do
      names.delete('firstname')
      expect(user.display_name(names)).to eq('Bar')
    end
    
    it 'without user_info' do
      expect(user.display_name).to eq(nil)
    end  
  end
  
  describe '#oxford_email' do
    it 'with empty user_info' do
      expect(user.oxford_email({})).to eq(nil)
    end
    
    it 'with nil user_info' do
      expect(user.oxford_email).to eq(nil)
    end
    
    it 'with user_info' do
      expect(user.oxford_email({'oxford_email' => 'foo'})).to eq('foo')
    end
  end
  
  describe '#reviewer?' do
    it 'with no groupsarray' do
      expect(user.reviewer?).to eq(false)
    end
    
    it 'with groupsarray of reviewer' do
      RoleMapper.stub(:roles) { ['reviewer'] }

      expect(user.reviewer?).to eq(true)
    end
  end
  
end

